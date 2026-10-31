"""Reexecuta as baterias existentes e as regressões visuais, preservando logs separados."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true', help='Também executa os testes de janela e renderização OpenGL')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = args.output or project / 'relatorios/coin_flip/final'
    output.mkdir(parents=True, exist_ok=True)
    godot = project / 'ferramentas/godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', APPDATA=str(output / 'userdata'), PF_REPORT=str(output))
    commands = [('python', [sys.executable, '-B', '-m', 'unittest', 'discover', '-s', 'tests', '-v'])]
    for name in ['test_models', 'test_rules', 'test_fidelity', 'test_controls_fidelity', 'test_natural_fidelity', 'test_duel', 'test_presentation', 'test_animation_v8', 'test_art_v9', 'test_character_select', 'test_coin_flip']:
        commands.append((name, [str(godot), '--headless', '--path', str(project/'godot'), '--log-file', str(output/(name+'_engine.log')), '--script', 'res://tests/'+name+'.gd']))
    if args.render:
        for name in ['render_preview', 'render_mechanics', 'test_showcase_ui', 'test_character_select_ui', 'render_chains_and_c4_demo']:
            commands.append((name, [str(godot), '--path', str(project/'godot'), '--log-file', str(output/(name+'_engine.log')), '--script', 'res://tests/'+name+'.gd']))
    if args.render:
        commands[-1][1].extend(['--','--output',str(output/'legacy_demo')])
    results = []
    for name, command in commands:
        started = time.monotonic()
        try:
            completed = subprocess.run(command, cwd=project, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
            text = completed.stdout + completed.stderr
            passed = completed.returncode == 0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text
            result = {'name':name,'passed':passed,'exit_code':completed.returncode,'seconds':round(time.monotonic()-started,3),'command':command}
        except subprocess.TimeoutExpired as error:
            text = 'TIMEOUT: '+str(error)
            result = {'name':name,'passed':False,'timeout':True,'command':command}
        (output/(name+'.log')).write_text(text,encoding='utf-8')
        results.append(result)
        print(name, 'PASS' if result['passed'] else 'FAIL', flush=True)
    (output/'summary.json').write_text(json.dumps({'scope':'Existing MAME-derived fixtures; not a new full-match MAME synchronization test','results':results},ensure_ascii=False,indent=2),encoding='utf-8')
    return 0 if all(r['passed'] for r in results) else 1


if __name__ == '__main__':
    sys.exit(main())
