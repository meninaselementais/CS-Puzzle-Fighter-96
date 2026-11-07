from pathlib import Path
import os, subprocess, json, re, sys, hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
GODOT=ROOT/'ferramentas/godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe'
phase=sys.argv[1] if len(sys.argv)>1 else 'focused'
results=[]
def run(name, script, headless=True, extra=(), marker=None):
    folder=OUT/'evidence'/name
    folder.mkdir(parents=True,exist_ok=True)
    env=os.environ.copy()
    env.update(PF_REPORT=str(folder),APPDATA=str(folder/'userdata'),LOCALAPPDATA=str(folder/'userdata'))
    cmd=[str(GODOT),'--path',str(ROOT/'godot'),'--log-file',str(folder/'godot.log')]
    if headless: cmd.append('--headless')
    cmd+=['--script','res://tests/'+script+'.gd']
    if extra: cmd+=['--',*extra]
    try:
        proc=subprocess.run(cmd,cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
        log=proc.stdout.decode('utf-8',errors='replace')
        code=proc.returncode
    except subprocess.TimeoutExpired as e:
        log=(e.stdout or b'').decode('utf-8',errors='replace')+'\nTIMEOUT'
        code=-1
    (folder/'console.log').write_text(log,encoding='utf-8')
    passed=code==0 and not re.search(r'SCRIPT ERROR:|(?m:^ERROR:)|Parse Error|Assertion failed|TIMEOUT',log) and (marker is None or marker in log)
    item=dict(name=name,exit_code=code,passed=passed,command=cmd)
    results.append(item)
    print(name, 'PASS' if passed else 'FAIL', '\n'+log[-2200:],flush=True)
if phase=='glass':
    run('glass','test_glass_v11_4_1',False,marker='GLASS_V11_4_1 checks=')
elif phase=='glass2':
    run('glass2','test_glass_v11_4_2',marker='GLASS_V11_4_2 checks=')
elif phase=='bench2':
    run('bench2','bench_glass_v11_4_2',False,marker='GLASS_BENCH done=')
elif phase=='hud5':
    run('hud5','test_hud_v11_5',False,marker='HUD_V11_5 checks=')
elif phase=='integration':
    run('glass','test_glass_v11_4_1',False,marker='GLASS_V11_4_1 checks=')
    run('glass2','test_glass_v11_4_2',marker='GLASS_V11_4_2 checks=')
    run('explosions','test_gem_destruction_v11_4',False,marker='EXPLOSIONS_V11_4 checks=')
elif phase=='vfx':
    run('explosions','test_gem_destruction_v11_4',False,marker='EXPLOSIONS_V11_4 checks=')
elif phase=='next':
    run('hud_next','test_hud_next',False,marker='HUD_NEXT checks=')
elif phase=='focused':
    run('hud_next','test_hud_next',False,marker='HUD_NEXT checks=')
    run('hud_presenter','test_hud_presenter',marker='checks=3931 suites=7 failures=[]')
    run('hud_scene','test_hud_presenter_scene',False,marker='HUD_SCENE checks=1013 failures=[]')
elif phase=='regression':
    historical=[ROOT/'relatorios/fidelidade_v5'/s for s in ['comparacao.json','controles.json','partidas.json']]
    saved={p:p.read_bytes() if p.exists() else None for p in historical}
    try:
        scripts=['test_models','test_rules','test_fidelity','test_controls_fidelity','test_natural_fidelity','test_duel','test_presentation','test_coin_flip','test_character_select','test_visual_timeline_v10_3_2','test_pair_rotation_visual_v10_3_3','test_power_facet_v10_3_4','test_animation_v8','test_art_v9']
        for script in scripts: run(script,script)
        folder=OUT/'evidence/physics'; folder.mkdir(parents=True,exist_ok=True)
        run('physics','test_gem_timeline',extra=['--fixtures='+str(ROOT/'relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json'),'--out='+str(folder/'timeline.json')],marker='GEM_TIMELINE')
        folder=OUT/'evidence/chains'; folder.mkdir(parents=True,exist_ok=True)
        run('chains','test_chain_counter_timeline',extra=['--out='+str(folder/'timeline.json')])
        run('showcase_ui','test_showcase_ui',False,marker='SHOWCASE_UI_OK')
        run('character_select_ui','test_character_select_ui',False,marker='COIN_SELECT_UI_OK')
        run('match_flow_visual','test_match_flow_visual_v10_3_4',False,extra=['--visual'],marker='MATCH_FLOW_RESULT completed=4/4')
    finally:
        for p,content in saved.items():
            if content is not None: p.write_bytes(content)
            elif p.exists(): p.unlink()
        (OUT/'historical_restoration.json').write_text(json.dumps({str(p.relative_to(ROOT)):p.read_bytes()==content if content is not None else not p.exists() for p,content in saved.items()},indent=2),encoding='utf-8')
if phase=='checks':
    skill=Path(r'C:\Users\MauTrIX\.codex\skills\godot\scripts\debug')
    commands=[
        ('lint',['python','-B',str(skill/'lint_project.py'),str(ROOT/'godot'),'--pretty']),
        ('python',['python','-B','-m','unittest','discover','-s','tests','-v']),
        ('native',['python','-B',str(skill/'validate_project.py'),str(ROOT/'godot'),'--godot-bin',str(GODOT),'--pretty']),
        ('smoke',['python','-B',str(skill/'smoke_scenes.py'),str(ROOT/'godot'),'--godot-bin',str(GODOT),'--seconds','2','--jobs','4','--fuzz','--pretty'])]
    for name,cmd in commands:
        folder=OUT/'evidence'/name
        folder.mkdir(parents=True,exist_ok=True)
        (folder/'tmp').mkdir(exist_ok=True)
        env=os.environ.copy()
        env.update(APPDATA=str(folder/'userdata'),LOCALAPPDATA=str(folder/'userdata'),TMP=str(folder/'tmp'),TEMP=str(folder/'tmp'),PYTHONDONTWRITEBYTECODE='1')
        proc=subprocess.run(cmd,cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=150)
        log=proc.stdout.decode('utf-8',errors='replace')
        (folder/'console.log').write_text(log,encoding='utf-8')
        item=dict(name=name,exit_code=proc.returncode,passed=proc.returncode==0,command=cmd)
        try:
            data=json.loads(log)
            item['counts']=data.get('counts',{})
            item['ok']=data.get('ok')
            (folder/'result.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
            item['passed']=item['passed'] and data.get('ok',True)
        except ValueError: pass
        results.append(item)
        print(name,'PASS' if item['passed'] else 'FAIL',item.get('counts',{}),flush=True)
(OUT/(phase+'_summary.json')).write_text(json.dumps(results,indent=2),encoding='utf-8')
sys.exit(0 if all(r['passed'] for r in results) else 1)
