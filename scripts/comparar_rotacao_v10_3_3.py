"""Compare preserved real-scene captures with MAME; no emulator collection."""
from pathlib import Path
import csv, json, sys
from pathlib import Path
import struct,zlib
def png(path):
    data=Path(path).read_bytes();pos=8;compressed=[];bpp=0
    assert data[:8]==b'\x89PNG\r\n\x1a\n'
    while pos<len(data):
        n=struct.unpack_from('>I',data,pos)[0];k=data[pos+4:pos+8];v=data[pos+8:pos+8+n]
        assert zlib.crc32(k+v)&0xffffffff==struct.unpack_from('>I',data,pos+8+n)[0]
        if k==b'IHDR':
            w,h,depth,color,c,f,i=struct.unpack('>IIBBBBB',v);assert depth==8 and color in [2,6] and (c,f,i)==(0,0,0);bpp=3 if color==2 else 4
        if k==b'IDAT':compressed.append(v)
        pos+=n+12
    raw=zlib.decompress(b''.join(compressed));stride=w*bpp;previous=bytearray(stride);rows=[]
    for y in range(h):
        line=raw[y*(stride+1):(y+1)*(stride+1)];mode=line[0];r=bytearray(line[1:])
        for x in range(stride):
            a=r[x-bpp] if x>=bpp else 0;b=previous[x];c=previous[x-bpp] if x>=bpp else 0
            p=a+b-c;pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
            pred=[0,a,b,(a+b)//2,a if pa<=pb and pa<=pc else (b if pb<=pc else c)][mode]
            r[x]=(r[x]+pred)&255
        rows.append(bytes(r) if bpp==3 else b''.join(r[x:x+3] for x in range(0,stride,4)));previous=r
    return rows


root = Path(sys.argv[1])
out = Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
render = root / 'relatorios/v10_3_3/render'
native = root / 'laboratorio/auto_20261101_222825_850720/snap'
background = png(root / 'laboratorio/auto_20261102_172410_209057/snap/empty_background_reference_f061.png')
records = json.loads((render/'captures.json').read_text())['records']
fixtures = json.loads((root/'godot/data/pair_rotation_v10_3_3.json').read_text())
colors = {(case['id'],int(sample['frame'])):sample['colors'] for case in fixtures['primary'] for sample in case['samples']}
halo = bytes([255,187,187])

def pixel(im,x,y):
    return im[y][3*x:3*x+3]

def gp(im,x,y):
    return pixel(im,64+(x-16)*2,108+(y-16)*2)

# Independent, non-overlapping reference bodies, before the turn. Preserve RGB
# only within each renderer to establish ownership of pixels during overlap.
nref = png(native/'rotation_r0_b1_f004.png')
gref = png(render/'rotation_r0_b1_f003.png')
gbref = png(render/'rotation_r0_b1_f003_background.png')
ntemplates=[]; gtemplates=[]
for cy in [88,72]:
    nt={}; gt={}
    for dy in range(-8,8):
        for dx in range(-8,8):
            x,y=56+dx,cy+dy
            if pixel(nref,x,y)!=pixel(background,x,y) and pixel(nref,x,y)!=halo:
                nt[dx,dy]=pixel(nref,x,y)
            if gp(gref,x,y)!=gp(gbref,x,y): gt[dx,dy]=gp(gref,x,y)
    assert len(nt)==len(gt)==184
    assert nt.keys()==gt.keys()
    ntemplates.append(nt);gtemplates.append(gt)

results=[]
for row in records:
    if row['case'].startswith('edge_') or not 4<=int(row['frame'])<=11: continue
    case=row['case']; f=int(row['frame'])
    ni=png(native/f'{case}_f{f+1:03}.png')
    gi=png(render/f'{case}_f{f:03}.png')
    gb=png(render/f'{case}_f{f:03}_background.png')
    centers=[(round(24+p[0]*16),round(24+(p[1]-2)*16)) for p in [row['pivot'],row['satellite']]]
    parts=[{(cx+dx,cy+dy) for dx,dy in ntemplates[i]} for i,(cx,cy) in enumerate(centers)]
    expected=parts[0]|parts[1]
    x0=min(x for x,y in expected)-1;x1=max(x for x,y in expected)+2
    y0=min(y for x,y in expected)-1;y1=max(y for x,y in expected)+2
    if case.startswith('corridor_'): x0,x1=48,64
    gm=set();nm=set();nonuniform=0
    for y in range(y0,y1):
        for x in range(x0,x1):
            gx=64+(x-16)*2;gy=108+(y-16)*2
            changed=[pixel(gi,gx+dx,gy+dy)!=pixel(gb,gx+dx,gy+dy) for dy in [0,1] for dx in [0,1]]
            nonuniform+=len(set(changed))!=1
            if changed[0]:gm.add((x,y))
            c=pixel(ni,x,y)
            if c!=pixel(background,x,y) and c!=halo:nm.add((x,y))
    overlap=parts[0]&parts[1]
    nwrong=gwrong=0
    for x,y in overlap:
        cx,cy=centers[1];local=x-cx,y-cy
        color_index=int(colors[case,f][1])-1
        nwrong+=pixel(ni,x,y)!=ntemplates[color_index][local]
        gwrong+=gp(gi,x,y)!=gtemplates[color_index][local]
    result=dict(case=case,godot_frame=f,mame_png_frame=f+1,timer=row['timer'],
        godot_pixels=len(gm),mame_pixels=len(nm),different_pixels=len(gm^nm),
        godot_expected_difference=len(gm^expected),mame_expected_difference=len(nm^expected),
        nonuniform_blocks=nonuniform,overlap_pixels=len(overlap),
        mame_occlusion_errors=nwrong,godot_occlusion_errors=gwrong)
    results.append(result)
    print(case,f,'mask',len(gm^nm),'overlap',len(overlap),'ownership',nwrong,gwrong,flush=True)

with (out/'comparacao_rotacao_mame.csv').open('w',newline='',encoding='utf-8') as file:
    writer=csv.DictWriter(file,fieldnames=results[0]);writer.writeheader();writer.writerows(results)
summary=dict(pairs=len(results),different_pixels=sum(r['different_pixels'] for r in results),
    overlap_frames=sum(r['overlap_pixels']>0 for r in results),overlap_pixels=sum(r['overlap_pixels'] for r in results),
    mame_occlusion_errors=sum(r['mame_occlusion_errors'] for r in results),
    godot_occlusion_errors=sum(r['godot_occlusion_errors'] for r in results),
    nonuniform_blocks=sum(r['nonuniform_blocks'] for r in results))
(out/'comparacao_rotacao_summary.json').write_text(json.dumps(summary,indent=2))
print(summary,flush=True)
assert len(results)==80
assert all(not r[k] for r in results for k in ['different_pixels','godot_expected_difference','mame_expected_difference','nonuniform_blocks','mame_occlusion_errors','godot_occlusion_errors'])
