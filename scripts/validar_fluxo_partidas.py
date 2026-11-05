"""Executa partidas integradas no Godot, com evidências separadas de lote e visual."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--matches', type=int, default=1000)
    parser.add_argument('--workers', type=int, default=4)
    parser.add_argument('--visual', action='store_true', help='Quatro casos em janela real, sem lote headless')
    parser.add_argument('--movie', type=Path, help='AVI gravado pelo MovieWriter do Godot; implica --visual')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.matches < 1 or not 1 <= args.workers <= 8:
        parser.error('Use --matches >= 1 e --workers entre 1 e 8')
    project = Path(__file__).resolve().parents[1]
    executable = project/'ferramentas/godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    visual = args.visual or args.movie is not None
    output = (args.output or project/'relatorios/rounds_integration'/('visual' if visual else 'bulk')).resolve()
    output.mkdir(parents=True, exist_ok=True)
    groups, remainder = divmod(args.matches, 4)
    counts = [4*(groups//args.workers + (index < groups % args.workers)) + (remainder if index == 0 else 0) for index in range(args.workers)]
    if visual:
        counts = [4]
    started = time.monotonic()

    def run(index, count):
        folder = output if visual else output/f'worker_{index+1}'
        folder.mkdir(parents=True, exist_ok=True)
        environment = dict(os.environ, PF_REPORT=str(folder), APPDATA=str(folder/'userdata'))
        command = [str(executable), '--path', str(project/'godot'), '--log-file', str(folder/'engine.log')]
        if not visual:
            command += ['--headless']
        if args.movie:
            args.movie.parent.mkdir(parents=True, exist_ok=True)
            command += ['--write-movie', str(args.movie.resolve()), '--fixed-fps', '30']
        script = 'test_match_flow_visual_v10_3_4.gd' if visual else 'test_match_flow.gd'
        command += ['--script', f'res://tests/{script}', '--', '--visual' if visual else f'--matches={count}']
        log = folder/'console.log'
        process = subprocess.Popen(command, cwd=project, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace')
        with log.open('w',encoding='utf-8') as stream:
            for line in process.stdout:
                stream.write(line)
                stream.flush()
                if 'MATCH_FLOW_' in line or 'ERROR' in line:
                    print(f'[worker {index+1}] {line.strip()}', flush=True)
        return_code = process.wait()
        report_path = folder/'integration_summary.json'
        report = json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {}
        raw = log.read_text(encoding='utf-8')
        passed = return_code == 0 and report.get('completed') == count and not report.get('failures') and 'SCRIPT ERROR' not in raw and 'ERROR:' not in raw
        return {'worker':index+1,'requested':count,'passed':passed,'exit_code':return_code,'log':str(log),'report':report}

    results = []
    with ThreadPoolExecutor(max_workers=len(counts)) as pool:
        futures = [pool.submit(run,index,count) for index,count in enumerate(counts) if count]
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda item:item['worker'])
    result = {'visual':visual,'requested':sum(counts),'completed':sum(item['report'].get('completed',0) for item in results),'rounds':sum(item['report'].get('rounds',0) for item in results),'checks':sum(item['report'].get('checks',0) for item in results),'elapsed_s':round(time.monotonic()-started,3),'passed':all(item['passed'] for item in results),'workers':results}
    (output/'summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({key:value for key,value in result.items() if key!='workers'}),flush=True)
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
