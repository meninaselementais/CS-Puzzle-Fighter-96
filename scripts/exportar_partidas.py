"""Extrai endpoints das partidas sem injeção de RAM, inclusive divergências potenciais."""
import argparse,csv,json
from pathlib import Path
from automatizar_mame import sha256
from exportar_fidelidade import valid
from exportar_mecanicas import canonical,values,powers


def extract(session):
    valid(session);result=[]
    for row in csv.DictReader((session/'natural.csv').open()):
        parse=lambda field:[canonical(v) for v in values({'board':row[field]},'board')]
        result.append({'id':f'natural_e{row["episode"]}_p{row["player"]}_t{row["turn"]}_f{row["source_frame"]}',
            'player':int(row['player'])-1,'input':parse('input'),'expected':parse('expected'),
            'input_powers':powers({'grid1':row['input'],'aux1':row['aux_input']}),
            'expected_powers':powers({'grid1':row['expected'],'aux1':row['aux_expected']}),
            'expected_score':int(row['score_after'])-int(row['score_before']),
            'incoming':int(row['incoming']),'outgoing':int(row['outgoing']),
            'permutation':int(row['permutation']),'source_character':int(row['source_character']),
            'first_bonus':bool(int(row['first_bonus'])),
            'opponent_first_bonus':bool(int(row.get('opponent_first_bonus',0))),
            'source_frame':int(row['source_frame']),'target_frame':int(row['target_frame'])})
    if not result:raise ValueError('Nenhum endpoint concluído')
    return {'session':str(session),'csv_sha256':sha256(session/'natural.csv'),'fixtures':result,
            'scope':'Resolução por turno, com entradas e duplas observadas. Não é reprodução temporal completa da partida.'}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('session',type=Path);p.add_argument('--out',required=True,type=Path);p.add_argument('--overwrite',action='store_true')
    a=p.parse_args()
    try:
        data=extract(a.session)
        with a.out.open('w' if a.overwrite else 'x',encoding='utf-8') as f:json.dump(data,f,ensure_ascii=False,indent=2)
        print(len(data['fixtures']),'endpoints naturais exportados')
    except (OSError,ValueError,KeyError,AssertionError) as e:p.exit(1,f'Erro: {e}\n')


if __name__=='__main__':main()
