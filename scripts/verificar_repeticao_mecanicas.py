"""Confere duas execuções independentes do mesmo experimento, sem alterar as sessões."""
import argparse
import json
from pathlib import Path
from automatizar_mame import sha256


def compare(first, second):
    manifests=[]
    for session in (first,second):
        manifest=json.loads((session/'execucao.json').read_text(encoding='utf-8'))
        if not all(manifest.get(k) for k in ['fontes_preservadas','lua_concluiu','lua_sem_erros']):
            raise ValueError(f'Sessão inválida: {session}')
        manifests.append(manifest)
    if manifests[0]['lua_sha256']!=manifests[1]['lua_sha256']:
        raise ValueError('Experimentos Lua diferentes')
    if sha256(first/'sta/spf2tu/input.sta')!=sha256(second/'sta/spf2tu/input.sta'):
        raise ValueError('Estados de partida diferentes')
    names1={p.name for p in (first/'captures').glob('*.bin')}
    names2={p.name for p in (second/'captures').glob('*.bin')}
    differences=sorted(names1^names2)
    for name in sorted(names1&names2):
        if sha256(first/'captures'/name)!=sha256(second/'captures'/name):differences.append(name)
    same_csv=sha256(first/'mechanics.csv')==sha256(second/'mechanics.csv')
    return {'first':str(first),'second':str(second),'lua_sha256':manifests[0]['lua_sha256'],
            'ram_dumps':len(names1&names2),'different_dumps':differences,'csv_identical':same_csv,
            'all_match':not differences and same_csv,
            'source_hashes_preserved':all(sha256(item['origem'])==item['sha256'] for m in manifests for item in m['copias'])}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('first',type=Path);parser.add_argument('second',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    try:
        result=compare(args.first.resolve(strict=True),args.second.resolve(strict=True))
        args.out.parent.mkdir(parents=True,exist_ok=True)
        with args.out.open('x',encoding='utf-8') as stream:json.dump(result,stream,ensure_ascii=False,indent=2)
        print(json.dumps(result,ensure_ascii=False))
        return 0 if result['all_match'] and result['source_hashes_preserved'] else 1
    except (OSError,ValueError,KeyError) as error:parser.exit(1,f'Erro: {error}\n')


if __name__=='__main__':raise SystemExit(main())
