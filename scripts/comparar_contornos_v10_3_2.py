from pathlib import Path
import csv,json,struct,zlib,sys

def bbox(points):
    if not points:return None
    return min(x for x,y in points),min(y for x,y in points),max(x for x,y in points),max(y for x,y in points)

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

root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(r'C:\Projetos\CS-Puzzle-Fighter-96')
out=Path(sys.argv[2]) if len(sys.argv)>2 else Path(__file__).resolve().parents[2]/'outputs/v10_3_2'
native=root/'laboratorio/auto_20261102_172410_209057/snap'
cache={}
def get(p):
    if p not in cache:cache[p]=png(p)
    return cache[p]
comparisons=[]
for case,ref in [('isolated','isolated_approach'),('same_color','same_color_approach')]:
    for f in [1,2,14,15,16,30,31,35,39,40]:
        godot=get(out/'render'/f'{case}_f{f:03d}.png');bg=get(out/'render'/f'background_f{f:03d}.png')
        mame=get(native/f'{ref}_f{f+1:03d}.png');mbg=get(native/f'empty_background_reference_f{f+1:03d}.png')
        gm=set();nm=set()
        for y in range(128,208):
            for x in range(16,112):
                if mame[y][3*x:3*x+3]!=mbg[y][3*x:3*x+3]:nm.add((x,y))
                gx=64+(x-16)*2;gy=108+(y-16)*2
                changes=[godot[gy+dy][3*(gx+dx):3*(gx+dx)+3]!=bg[gy+dy][3*(gx+dx):3*(gx+dx)+3] for dy in [0,1] for dx in [0,1]]
                assert len(set(changes))==1,('non-native pixel alignment',case,f,x,y)
                if changes[0]:gm.add((x,y))
        comparisons.append(dict(case=case,godot_frame=f,mame_png_frame=f+1,godot_pixels_native_scale=len(gm),mame_pixels=len(nm),different_pixels=len(gm^nm),match=gm==nm,godot_bounds=str(bbox(gm)),mame_bounds=str(bbox(nm))))
with (out/'comparacao_contornos_mame.csv').open('w',encoding='utf-8',newline='') as file:
    w=csv.DictWriter(file,fieldnames=list(comparisons[0]));w.writeheader();w.writerows(comparisons)
print(json.dumps(comparisons,indent=2))
assert all(r['match'] for r in comparisons),'See native-pixel comparison differences'

fall_comparisons=[]
for f in [2,3,4,5]:
    native_frame=f+56
    old=get(root/'laboratorio/auto_20261101_001520_164035/snap'/f'split_r1_pivot_depth3_f{native_frame:03d}.png')
    mbg=get(native/'empty_background_reference_f061.png')
    # First prove the reused empty reference has the same static background outside occupied columns.
    outside=sum(old[y][3*x:3*x+3]!=mbg[y][3*x:3*x+3] for y in range(128,208) for x in range(16,112) if x<48 or x>=80)
    assert outside==0,('old capture background differs',f,outside)
    godot=get(out/'render'/f'split_f{f:03d}.png');bg=get(out/'render'/f'background_f{f:03d}.png') if (out/'render'/f'background_f{f:03d}.png').exists() else get(out/'render'/'background_f002.png')
    gm=set();nm=set()
    for y in range(128,208):
        for x in range(64,80):
            if old[y][3*x:3*x+3]!=mbg[y][3*x:3*x+3]:nm.add((x,y))
            gx=64+(x-16)*2;gy=108+(y-16)*2
            if godot[gy][3*gx:3*gx+3]!=bg[gy][3*gx:3*gx+3]:gm.add((x,y))
    fall_comparisons.append(dict(godot_frame=f,mame_png_frame=native_frame,native_case='split_r1_pivot_depth3',background_differences_outside_occupied_columns=outside,different_pixels=len(gm^nm),match=gm==nm,godot_bounds=str(bbox(gm)),mame_bounds=str(bbox(nm))))
with (out/'comparacao_queda_mame.csv').open('w',encoding='utf-8',newline='') as file:
    writer=csv.DictWriter(file,fieldnames=list(fall_comparisons[0]));writer.writeheader();writer.writerows(fall_comparisons)
print('FALL:',json.dumps(fall_comparisons,indent=2))
assert all(r['match'] for r in fall_comparisons),'Fall geometry differs from captured MAME pixels'
