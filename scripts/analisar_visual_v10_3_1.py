"""Exporta observações MAME e valida repetição, tabelas e fixtures V10 existentes.
Uso: python analisar_medicoes.py PROJECT SESSION REPEAT OUTPUT
Somente lê fontes; não inclui dumps/ROMs nos resultados.
"""
import csv
import hashlib
import json
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

root, session, repeat, out = map(Path, sys.argv[1:])
out.mkdir(parents=True, exist_ok=True)
def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))
def save(name, data):
    assert data, name
    with (out/name).open('w', encoding='utf-8', newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

cpu = rows(session/'visual_trace_v10_3_1.csv')
again = rows(repeat/'visual_trace_v10_3_1.csv')
video = rows(session/'video_trace.csv')
assert cpu == again, 'Repetição CPU divergente'
assert video == rows(repeat/'video_trace.csv'), 'Repetição vídeo divergente'
assert len(cpu)==1100 and len(video)==1099 # Final CPU sample exits before frame_done.
tables=rows(session/'rotation_tables_12D00_12DA0.csv')
lookup={(r['table_addr'],int(r['d1_index']),int(r['t_index'])):(int(r['dx']),int(r['dy'])) for r in tables}
assert len(lookup)==72
checks=[]
coverage=defaultdict(set)
for r in cpu:
    timer=int(r['rot_timer'])
    if not r['scenario'].startswith(('rotation_','corridor_')) or timer>7: continue
    # Timer zero is checked only at the end of a measured rotation.
    if timer==0 and int(r['frame'])!=11: continue
    if timer==0 or timer>0:
        group=4 if int(r['rot_dir'])==2 else int(r['rot'])
        table='0x12DA0' if int(r['rot_dir'])==0 else '0x12D00'
        expected=lookup[table,group,timer]
        observed=int(r['rot_dx']),int(r['rot_dy'])
        assert observed==expected,(r['scenario'],r['frame'],expected,observed)
        coverage[r['scenario']].add(timer)
        if r['scenario'].startswith('rotation_'):
            initial,button=map(int,re.match(r'rotation_r(\d)_b(\d)',r['scenario']).groups())
            assert int(r['rot'])==(initial+(-1 if button==1 else 1))%4
        else:
            assert int(r['rot'])==0 and int(r['rot_dir'])==2
            assert (r['c1'],r['c2'])==('0x0002','0x0001')
        checks.append(dict(scenario=r['scenario'],frame=r['frame'],table=table,group=group,timer=timer,dx=observed[0],dy=observed[1],match=True))
assert len(coverage)==10 and all(v==set(range(8)) for v in coverage.values())
save('rotacao_por_quadro.csv',checks)
old=json.loads((root/'relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json').read_text())
fixture_checks=[]
for case in old['cases']:
    samples=case['expected_samples']
    for i,s in enumerate(samples):
        b=bytes.fromhex(s['animation_ram'])
        timer=int.from_bytes(b[0x4c:0x4e],'big',signed=True)
        previous=bytes.fromhex(samples[i-1]['animation_ram']) if i else bytes(112)
        prev_timer=int.from_bytes(previous[0x4c:0x4e],'big',signed=True)
        if 0<=timer<=7 and (timer>0 or prev_timer==1):
            direction=b[0x47];group=4 if direction==2 else int(s['rotation'])
            table='0x12DA0' if direction==0 else '0x12D00'
            actual=(int.from_bytes(b[0x48:0x4a],'big',signed=True),int.from_bytes(b[0x4a:0x4c],'big',signed=True))
            assert actual==lookup[table,group,timer],(case['id'],s['frame'],actual)
            fixture_checks.append(dict(case=case['id'],frame=s['frame'],timer=timer,table=table,group=group,dx=actual[0],dy=actual[1],match=True))
save('comparacao_animation_ram.csv',fixture_checks)

pattern=re.compile(r'\((\d+),(\d+)\):bw=([0-9A-F]+)\|pg=([0-9A-F]+)\|st=([0-9A-F]+)/([0-9A-F]+)\|ptr=([0-9A-F]+)\|tm=(-?\d+)\|fl=([0-9A-F]+)\|d=\((-?\d+),(-?\d+)\)\|tl=([0-9A-F]+)\|at=([0-9A-F]+)\|pw=(\d+)x(\d+)<-(\d+)x(\d+)@\((\d+),(\d+)\)')
cellnames=['col','row','board_word','power_word','state','previous_state','script_pointer','anim_timer','layout_flag','dx','dy','tile','attr','width_minus_one','height_minus_one','previous_width_minus_one','previous_height_minus_one','local_x','local_y']
hexcols={2,3,4,5,6,8,11,12}
cells=[]
for r in video:
    parts=pattern.findall(r['cells_detail'])
    assert len(parts)==36
    for part in parts:
        d={k:int(v,16 if i in hexcols else 10) for i,(k,v) in enumerate(zip(cellnames,part))}
        cells.append(dict(scenario=r['scenario'],frame=int(r['frame']),phase=int(r['phase']),clear_timer=int(r['clear_timer']),**d))
save('sprites_por_quadro_video.csv',cells)
groups=defaultdict(list)
for r in cpu: groups[r['scenario']].append(r)
for case in ['landing_contact','landing_same_color']:
    assert [int(r['contact']) for r in groups[case][:16]]==list(range(16,0,-1))
    assert groups[case][16]['phase']=='1'
for case,start,end in [('explosion_simple',26,65),('explosion_chain_2',69,108),('explosion_chain_2',130,169)]:
    interval=groups[case][start-1:end]
    assert all(r['phase']=='11' for r in interval)
    assert [int(r['clear_timer']) for r in interval]==list(range(40,0,-1))
    assert groups[case][end]['phase']=='3' and groups[case][end]['clear_timer']=='0'
for case,frame,col,row,width,height in [('power_2x2',1,0,12,2,2),('power_2x3',36,0,11,2,3),('power_union_5x2',46,2,12,5,2)]:
    c=next(c for c in cells if c['scenario']==case and c['frame']==frame and c['col']==col and c['row']==row)
    assert (c['width_minus_one']+1,c['height_minus_one']+1)==(width,height)
clock_matches=0
for v in video:
    f=int(v['frame']);case=v['scenario']
    if f>=len(groups[case]) or (f==34 and case in ['power_2x3','power_union_5x2']):continue
    following=groups[case][f]
    assert all(v[k]==following[k] for k in v if k not in ['frame','note']), (case,f)
    clock_matches+=1
timeline=[]
for k,rs in groups.items():
    for i,r in enumerate(rs):
        if i==0 or any(r[key]!=rs[i-1][key] for key in ['phase','clear_timer','contact']):
            timeline.append({key:r[key] for key in ['scenario','frame','phase','clear_timer','contact','y','offset']})
save('cronologia.csv',timeline)
# Full observed fixtures are numeric summaries/RAM descriptors, never executable ROM data.
for name in ['visual_trace_v10_3_1.csv','video_trace.csv','video_clock.csv','injections.csv','rotation_tables_12D00_12DA0.csv']:
    shutil.copyfile(session/name,out/name)
for label,source in [('primary',session),('repeat',repeat)]:
    manifest=json.loads((source/'execucao.json').read_text())
    assert manifest['exit_code']==0 and manifest['fontes_preservadas'] and manifest['lua_concluiu'] and manifest['lua_sem_erros']
    shutil.copyfile(source/'execucao.json',out/f'execucao_{label}.json')
summary=dict(cases=len(groups),cpu_samples=len(cpu),video_samples=len(video),sprite_samples=len(cells),rotation_steps=len(checks),old_animation_ram_matches=len(fixture_checks),old_cases_compared=len(set(x['case'] for x in fixture_checks)),video_f_matches_cpu_f_plus_1=clock_matches,repeat_cpu_equal=True,repeat_video_equal=True,primary=str(session),repeat=str(repeat),probe_sha256=sha(session/'experimento.lua'))
(out/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
reference_probe=root/'scripts/medir_visual_v10_3_1.lua'
if not reference_probe.exists():reference_probe=Path(__file__).with_name('probe_corrigido.lua')
assert sha(session/'experimento.lua')==sha(reference_probe)
assert sha(session/'rotation_tables_12D00_12DA0.csv')==sha(root/'laboratorio/auto_20261101_220908_925177/rotation_tables_12D00_12DA0.csv')
print(json.dumps(summary,indent=2))
