"""Regressões de entrada dos validadores V10; fixtures originais só são lidas."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import importlib.util

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT/'ferramentas/godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe'
PHYSICS = ROOT/'relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json'
CAPTURES = Path(os.environ.get('PF_POWER_CAPTURE', ROOT/'relatorios/v10_3_4/render'))


class ValidatorInputs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        global CAPTURES
        if 'PF_POWER_CAPTURE' not in os.environ:
            cls.render_temp = tempfile.TemporaryDirectory()
            cls.addClassCleanup(cls.render_temp.cleanup)
            output = Path(cls.render_temp.name)
            result = subprocess.run([str(GODOT), '--path', str(ROOT/'godot'), '--script',
                                     'res://tests/render_power_facet_v10_3_4.gd'],
                                    env=dict(os.environ, PF_REPORT=str(output)), capture_output=True,
                                    text=True, encoding='utf-8', errors='replace', timeout=120)
            if result.returncode or 'ERROR' in result.stdout + result.stderr:
                raise RuntimeError(result.stdout + result.stderr)
            CAPTURES = output/'render'

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)

    def run_validator(self, script, args):
        result = subprocess.run([str(GODOT), '--headless', '--path', str(ROOT/'godot'),
                                 '--script', f'res://tests/{script}.gd', '--', *args],
                                env=dict(os.environ, PF_REPORT=str(self.folder)),
                                capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60)
        return result.returncode, result.stdout + result.stderr

    def physics(self, value, raw=False, output=None):
        path = self.folder/'fixtures.json'
        path.write_text(value if raw else json.dumps(value), encoding='utf-8')
        return self.run_validator('test_gem_timeline', [f'--fixtures={path}', f'--out={output or self.folder/"report.json"}'])

    def power(self, value, raw=False):
        (self.folder/'captures.json').write_text(value if raw else json.dumps(value), encoding='utf-8')
        return self.run_validator('test_power_facet_capture_v10_3_4', [str(self.folder)])

    def rejected(self, result, message):
        code, log = result
        self.assertEqual(code, 1, log)
        self.assertIn(message, log)
        self.assertNotIn('SCRIPT ERROR', log)

    def test_physics_empty_invalid_and_missing(self):
        for value, raw in [({'cases': []}, False), ({}, False), ([], False), ('{broken', True), ('', True)]:
            with self.subTest(value=value):
                self.rejected(self.physics(value, raw), 'GEM_TIMELINE input:')
        self.rejected(self.run_validator('test_gem_timeline', [f'--fixtures={self.folder/"missing.json"}', f'--out={self.folder/"r.json"}']), 'Fixture file missing')
        self.rejected(self.run_validator('test_gem_timeline', []), 'Use --fixtures=')

    def test_physics_incomplete_duplicate_and_bad_samples(self):
        original = json.loads(PHYSICS.read_text(encoding='utf-8'))
        for kind in ['missing_case', 'duplicate_case', 'unknown_case', 'empty_samples', 'missing_sample', 'bad_field', 'bad_grid', 'duplicate_frame', 'bad_optional', 'fractional_optional']:
            data = copy.deepcopy(original)
            row = data['cases'][0]['expected_samples'][0]
            if kind == 'missing_case': data['cases'].pop()
            if kind == 'duplicate_case': data['cases'][-1] = data['cases'][0]
            if kind == 'unknown_case': data['cases'][0]['id'] = 'unknown_case'
            if kind == 'empty_samples': data['cases'][0]['expected_samples'] = []
            if kind == 'missing_sample': data['cases'][0]['expected_samples'].pop()
            if kind == 'bad_field': row.pop('x')
            if kind == 'bad_grid': row['grid'] = 'zzzz:'*83 + 'zzzz'
            if kind == 'duplicate_frame': data['cases'][0]['expected_samples'][1]['frame'] = 0
            if kind == 'bad_optional': row['rotation_disabled'] = 'invalid'
            if kind == 'fractional_optional': row['rotation_disabled'] = 0.5
            with self.subTest(kind=kind): self.rejected(self.physics(data), 'GEM_TIMELINE input:')

    def test_physics_ram_and_output_errors(self):
        data = json.loads(PHYSICS.read_text(encoding='utf-8'))
        data['cases'][0]['source_session'] = '__missing_v10_test__'
        self.rejected(self.physics(data), 'Initial RAM missing or invalid')
        data = json.loads(PHYSICS.read_text(encoding='utf-8'))
        data['cases'][0]['initial_ram_sha256'] = '0'*64
        self.rejected(self.physics(data), 'Initial RAM SHA256 mismatch')
        data = json.loads(PHYSICS.read_text(encoding='utf-8'))
        self.rejected(self.physics(data, output=self.folder/'missing'/'report.json'), 'Cannot write report')

    def test_physics_positive(self):
        code, log = self.run_validator('test_gem_timeline', [f'--fixtures={PHYSICS}', f'--out={self.folder/"physics.json"}'])
        self.assertEqual(code, 0, log)
        self.assertNotIn('ERROR', log)
        summary = json.loads((self.folder/'physics.json').read_text())
        self.assertEqual((summary['cases_passed'], summary['samples_matched']), (112, 14072))

    def test_physics_real_difference_fails(self):
        data = json.loads(PHYSICS.read_text(encoding='utf-8'))
        data['cases'][0]['expected_samples'][5]['score'] += 1
        code, log = self.physics(data)
        self.assertEqual(code, 1, log)
        self.assertIn('GEM_TIMELINE cases=111/112', log)
        self.assertNotIn('SCRIPT ERROR', log)

    def test_power_empty_invalid_and_missing(self):
        for value, raw in [([], False), ({}, False), ('null', True), ('[broken', True), ('', True)]:
            with self.subTest(value=value): self.rejected(self.power(value, raw), 'POWER_FACET_CAPTURE input:')
        self.rejected(self.run_validator('test_power_facet_capture_v10_3_4', [str(self.folder/'missing')]), 'Capture manifest missing')
        self.rejected(self.run_validator('test_power_facet_capture_v10_3_4', []), 'Use -- <capture folder>')

    def test_power_coverage_schema_and_missing_image(self):
        original = json.loads((CAPTURES/'captures.json').read_text())
        for kind in ['missing_capture', 'duplicate_capture', 'unknown_case', 'bad_frame', 'bad_ages', 'bad_age', 'bad_region', 'missing_regions', 'missing_image']:
            data = copy.deepcopy(original)
            if kind == 'missing_capture': data.pop()
            if kind == 'duplicate_capture': data[-1] = data[0]
            if kind == 'unknown_case': data[0]['case'] = 'unknown'
            if kind == 'bad_frame': data[0]['frame'] = 1.5
            if kind == 'bad_ages': data[0]['ages'] = []
            if kind == 'bad_age': data[0]['ages'][0] = 'invalid'
            if kind == 'bad_region': data[0]['regions'] = [[0, 0, 7, 14]]
            if kind == 'missing_regions': data[0]['regions'] = []
            with self.subTest(kind=kind): self.rejected(self.power(data), 'POWER_FACET_CAPTURE input:')

    def test_power_invalid_image_and_dimensions(self):
        records = json.loads((CAPTURES/'captures.json').read_text())
        stem = f"{records[0]['case']}_f{records[0]['frame']:03d}.png"
        base = f"{records[0]['case']}_base_f{records[0]['frame']:03d}.png"
        (self.folder/stem).write_bytes(b'invalid PNG')
        (self.folder/base).write_bytes((CAPTURES/base).read_bytes())
        self.rejected(self.power(records), 'Invalid capture image')
        # A real 1x1 PNG exercises bounds checking before any pixel access.
        import struct
        import zlib
        def chunk(kind, data):
            return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
        png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(b'\0\0\0\0')) + chunk(b'IEND', b'')
        (self.folder/stem).write_bytes(png)
        self.rejected(self.power(records), 'Expected 1000x700 image pair')

    def test_power_positive(self):
        code, log = self.run_validator('test_power_facet_capture_v10_3_4', [str(CAPTURES)])
        self.assertEqual(code, 0, log)
        self.assertNotIn('ERROR', log)
        report = json.loads((self.folder/'capture_structure.json').read_text())
        self.assertEqual((report['captures'], report['checks'], report['failures']), (181, 1407, []))

    def test_power_missing_effect_fails(self):
        records = json.loads((CAPTURES/'captures.json').read_text())
        for record in records:
            stem = f"{record['case']}_f{record['frame']:03d}.png"
            base = f"{record['case']}_base_f{record['frame']:03d}.png"
            # Copies in the temporary folder only: no effect can pass as a facet.
            data = (CAPTURES/base).read_bytes()
            (self.folder/stem).write_bytes(data)
            (self.folder/base).write_bytes(data)
        code, log = self.power(records)
        self.assertEqual(code, 1, log)
        self.assertIn('missing facet in cell', log)
        self.assertNotIn('SCRIPT ERROR', log)


class MatchFlowRunner(unittest.TestCase):
    def test_visual_and_movie_use_adapter_headless_keeps_historical(self):
        spec = importlib.util.spec_from_file_location('flow_runner', ROOT/'scripts/validar_fluxo_partidas.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        for mode in [[], ['--visual'], ['--movie']]:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as temp:
                folder = Path(temp)
                visual = bool(mode)
                report = {'completed': 4, 'rounds': 10, 'checks': 276, 'failures': []}
                target = folder if visual else folder/'worker_1'
                target.mkdir(exist_ok=True)
                (target/'integration_summary.json').write_text(json.dumps(report))
                args = ['runner', '--matches', '4', '--workers', '1', '--output', str(folder), *mode]
                if mode == ['--movie']: args.append(str(folder/'test.avi'))
                with patch('sys.argv', args), patch.object(module.subprocess, 'Popen') as popen:
                    popen.return_value.stdout = []
                    popen.return_value.wait.return_value = 0
                    self.assertEqual(module.main(), 0)
                    command = popen.call_args.args[0]
                    expected = 'test_match_flow_visual_v10_3_4.gd' if visual else 'test_match_flow.gd'
                    self.assertIn('res://tests/'+expected, command)
                    self.assertEqual('--headless' in command, not visual)


if __name__ == '__main__':
    unittest.main()
