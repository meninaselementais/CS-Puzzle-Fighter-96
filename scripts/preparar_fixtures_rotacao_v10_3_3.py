"""Deriva somente valores observados; preserva fontes e não exporta RAM/ROM."""
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    source = ROOT / 'relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json'
    cases = []
    for case in json.loads(source.read_text())['cases']:
        first = case['expected_samples'][0]
        initial = ROOT / 'laboratorio' / case['source_session'] / 'captures' / (case['id'] + '_initial.bin')
        assert sha(initial) == case['initial_ram_sha256']
        ram = initial.read_bytes()
        word = lambda address: int.from_bytes(ram[address:address+2], 'big')
        clock = {key: first[key] for key in ['phase', 'contact', 'offset', 'fall_countdown', 'fall_interval', 'fall_increment', 'fall_offset', 'contacts' if 'contacts' in first else 'contact_count', 'down_counter', 'previous_input']}
        clock['contacts'] = clock.pop('contact_count')
        clock.update(fall_start=bool(ram[0x857e]), upkicks=word(0x8614), rotation_disabled=bool(ram[0x8616]), down_timer=ram[0x84a9], horizontal_timer=word(0x8488))
        samples = []
        for row in case['expected_samples']:
            anim = bytes.fromhex(row['animation_ram'])
            samples.append(dict(frame=row['frame'], input=row['input'], phase=row['phase'], contact=row['contact'], x=row['x'], y=row['y']-1, rotation=row['rotation'], offset=row['offset'], colors=[row['pivot'], row['satellite']], mode=anim[0x47], timer=int.from_bytes(anim[0x4c:0x4e], 'big'), dx=int.from_bytes(anim[0x48:0x4a], 'big', signed=True), dy=int.from_bytes(anim[0x4a:0x4c], 'big', signed=True)))
        cases.append(dict(id=case['id'], initial=dict(x=first['x'], y=first['y']-1, rotation=first['rotation'], colors=[first['pivot'], first['satellite']], cells=[int(x,16) for x in first['grid'].split(':')], clock=clock, pair_age=first['pair_age'], score=first['score'], turn=first['turn'], global_seed=first['global_seed'], next_colors=[word(0x8456),word(0x8458)]), samples=samples))
    trace = ROOT / 'relatorios/v10_3_1/visual_trace_v10_3_1.csv'
    rows = list(csv.DictReader(trace.open(encoding='utf-8-sig')))
    primary = []
    for name in dict.fromkeys(r['scenario'] for r in rows if r['scenario'].startswith(('rotation_', 'corridor_'))):
        samples = []
        for r in (r for r in rows if r['scenario'] == name):
            samples.append(dict(frame=int(r['frame']),input=int(r['input']),phase=int(r['phase']),contact=int(r['contact']),x=int(r['x']),y=int(r['y'])-1,rotation=int(r['rot']),offset=int(r['offset']),colors=[int(r['c1'],16),int(r['c2'],16)],mode=int(r['rot_dir']),timer=int(r['rot_timer']),dx=int(r['rot_dx']),dy=int(r['rot_dy'])))
        primary.append(dict(id=name, samples=samples))
    data = dict(sources={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [source,trace]}, primary=primary, cases=cases)
    dest = ROOT / 'godot/data/pair_rotation_v10_3_3.json'
    dest.write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
    print(len(primary),'primary cases;',len(cases),'regression cases;',len(dest.read_bytes()),'bytes')


if __name__ == '__main__':
    main()
