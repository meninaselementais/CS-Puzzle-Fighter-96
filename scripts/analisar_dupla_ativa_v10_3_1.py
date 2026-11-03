"""Verifica somente o suplemento: PROJECT PRIMARY REPEAT NEW_OUTPUT.
Não sobrescreve saída existente e não requer dependências externas.
"""
import csv,hashlib,json,shutil,sys
from collections import defaultdict
from pathlib import Path
from png_rgb_v10_3_1 import read_rgb,changed_pixels,components,bbox

root,primary,repeat,out=map(Path,sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
    with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def save(name,data):
    with (out/name).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)

for name in ['states.csv','sprites.csv','injections.csv']:
    assert (primary/name).read_bytes()==(repeat/name).read_bytes(),name
    shutil.copyfile(primary/name,out/name)
for label,session in [('primary',primary),('repeat',repeat)]:
    manifest=json.loads((session/'execucao.json').read_text())
    assert manifest['versao'].startswith('MAME v0.289 ')
    assert manifest['exit_code']==0 and manifest['fontes_preservadas'] and manifest['lua_concluiu'] and manifest['lua_sem_erros']
    assert sha(session/'experimento.lua')==manifest['lua_sha256']
    for item in manifest['copias']:
        assert sha(Path(item['origem']))==item['sha256']
        # MAME legitimately updates the isolated EEPROM; all original sources stay intact.
        if Path(item['copia']).name!='eeprom':assert sha(Path(item['copia']))==item['sha256']
    shutil.copyfile(session/'execucao.json',out/f'execucao_{label}.json')

states=read(primary/'states.csv');sprites=read(primary/'sprites.csv');injections=read(primary/'injections.csv')
assert len(states)==576 and len(sprites)==23040
assert all(r['stage']=='setup' and r['frame']=='0' for r in injections)
keys=['isolated_approach','same_color_approach','empty_background_reference']
targets=keys[:2]
state_index={(r['scenario'],r['clock'],int(r['frame'])):r for r in states}
sprite_index={(r['scenario'],r['clock'],int(r['frame']),r['kind'],int(r['index'])):r for r in sprites}
events=[]
for key in targets:
    for clock,contact,deposit in [('cpu',15,31),('video',14,30)]:
        series=[state_index[key,clock,f] for f in range(1,97)]
        assert [int(r['contact']) for r in series[contact-1:contact+15]]==list(range(16,0,-1))
        assert series[deposit-1]['phase']=='1'
        assert all(r['input']=='0' and r['orientation']=='0' for r in series[:deposit])
        for f in range(1,deposit):
            a=sprite_index[key,clock,f,'active_next',0]
            b=sprite_index[key,clock,f,'active_next',1]
            assert (a['state'],a['tile'],a['attr'],a['dx'],a['dy'])==('2','23040','1','0','0')
            assert (b['state'],b['tile'],b['attr'],b['dx'],b['dy'])==('6','23040','3','0','0')
        events.extend([dict(scenario=key,clock=clock,event='first_contact',frame=contact),dict(scenario=key,clock=clock,event='contact_1',frame=deposit-1),dict(scenario=key,clock=clock,event='deposit_phase_1',frame=deposit)])
save('eventos.csv',events)
clock_matches=0
for key in keys:
    for f in range(1,96):
        a=state_index[key,'video',f];b=state_index[key,'cpu',f+1]
        assert all(a[k]==b[k] for k in a if k not in ['clock','frame'])
        for kind,ids in [('active_next',range(4)),('cell',range(42,78))]:
            for i in ids:
                a=sprite_index[key,'video',f,kind,i];b=sprite_index[key,'cpu',f+1,kind,i]
                assert all(a[k]==b[k] for k in a if k not in ['clock','frame'])
        clock_matches+=1

names=sorted(p.name for p in (primary/'snap').glob('*.png'))
assert len(names)==288
assert names==sorted(p.name for p in (repeat/'snap').glob('*.png'))
png_hashes=[]
for name in names:
    a=sha(primary/'snap'/name);b=sha(repeat/'snap'/name)
    assert a==b,name
    png_hashes.append(dict(file=name,primary_sha256=a,repeat_sha256=b,match=True))
