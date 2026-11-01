"""Confere fixtures observadas contra CSVs e dumps, sem recalcular regras do arcade."""
import argparse,csv,json,pathlib,re,struct

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--fixtures',type=pathlib.Path,default=pathlib.Path(__file__).with_name('mame_contact_fixtures.json'))
parser.add_argument('--session',type=pathlib.Path,action='append',help='Sessão MAME a confrontar; pode ser repetido')
args=parser.parse_args()
bundle=json.loads(args.fixtures.read_text(encoding='utf-8'))
expected={c['id']:{r['frame']:r for r in c['expected_samples']} for c in bundle['cases']}
root=args.fixtures.parent
sessions=args.session or [root/'runs/matrix_final',root/'runs/edges_first']
rows_checked=0;dumps_checked=0
for session in sessions:
    with (session/'contact.csv').open(encoding='utf-8',newline='') as stream:
        rows=list(csv.DictReader(stream))
    observed={(r['case'],int(r['frame'])):r for r in rows}
    for r in rows:
        want=expected[r['case']][int(r['frame'])]
        for k,v in r.items():
            if k=='case' or k not in want:continue
            value=int(v) if isinstance(want[k],int) else v
            assert value==want[k],(session,r['case'],r['frame'],k,value,want[k])
        rows_checked+=1
    for f in (session/'captures').glob('*.bin'):
        match=re.fullmatch(r'(.+)_f(\d+)\.bin',f.name)
        if not match:continue
        name,n=match.groups();r=observed[(name,int(n))];ram=f.read_bytes()
        assert len(ram)==65536
        for field,offset,fmt in [('x',0x8310,'>H'),('y',0x8314,'>H'),('offset',0x8542,'>h'),('rotation',0x8470,'B'),('contact',0x8476,'B'),('phase',0x847E,'B'),('turn',0x84A0,'>H')]:
            assert struct.unpack_from(fmt,ram,offset)[0]==int(r[field]),(f,field)
        cells=[struct.unpack_from('>H',ram,0xAB00+y*16+2*(x+1))[0] for y in range(14) for x in range(6)]
        assert cells==[int(v,16) for v in r['grid'].split(':')],f
        dumps_checked+=1
print(json.dumps({'passed':True,'cases_available':len(expected),'rows_checked':rows_checked,'cpu_ram_dumps_checked':dumps_checked,'scope':'Observations only; no Godot implementation or expected-value fitting'},ensure_ascii=False))
