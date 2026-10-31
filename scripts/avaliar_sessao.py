"""Valida a bateria MAME e exporta estados independentes do emulador para Godot."""
import argparse
import colorsys
import csv
import hashlib
import json
import re
import struct
from collections import Counter, defaultdict
from pathlib import Path

from analisar_puzzle import grid, number
from comparar_memoria import load_dump, write_csv

COLOR_IDS = {'blue': 1, 'yellow': 2, 'green': 3, 'red': 4}
OFFSETS = ((0, -1), (1, 0), (0, 1), (-1, 0))


def pixel_color(pixels, width, height, x, y, byteorder='little'):
    if not (4 <= x < width-4 and 4 <= y < height-4):
        return None
    votes=Counter()
    for dy in range(-4,5):
        for dx in range(-4,5):
            value=struct.unpack_from('<I' if byteorder=='little' else '>I', pixels, ((y+dy)*width+x+dx)*4)[0]
            hue,sat,bright=colorsys.rgb_to_hsv((value>>16&255)/255,(value>>8&255)/255,(value&255)/255)
            if sat < .45 or bright < .35:
                continue
            label=('red' if hue < .07 or hue > .94 else 'yellow' if .08 < hue < .20 else
                   'green' if .20 <= hue < .48 else 'blue' if .50 < hue < .76 else 'other')
            votes[label]+=1
    if not votes:
        return None
    label,count=votes.most_common(1)[0]
    return label if label in COLOR_IDS and count >= 4 and count/sum(votes.values()) >= .6 else None


def state(data, player):
    shift=player*0x400
    rows,valid=grid(data,0xFFAB00+player*0x200)
    if not valid:
        raise ValueError('Bordas de grade inválidas na partida')
    y=number(data,0xFF8314+shift)
    fraction=number(data,0xFF8542+shift,signed=True)
    return {'x':number(data,0xFF8310+shift),'y':y,'fraction_y':fraction,'render_y':y-1+fraction/16,
            'rotation':data[0x8470+shift], 'colors':[0,0],
            'cells':[value for row in rows[:14] for value in row[1:7]]}


