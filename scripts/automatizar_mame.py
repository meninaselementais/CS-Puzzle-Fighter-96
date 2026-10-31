"""Executa o spf2tu numa cópia isolada do MAME, sem alterar as fontes."""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path


def sha256(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def copy_verified(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    expected = sha256(source)
    if not target.exists():
        with Path(source).open('rb') as src, target.open('xb') as dst:
            shutil.copyfileobj(src, dst)
    if sha256(target) != expected:
        raise ValueError(f'Cópia divergente, não sobrescrita: {target}')
    return {'origem': str(source), 'copia': str(target), 'sha256': expected}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--mame', type=Path, default=Path('C:/MAME'))
    parser.add_argument('--lua', type=Path, required=True)
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--state', type=Path, help='Estado de laboratório existente, copiado para a nova sessão')
    parser.add_argument('--video', choices=['gdi','none'], default='none',
                        help='none: sem janela; gdi: janela nativa do Windows')
    parser.add_argument('--timeout', type=int, default=120)
    args = parser.parse_args()
    try:
        root = args.project.resolve()
        original = args.mame.resolve(strict=True)
        if root == original or root.is_relative_to(original) or original.is_relative_to(root):
            raise ValueError('Projeto e originais do MAME devem estar em diretórios separados')
        lua = args.lua.resolve(strict=True)
        runtime = root/'laboratorio/runtime_0289'
        copies = [copy_verified(args.mame/name, runtime/name)
                  for name in ['mame.exe', 'roms/spf2t.zip', 'roms/spf2tu.zip',
                               'roms/qsound_hle.zip', 'roms/qsound.zip']]
        session = root/'laboratorio'/datetime.now().strftime('auto_%Y%m%d_%H%M%S_%f')
        session.mkdir(parents=True, exist_ok=False)
        for name in ['cfg','nvram','sta','snap','inp','comments','diff','ini','captures']:
            (session/name).mkdir()
        eeprom = args.mame/'nvram/spf2tu/eeprom'
        if eeprom.exists():
            copies.append(copy_verified(eeprom, session/'nvram/spf2tu/eeprom'))
        state_entry = ''
        if args.state:
            copies.append(copy_verified(args.state.resolve(strict=True), session/'sta/spf2tu/input.sta'))
            state_entry = ', PF_STATE="input"'
        for path in (session, lua):
            if ']=]' in path.as_posix():
                raise ValueError('Caminho incompatível com literal Lua')
        lua_snapshot = session/'experimento.lua'
        copy_verified(lua, lua_snapshot)
        copy_verified(Path(__file__).resolve(), session/'automatizar_mame.py')
        version = subprocess.run([str(runtime/'mame.exe'),'-help'],cwd=session,
                                 capture_output=True,text=True,check=True).stdout.splitlines()[0]
        if not version.startswith('MAME v0.289 '):
            raise ValueError(f'Versão não validada pelo mapa: {version}')
        wrapper = session/'run.lua'
        wrapper.write_text(f'local env = setmetatable({{PF_SESSION = [=[{session.as_posix()}]=]{state_entry}}}, {{__index=_G}})\n'
                           f'assert(loadfile([=[{lua_snapshot.as_posix()}]=], "t", env))()\n', encoding='utf-8')
        command = [str(runtime/'mame.exe'), 'spf2tu', '-noreadconfig', '-skip_gameinfo',
                   '-noplugins', '-noautosave', '-window', '-video', args.video, '-sound', 'none',
                   '-nothrottle', '-frameskip', '0', '-rompath', str(runtime/'roms'),
                   '-inipath', str(session/'ini'), '-homepath', str(session),
                   '-autoboot_delay', '0', '-autoboot_script', str(wrapper), '-seconds_to_run', '0']
        for key, folder in [('cfg_directory','cfg'),('nvram_directory','nvram'),('state_directory','sta'),
                            ('snapshot_directory','snap'),('input_directory','inp'),
                            ('comment_directory','comments'),('diff_directory','diff')]:
            command += ['-'+key, str(session/folder)]
        if args.debug:
            debugscript=session/'inicio.cmd'
            debugscript.write_text('g\n', encoding='ascii')
            command += ['-debug', '-debugger', 'none', '-debugscript', str(debugscript)]
        manifest = {'versao':version,'comando': command, 'copias': copies, 'lua': str(lua),
                    'lua_sha256': sha256(lua),'runner_sha256':sha256(Path(__file__).resolve())}
        (session/'execucao.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        print(str(session), flush=True)
        start=time.monotonic()
        with (session/'mame.log').open('wb') as log:
            process=subprocess.Popen(command, cwd=session, stdout=log, stderr=subprocess.STDOUT,
                                     creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            try:
                code=process.wait(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=10)
                raise RuntimeError(f'MAME excedeu {args.timeout}s; processo desta sessão encerrado. Log: {session}')
        manifest.update(exit_code=code, segundos_reais=time.monotonic()-start)
        manifest['fontes_preservadas']=all(sha256(item['origem'])==item['sha256'] for item in copies)
        (session/'execucao.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        script_completed = (session/'concluido.txt').is_file()
        manifest['lua_concluiu'] = script_completed
        manifest['lua_sem_erros'] = '[LUA ERROR]' not in (session/'mame.log').read_text(encoding='utf-8',errors='replace')
        (session/'execucao.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        if code != 0 or not manifest['fontes_preservadas'] or not script_completed or not manifest['lua_sem_erros']:
            raise RuntimeError(f'Falha de execução/integridade. Consulte {session}/mame.log')
        print(f'Concluído em {manifest["segundos_reais"]:.2f}s', flush=True)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, f'Erro: {error}\n')


if __name__=='__main__':
    main()