save('repeticao_png_sha256.csv',png_hashes)

# A 96-frame paired empty-board reference captures the very same stage/background.
# Exact RGB subtraction precedes palette classification; no guessed threshold or resize.
backgrounds={f:read_rgb(primary/'snap'/f'empty_background_reference_f{f:03d}.png')[2] for f in range(1,97)}
measurements=[];contours=[];saved_masks={};roi=(16,128,112,208)
for key in targets:
    for f in range(1,97):
        w,h,im=read_rgb(primary/'snap'/f'{key}_f{f:03d}.png')
        assert (w,h)==(384,224)
        changed=changed_pixels(im,backgrounds[f],roi)
        if f>=2:assert all(48<=x<=63 for x,y in changed),('Background not stationary',key,f)
        blue=set();green=set();pink=set()
        for x,y in changed:
            r,g,b=im[y][x*3:x*3+3]
            if b>r and b>=g:blue.add((x,y))
            elif g>r and g>b:green.add((x,y))
            elif (r,g,b)==(255,187,187):pink.add((x,y))
            else:raise AssertionError(('Unclassified foreground pixel',key,f,x,y,(r,g,b)))
        assert changed==blue|green|pink
        masks={'all_changed':changed,'blue_body_total':blue,'green_body':green,'pink_halo':pink}
        if key=='same_color_approach' and f>=16:
            masks.update(blue_upper_slot={(x,y) for x,y in blue if 176<=y<=191},blue_lower_slot={(x,y) for x,y in blue if 192<=y<=207})
        if f>=3 and f<=31:
            # The pixels correspond to video-descriptor sample F-2 in this capture path.
            prev=state_index[key,'video',f-2]
            groups=sorted(components(blue),key=lambda c:bbox(c)[1])
            pivot=groups[0]
            top=(int(prev['y'])-2)*16+int(prev['offset'])+1
            assert bbox(pivot)==(49,top,62,top+13)
            assert bbox(green)==(49,top-16,62,top-3)
        for subject,mask in masks.items():
            bounds=bbox(mask)
            if bounds:
                x0,y0,x1,y1=bounds
                norm=sorted((x-x0,y-y0) for x,y in mask)
                shape=hashlib.sha256(json.dumps(norm,separators=(',',':')).encode()).hexdigest()
                edge={(x,y) for x,y in mask if any(p not in mask for p in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)])}
                row=dict(scenario=key,frame=f,subject=subject,x_min=x0,y_min=y0,x_max=x1,y_max=y1,width=x1-x0+1,height=y1-y0+1,area=len(mask),boundary_pixels=len(edge),components=len(components(mask)),shape_sha256=shape)
                # Exact horizontal runs, including any holes; reconstructs the full binary mask.
                for y in range(y0,y1+1):
                    xs=sorted(x for x,yy in mask if yy==y);runs=[]
                    for x in xs:
                        if runs and x==runs[-1][1]+1:runs[-1][1]=x
                        else:runs.append([x,x])
                    contours.append(dict(scenario=key,frame=f,subject=subject,y=y,runs=json.dumps(runs,separators=(',',':'))))
            else:row=dict(scenario=key,frame=f,subject=subject,x_min='',y_min='',x_max='',y_max='',width=0,height=0,area=0,boundary_pixels=0,components=0,shape_sha256='')
            measurements.append(row);saved_masks[key,f,subject]=mask
save('medicoes_pixels.csv',measurements);save('contornos_runs.csv',contours)

def metric(key,f,subject):return next(r for r in measurements if r['scenario']==key and r['frame']==f and r['subject']==subject)
for f in range(2,97):
    a=metric('isolated_approach',f,'blue_body_total');b=metric('isolated_approach',f,'green_body')
    assert (a['width'],a['height'],a['area'])==(14,14,184)
    assert (b['width'],b['height'],b['area'])==(14,14,184)
    assert a['shape_sha256']==metric('isolated_approach',2,'blue_body_total')['shape_sha256']
    assert b['shape_sha256']==metric('isolated_approach',2,'green_body')['shape_sha256']
    green=metric('same_color_approach',f,'green_body')
    assert green['shape_sha256']==b['shape_sha256'] and green['area']==184
