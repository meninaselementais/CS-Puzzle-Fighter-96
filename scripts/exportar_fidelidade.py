"""Exporta observações independentes do arcade; não calcula regras de jogo esperadas."""
import argparse,csv,json,re,struct
from pathlib import Path
from automatizar_mame import sha256
from exportar_mecanicas import export,canonical,values


def valid(session):
    m=json.loads((session/'execucao.json').read_text())
    if not all(m.get(k) for k in ['fontes_preservadas','lua_concluiu','lua_sem_erros']):raise ValueError(f'Sessão inválida: {session}')
    return m


def profiles(session):
    valid(session)
    raw=(session/'attack_tables.bin').read_bytes()
    def words(address,count):return struct.unpack('>'+str(count)+'H',raw[address-0xff98:address-0xff98+count*2])
    permutations=[[v//2 for v in raw[i*8:i*8+6]] for i in range(8)]
    if not all(sorted(p)==list(range(6)) for p in permutations):raise ValueError('Permutação inválida na tabela')
    palette=words(0x10178,8)
    patterns=[[[palette[i]>>12 for i in words(0x10188+c*192+r*16,6)] for r in range(12)] for c in range(11)]
    if not all(v in [1,2,3,4] for p in patterns for row in p for v in row):raise ValueError('Cor inválida no padrão')
    return {'schema_version':1,'session':str(session),'table_sha256':sha256(session/'attack_tables.bin'),
            'permutations':permutations,'patterns':patterns,'counter_start':[v>>8 for v in words(0x10160,11)]}


def rng_samples(text):
    events=re.findall(r'(GLOBAL|PIECE)_(IN|OUT),([A-F0-9,]+)',text.replace('\n',''))
    if not events or len(events)%2:raise ValueError('Traço RNG incompleto')
    samples=[]
    for i in range(0,len(events),2):
        a,b=events[i:i+2]
        if a[0]!=b[0] or a[1]!='IN' or b[1]!='OUT':raise ValueError('Traço RNG fora de ordem')
        samples.append({'piece':a[0]=='PIECE','input':int(a[2].split(',')[-1],16),'expected':int(b[2].split(',')[-1],16)})
    return samples


def extract(mechanics,delivery,timing,rng):
    for p in [mechanics,delivery,timing,rng]:valid(p)
    data=export(mechanics)
    for row in csv.DictReader((delivery/'delivery.csv').open()):
        before=values({'board':row['before']},'board');after=values({'board':row['after']},'board')
        if sum(v&255 in (6,7) for v in after)!=int(row['amount']):raise ValueError('Entrega incompleta ou quantidade divergente')
        data['deliveries'].append({'id':row['case'],'target':1,'source':0,'character':int(row['character']),
            'permutation':int(row['permutation']),'amount':int(row['amount']),
            'input':[canonical(v) for v in before],'expected':[canonical(v) for v in after]})
    samples=rng_samples((rng/'rng_native.txt').read_text())
    timing_rows=list(csv.DictReader((timing/'timing.csv').open()))
    return data,{'rng':samples,'timing':timing_rows,'sources':{str(p):valid(p)['lua_sha256'] for p in [mechanics,delivery,timing,rng]}}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['mechanics','delivery','timing','rng','out']:p.add_argument('--'+name,type=Path,required=True)
    args=p.parse_args()
    try:
        if args.out.exists():raise ValueError('Destino existente; resultados não sobrescritos')
        data,controls=extract(args.mechanics,args.delivery,args.timing,args.rng)
        pattern=profiles(args.delivery)
        args.out.mkdir(parents=True)
        for name,value in [('mechanics_fixtures.json',data),('control_fixtures.json',controls),('attack_profiles.json',pattern)]:
            (args.out/name).write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')
        print(len(data['fixtures']),'resoluções;',len(data['deliveries']),'entregas;',len(data['counterattacks']),'contra-ataques;',len(controls['rng']),'RNG')
    except (OSError,ValueError,KeyError,struct.error) as error:p.exit(1,f'Erro: {error}\n')


if __name__=='__main__':main()
