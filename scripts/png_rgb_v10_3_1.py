"""Leitor PNG RGB8 sem dependências; valida CRC e reconstrói os cinco filtros PNG."""
import struct,zlib
from pathlib import Path

def read_rgb(path):
    data=Path(path).read_bytes()
    assert data[:8]==b'\x89PNG\r\n\x1a\n'
    offset=8;compressed=[];width=height=0
    while offset<len(data):
        length=struct.unpack_from('>I',data,offset)[0]
        kind=data[offset+4:offset+8];payload=data[offset+8:offset+8+length]
        assert zlib.crc32(kind+payload)&0xffffffff==struct.unpack_from('>I',data,offset+8+length)[0]
        if kind==b'IHDR':
            width,height,depth,color,comp,flt,interlace=struct.unpack('>IIBBBBB',payload)
            assert (depth,color,comp,flt,interlace)==(8,2,0,0,0)
        elif kind==b'IDAT':compressed.append(payload)
        elif kind==b'IEND':break
        offset+=12+length
    raw=zlib.decompress(b''.join(compressed));stride=width*3
    assert len(raw)==height*(stride+1)
    rows=[];prior=bytearray(stride)
    for y in range(height):
        line=raw[y*(stride+1):(y+1)*(stride+1)];mode=line[0];current=bytearray(line[1:])
        assert 0<=mode<=4
        for x in range(stride):
            a=current[x-3] if x>=3 else 0;b=prior[x];c=prior[x-3] if x>=3 else 0
            if mode==1:predict=a
            elif mode==2:predict=b
            elif mode==3:predict=(a+b)//2
            elif mode==4:
                p=a+b-c;pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
                predict=a if pa<=pb and pa<=pc else (b if pb<=pc else c)
            else:predict=0
            current[x]=(current[x]+predict)&255
        rows.append(bytes(current));prior=current
    return width,height,rows

def changed_pixels(image,background,roi):
    x0,y0,x1,y1=roi
    return {(x,y) for y in range(y0,y1) for x in range(x0,x1) if image[y][x*3:x*3+3]!=background[y][x*3:x*3+3]}

def components(points):
    pending=set(points);result=[]
    while pending:
        start=pending.pop();group={start};queue=[start]
        while queue:
            x,y=queue.pop()
            for near in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                if near in pending:pending.remove(near);group.add(near);queue.append(near)
        result.append(group)
    return sorted(result,key=lambda p:-len(p))

def bbox(points):
    if not points:return None
    xs=[p[0] for p in points];ys=[p[1] for p in points]
    return min(xs),min(ys),max(xs),max(ys)

if __name__=='__main__':
    # Five filters encode the same 2-pixel row; exercise each predictor including Paeth.
    import tempfile
    desired=bytes([30,60,90,50,80,110]);prior=bytes([10,20,30,40,50,60])
    for mode in range(5):
        encoded=[]
        for x,v in enumerate(desired):
            a=desired[x-3] if x>=3 else 0;b=prior[x];c=prior[x-3] if x>=3 else 0
            p=a+b-c;pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
            preds=[0,a,b,(a+b)//2,a if pa<=pb and pa<=pc else (b if pb<=pc else c)]
            encoded.append((v-preds[mode])&255)
        def chunk(k,v):return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
        data=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',2,2,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b'\x00'+prior+bytes([mode])+bytes(encoded)))+chunk(b'IEND',b'')
        with tempfile.TemporaryDirectory() as tmp:
            path=Path(tmp)/'test.png';path.write_bytes(data)
            assert read_rgb(path)==(2,2,[prior,desired])
    assert len(components({(0,0),(1,0),(5,5)}))==2
    print('PNG_SELF_CHECK: 5 filters, CRC, dimensions and components PASS')