for f in range(16,36):assert (metric('same_color_approach',f,'blue_body_total')['area'],metric('same_color_approach',f,'blue_body_total')['components'])==(368,2)
for f in range(36,40):assert (metric('same_color_approach',f,'blue_body_total')['width'],metric('same_color_approach',f,'blue_body_total')['height'],metric('same_color_approach',f,'blue_body_total')['area'])==(14,32,424)
for f in range(40,97):assert (metric('same_color_approach',f,'blue_body_total')['width'],metric('same_color_approach',f,'blue_body_total')['height'],metric('same_color_approach',f,'blue_body_total')['area'])==(16,32,488)
for f in range(36,40):assert metric('same_color_approach',f,'blue_body_total')['shape_sha256']==metric('same_color_approach',36,'blue_body_total')['shape_sha256']
for f in range(40,97):assert metric('same_color_approach',f,'blue_body_total')['shape_sha256']==metric('same_color_approach',40,'blue_body_total')['shape_sha256']
# Every nonempty halo is exactly the same translated 60-pixel ring, 16x16.
for r in measurements:
    if r['subject']=='pink_halo' and r['area']:assert (r['width'],r['height'],r['area'])==(16,16,60)

transitions=[]
for key in targets:
    for kind,index in [('active_next',0),('active_next',1),('cell',68),('cell',74)]:
        last=None
        for f in range(1,97):
            r=sprite_index[key,'video',f,kind,index]
            fields=['state','tile','attr','layout_flag','dx','dy','board_word']
            state=tuple(r[k] for k in fields)
            if state!=last:transitions.append(dict(scenario=key,frame=f,kind=kind,index=index,**{k:r[k] for k in fields}));last=state
save('transicoes_sprites.csv',transitions)

# Vector diagram of measured pixel masks, no resampling/editing of source PNGs.
panels=[('Duas gemas / F16','same_color_approach',16,'blue_body_total'),('Transição / F36','same_color_approach',36,'blue_body_total'),('Conexão / F40','same_color_approach',40,'blue_body_total'),('Halo / F29','isolated_approach',29,'pink_halo')]
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="920" height="300" viewBox="0 0 920 300">','<rect width="920" height="300" fill="#0c1422"/>','<g font-family="sans-serif" fill="#eee">','<text x="20" y="25" font-size="18">Contornos medidos • pixel nativo = 5 unidades • máscara RGB, sem halo no corpo</text>']
for i,(label,key,f,subject) in enumerate(panels):
    mask=saved_masks[key,f,subject];x0,y0,x1,y1=bbox(mask);xbase=35+i*225
    svg.append(f'<text x="{xbase}" y="60" font-size="16">{label}</text>')
    for x,y in mask:svg.append(f'<rect x="{xbase+(x-x0)*5}" y="{85+(y-y0)*5}" width="5" height="5" fill="{"#ffbbbb" if subject=="pink_halo" else "#69b9ff"}"/>')
    svg.append(f'<text x="{xbase}" y="270" font-size="14">{x1-x0+1}×{y1-y0+1} px · área {len(mask)}</text>')
svg+=['</g></svg>'];(out/'contornos_comparados.svg').write_text('\n'.join(svg),encoding='utf-8')
shutil.copytree(primary/'snap',out/'capturas')
summary=dict(primary=str(primary),repeat=str(repeat),supplemental_physics_cases=2,background_control_cases=1,frames_per_case=96,cpu_samples_per_run=288,video_samples_per_run=288,sprite_rows_per_run=23040,pngs_per_run=288,png_sha256_matches=288,states_identical=True,sprites_identical=True,injections_identical=True,video_f_matches_cpu_f_plus_1=clock_matches,pixel_alignment='PNG F matches video RAM F-2 for measured approach F3..31; tile transition landmarks also +2',new_native_percentage_claimed=False,initial_visible_gem_shape='14x14 / 184 pixels',same_color_intermediate='14x32 / 424 pixels / 4 frames F36..39',same_color_stable='16x32 / 488 pixels / F40..96',halo='16x16 / 60 pink pixels; not gem compression')
(out/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(summary,indent=2,ensure_ascii=False))
