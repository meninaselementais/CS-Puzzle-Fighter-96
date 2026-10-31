import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from exportar_mecanicas import canonical, values, powers, export
from verificar_repeticao_mecanicas import compare


class MechanicsTests(unittest.TestCase):
    def test_graphics_flags_do_not_change_gem_kind(self):
        self.assertEqual(canonical(0x6083),131)
        self.assertEqual(canonical(0x001c),12)
        self.assertEqual(canonical(0x4506),0x4507)
        self.assertEqual(canonical(0x0005),5)
        self.assertEqual(canonical(0x6005),5)
        self.assertEqual(canonical(0),0)

    def test_grid_size_is_validated(self):
        with self.assertRaises(ValueError):values({'grid1':'0000'},'grid1')

    def test_power_geometry_uses_all_four_corners(self):
        board=[0]*84;aux=[0]*84
        for x,y,flag in [(0,12,2),(1,12,8),(0,13,1),(1,13,4)]:
            board[y*6+x]=131;aux[y*6+x]=0x300|flag
        encode=lambda a:':'.join(f'{v:04X}' for v in a)
        self.assertEqual(powers({'grid1':encode(board),'aux1':encode(aux)}),[[0,12,2,2]])
        aux[13*6+1]=0
        self.assertEqual(powers({'grid1':encode(board),'aux1':encode(aux)}),[])

    def test_incomplete_arcade_run_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            (root/'execucao.json').write_text('{}')
            with self.assertRaises(ValueError):export(root)

    def test_repetition_detects_memory_difference(self):
        with tempfile.TemporaryDirectory() as directory:
            roots=[Path(directory)/name for name in ['a','b']]
            for root in roots:
                (root/'captures').mkdir(parents=True)
                (root/'sta/spf2tu').mkdir(parents=True)
                (root/'sta/spf2tu/input.sta').write_bytes(b'state')
                (root/'captures/test.bin').write_bytes(b'ram')
                (root/'mechanics.csv').write_text('identical')
                (root/'execucao.json').write_text(json.dumps({'fontes_preservadas':True,'lua_concluiu':True,
                    'lua_sem_erros':True,'lua_sha256':'same','copias':[]}))
            self.assertTrue(compare(*roots)['all_match'])
            (roots[1]/'captures/test.bin').write_bytes(b'different')
            self.assertEqual(compare(*roots)['different_dumps'],['test.bin'])


if __name__=='__main__':unittest.main()