def validate_protocol(session):
    execution=json.loads((session/'execucao.json').read_text(encoding='utf-8'))
    if not execution.get('fontes_preservadas') or not execution.get('lua_concluiu'):
        raise ValueError('Execução ou integridade não confirmadas')
    if '[LUA ERROR]' in (session/'mame.log').read_text(encoding='utf-8',errors='replace'):
        raise ValueError('A sessão contém erros Lua e não deve ser consolidada')
    rows=list(csv.DictReader((session/'eventos.csv').open(encoding='utf-8')))
    groups=defaultdict(list)
    for row in rows:
        groups[row['case']].append(row)
    if len(groups) < 24 or not (session/'concluido.txt').exists():
        raise ValueError('Bateria incompleta')
    hashes=set()
    for case,items in groups.items():
        if [int(row['frame']) for row in items] != list(range(len(items))):
            raise ValueError(f'Quadros ausentes em {case}')
        if items[0]['in0'] != 'FFFF':
            raise ValueError(f'Cache de entrada não neutro em {case}')
        base=load_dump(session/'captures'/f'{case}_base.bin')
        hashes.add(hashlib.sha256(base).hexdigest())
    if len(hashes)!=1:
        raise ValueError('Os estados iniciais diferem')
    for a,b in [('controle_a','controle_b'),('direita_a','direita_b'),
                ('esquerda_a','esquerda_b'),('rotacao_1','rotacao_1_rep')]:
        for frame in range(1,17):
            if (session/'captures'/f'{a}_f{frame:03d}.bin').read_bytes() != (session/'captures'/f'{b}_f{frame:03d}.bin').read_bytes():
                raise ValueError(f'Repetição divergente: {a}, {b}, quadro {frame}')
    return groups,next(iter(hashes))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('session',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    try:
        session=args.session.resolve(strict=True)
        groups,base_hash=validate_protocol(session)
        video=json.loads((session/'video.json').read_text(encoding='utf-8'))
        frames=[];by_key={};evidence=[];color_votes=defaultdict(Counter);active_votes=defaultdict(Counter)
        for case,rows in groups.items():
            for row in rows:
                frame=int(row['frame']);suffix='base' if frame==0 else f'f{frame:03d}'
                stem=f'{case}_{suffix}'
                data=load_dump(session/'captures'/(stem+'.bin'))
                item={'case':case,'frame':frame,'time_us':int(row['time_us']),
                      'players':[state(data,0),state(data,1)]}
                raw_image=session/'snap'/(stem+'.argb')
                if raw_image.exists() and frame>0:
                    pixels=raw_image.read_bytes();w,h=video['width'],video['height']
                    if len(pixels)!=w*h*4:
                        raise ValueError(f'Tamanho de vídeo inválido: {raw_image}')
                    for player,current in enumerate(item['players']):
                        origin=24+256*player
                        for y in range(2,14):
                            for x in range(6):
                                code=current['cells'][y*6+x]
                                if code not in (1,2,3,4):
                                    continue
                                observed=pixel_color(pixels,w,h,origin+x*16,y*16-8,video['byteorder'])
                                if observed:
                                    color_votes[code][observed]+=1
                                    evidence.append({'case':case,'frame':frame,'player':player+1,'x':x,'y':y,'code':code,'observed':observed})
                        if current['rotation'] in range(4) and 2 <= current['render_y'] < 13 and current['x'] in range(6):
                            dx,dy=OFFSETS[current['rotation']]
                            for index,(x,y) in enumerate([(current['x'],current['render_y']),(current['x']+dx,current['render_y']+dy)]):
                                observed=pixel_color(pixels,w,h,origin+x*16,round(y*16-8),video['byteorder'])
                                if observed:
                                    current['colors'][index]=COLOR_IDS[observed]
                                    active_votes[player+1][observed]+=1
                frames.append(item);by_key[case,frame]=item
        outcomes=[]
        for case,rows in groups.items():
            last=int(rows[-1]['frame']);control='controle_480' if last>48 else 'controle_48'
            action=load_dump(session/'captures'/f'{case}_f{last:03d}.bin')
            neutral=load_dump(session/'captures'/f'{control}_f{last:03d}.bin')
            current=by_key[case,last]
            outcomes.append({'case':case,'frames':last,'different_bytes':sum(a!=b for a,b in zip(action,neutral)),
                             'p1':{key:current['players'][0][key] for key in ('x','y','rotation')},
                             'p2':{key:current['players'][1][key] for key in ('x','y','rotation')}})
        checks={}
        def check(name,condition):
            checks[name]=bool(condition)
        def p(case,player=0,frame=16): return by_key[case,frame]['players'][player]
        for player,prefix in [(0,''),(1,'p2_')]:
            control=p('controle_a',player)
            right=p('direita_a' if player==0 else 'p2_direita',player)
            left=p('esquerda_a' if player==0 else 'p2_esquerda',player)
            down=p('baixo_16' if player==0 else 'p2_baixo',player)
            check(prefix+'horizontal',right['x']==control['x']+1 and left['x']==control['x']-1 and right['y']==left['y']==control['y'])
            check(prefix+'queda',down['y']>control['y'] and down['x']==control['x'])
            check(prefix+'rotacao',p('rotacao_1' if player==0 else 'p2_rotacao',player)['rotation']==3 and
                  p('rotacao_2' if player==0 else 'p2_rotacao_2',player)['rotation']==1)
        check('limites_laterais',p('direita_48',frame=48)['x']==5 and p('esquerda_48',frame=48)['x']==0)
        check('rotacao_180',p('rotacao_180')['rotation']==2)
        check('rotacao_completa',p('rotacao_completa',frame=20)['rotation']==0)
        independent=True
        for case,actor in [('direita_a',0),('esquerda_a',0),('rotacao_1',0),('baixo_16',0),
                           ('p2_direita',1),('p2_esquerda',1),('p2_rotacao',1),('p2_baixo',1)]:
            independent &= all(p(case,1-actor)[key]==p('controle_a',1-actor)[key] for key in ('x','y','rotation','cells'))
        check('independencia_dos_jogadores',independent)
        check('geometria_e_cores_da_dupla_na_imagem',all(p(case)['colors']==[2,4] for case in
              ['controle_a','direita_a','esquerda_a','rotacao_1','rotacao_2','rotacao_180']))
        for player,case in [(0,'baixo_48'),(1,'p2_baixo_48')]:
            current=p(case,player,48);other=p(case,1-player,48)
            neutral=p('controle_48',player,48);other_neutral=p('controle_48',1-player,48)
            check(f'grade_p{player+1}',current['cells']!=neutral['cells'] and other['cells']==other_neutral['cells'])
        for code,label in [(1,'blue'),(2,'yellow'),(3,'green'),(4,'red')]:
            votes=color_votes[code]
            check('cor_'+str(code),votes[label]>=3 and votes[label]==sum(votes.values()))
        args.out.mkdir(parents=True,exist_ok=False)
        result={'session':str(session),'cases':len(groups),'frames':len(frames),'base_sha256':base_hash,
                'repetitions_identical':True,'checks':checks,'all_checks_pass':all(checks.values()),
                'color_votes':{str(code):dict(votes) for code,votes in color_votes.items()},'outcomes':outcomes}
        (args.out/'validacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
        write_csv(args.out/'evidencias_cores.csv',['case','frame','player','x','y','code','observed'],evidence)
        dataset={'schema_version':1,'columns':6,'rows':14,'hidden_rows':2,
                 'color_ids':COLOR_IDS,'source_session':str(session),'frames':frames}
        (args.out/'replay_mame.json').write_text(json.dumps(dataset,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
        print(json.dumps({key:result[key] for key in ['cases','frames','checks','color_votes','all_checks_pass']},indent=2))
        if not result['all_checks_pass']:
            parser.exit(2,'Há verificações reprovadas; consultar validacao.json.\n')
    except (OSError,ValueError,KeyError,IndexError) as error:
        parser.exit(1,f'Erro: {error}\n')


if __name__=='__main__': main()
