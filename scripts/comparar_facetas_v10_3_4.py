"""V10.3.4: confronta cada célula com o traço CPU MAME F+1, sem realinhar ciclos."""
import csv, hashlib, json, re, sys
from pathlib import Path

root, out, capture = map(Path, sys.argv[1:4])
out.mkdir(parents=True, exist_ok=True)
source = root/'laboratorio/auto_20261101_222825_850720/visual_trace_v10_3_1.csv'
repeat = root/'laboratorio/auto_20261101_222903_899708/visual_trace_v10_3_1.csv'
assert source.read_bytes() == repeat.read_bytes(), 'MAME repeated trace differs'
rows = {(r['scenario'],int(r['frame'])): r for r in csv.DictReader(source.open(encoding='utf-8',newline=''))}
letters='abcdcba'
tiles={}
for base,step in [(0x5A20,2),(0x5A21,2),(0x5A30,2),(0x5A31,2), *[(b,1) for b in [0x5A18,0x5A1C,0x5A28,0x5A2C,0x5A38,0x5A3C,0x5A40,0x5A44]]]:
    for phase in range(4): tiles[base+phase*step]='abcd'[phase]
summary=[]; details=[]; failures=[]; unpaired=[]
records=json.loads((capture/'render/captures.json').read_text())
for case,native,coords in [('power_2x2','power_2x2',[(x,y) for y in [12,13] for x in range(2)]),('power_growth','power_2x3',[(x,y) for y in [11,12,13] for x in range(2)]),('power_union_5x2','power_union_5x2',[(x,y) for y in [12,13] for x in range(5)])]:
    matched=0; preambles=0; selected=[r for r in records if r['case']==case]
    expected_frames={'power_2x2':range(1,66),'power_growth':range(35,91),'power_union_5x2':range(35,95)}[case]
    assert [r['frame'] for r in selected] == list(expected_frames), ('Missing/duplicate capture frames',case)
    for record in selected:
        assert len(record['ages'])==84 and record['regions'], ('Incomplete cell capture',case,record['frame'])
        frame=record['frame']
        if (native,frame+1) not in rows:
            unpaired.append(dict(case=case,godot_frame=frame,reason='MAME source ended')); continue
        row=rows[native,frame+1]
        for x,y in coords:
            tile=int(re.search(r'\(%d,%d\):[^;]*tl=([0-9A-F]+)'%(x,y),row['cells_detail']).group(1),16)
            age=record['ages'][y*6+x]
            expected=tiles.get(tile)
            actual=letters[min(age//8,6)] if age>=0 else None
            # The 5A00 preamble has no facet; require no overlay, do not invent A.
            ok=actual==expected if expected is not None else (actual in [None,'a'] and tile in [0,0x5A00])
            preambles+=expected is None
            matched+=ok
            item=dict(case=case,godot_frame=frame,mame_cpu_frame=frame+1,cell=[x,y],tile=hex(tile),mame=expected,godot=actual,match=ok)
            details.append(item)
            if not ok: failures.append(item)
    summary.append(dict(case=case,frames=len(selected),cell_samples=sum(d['case']==case for d in details),matched=matched,preambles=preambles))
result=dict(alignment='Godot F = MAME CPU F+1; absolute frame-by-frame, all affected cells',source=str(source),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),repeat_identical=True,summary=summary,unpaired=unpaired,failures=failures)
(out/'comparacao_facetas_temporal.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
(out/'comparacao_facetas_celulas.json').write_text(json.dumps(details,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
sys.exit(1 if failures else 0)
