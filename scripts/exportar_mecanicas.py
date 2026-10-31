"""Exporta casos do arcade para a comparação independente do resolvedor Godot."""
import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from automatizar_mame import sha256


def canonical(value):
    if value == 0:
        return 0
    color = value & 7
    if value & 255 in (6, 7):
        return ((value >> 12 & 7) << 12) | ((value >> 8 & 15) << 8) | 7
    if color == 5:
        return 5
    if color not in (1, 2, 3, 4):
        return value
    return color | (128 if value & 128 else 8 if value & 8 else 0)


def values(row, field):
    result=[int(v, 16) for v in row[field].split(':')]
    if len(result)!=84 or any(v<0 or v>65535 for v in result):
        raise ValueError(f'Grade inválida: {field}')
    return result


def powers(row):
    board=values(row,'grid1');aux=values(row,'aux1');rects=[]
    for y in range(14):
        for x in range(6):
            i=y*6+x
            if aux[i]&15 != 2 or not board[i]&128:
                continue
            for h in range(2,15-y):
                for w in range(2,7-x):
                    if aux[y*6+x+w-1]&15 == 8 and aux[(y+h-1)*6+x]&15 == 1 and aux[(y+h-1)*6+x+w-1]&15 == 4:
                        cells=[board[r*6+c] for r in range(y,y+h) for c in range(x,x+w)]
                        if all(v&128 and v&7==board[i]&7 for v in cells):rects.append([x,y,w,h])
    return sorted(rects)


def export(session):
    execution=json.loads((session/'execucao.json').read_text(encoding='utf-8'))
    if not all(execution.get(k) for k in ['fontes_preservadas','lua_concluiu','lua_sem_erros']):
        raise ValueError('Execução inválida')
    groups=defaultdict(list)
    with (session/'mechanics.csv').open(encoding='utf-8') as stream:
        for row in csv.DictReader(stream):groups[row['case']].append(row)
    fixtures=[];summary=[];deliveries=[];counterattacks=[]
    for name,rows in groups.items():
        timeline={int(row['frame']):row for row in rows}
        baseline=int(rows[0]['turn1']);transitions=[];last=baseline
        for row in rows:
            turn=int(row['turn1'])
            if turn!=last:
                transitions.append(int(row['frame']));last=turn
        summary.append({'case':name,'frames':len(rows),'score1':int(rows[-1]['score1']),
                        'score2':int(rows[-1]['score2']),'transitions':transitions})
        if name.startswith('counterattack_'):
            for pos,row in enumerate(rows[1:-1],1):
                before=rows[pos-1];after=rows[pos+1]
                delta=int(row['score2'])-int(before['score2'])
                incoming=int(before['pending2'])
                if delta>100 and incoming>0:
                    counterattacks.append({'id':name,'incoming':incoming,'attack':delta//100,
                        'expected_pending':int(after['pending2']),
                        'expected_outgoing':int(after['pending1'])-int(before['pending1'])})
        if name in ['attack_red8','attack_red12','attack_p2_red12','attack_cancel'] or name.startswith('score_normal_'):
            target=0 if name=='attack_p2_red12' else 1
            field=f'grid{target+1}'
            arrival=next((int(r['frame']) for r in rows if any(v&255 in (6,7) for v in values(r,field))),None)
            if arrival and arrival+50<=len(rows):
                before=timeline[arrival-1];after=timeline[arrival+50]
                expected=[canonical(v) for v in values(after,field)]
                amount=sum(v&255==7 for v in expected)
                deliveries.append({'id':name,'target':target,'source':1-target,'amount':amount,
                    'permutation':int(before.get(f'permutation{target+1}',0)),
                    'character':2 if target==1 else 3,
                    'source_frame':arrival-1,'target_frame':arrival+50,
                    'input':[canonical(v) for v in values(before,field)],'expected':expected})
        if name in ['topout_center','topout_side','attack_cancel','attack_p2_red12'] or name.startswith(('cancel_','counterattack_')) or not transitions:
            continue
        starts=transitions[:5] if name=='counter_countdown' else transitions[:2] if name in ['power_growth','power_union'] else transitions[:1]
        for step,start in enumerate(starts):
            end=min(start+150,len(rows))
            if name in ['power_growth','power_union','counter_countdown']:end=min(start+100,len(rows))
            if name in ['power_growth','power_union'] and step==0:end=100
            if name.startswith('chain_3'):end=235
            before=timeline[start];after=timeline[end]
            fixtures.append({'id':name+(f'_turn{step+1}' if len(starts)>1 else ''),'case':name,
                'source_frame':start,'target_frame':end,'decrement_counters':True,
                'input':[canonical(v) for v in values(before,'grid1')],'input_powers':powers(before),
                'expected':[canonical(v) for v in values(after,'grid1')],'expected_powers':powers(after),
                'expected_score':int(after['score1'])-int(before['score1']),
                'expected_attack':int(after['pending2'])-int(before['pending2']),
                'compare_attack':int(after['pending2'])>=int(before['pending2']) and end<241})
    return {'schema_version':1,'session':str(session),'csv_sha256':sha256(session/'mechanics.csv'),
            'lua_sha256':execution['lua_sha256'],'fixtures':fixtures,'deliveries':deliveries,'counterattacks':counterattacks,'summary':summary,
            'note':'Fixtures sintéticas na RAM, resolvidas pelo arcade; normalização remove somente flags gráficas e de animação.'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('session',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    try:
        result=export(args.session.resolve(strict=True))
        args.out.parent.mkdir(parents=True,exist_ok=True)
        with args.out.open('x',encoding='utf-8') as stream:json.dump(result,stream,ensure_ascii=False,indent=2)
        print(f'{len(result["fixtures"])} fixtures de {len(result["summary"])} casos exportadas')
    except (OSError,ValueError,KeyError) as error:parser.exit(1,f'Erro: {error}\n')


if __name__=='__main__':main()
