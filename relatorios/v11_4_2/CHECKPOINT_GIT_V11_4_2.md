# Checkpoint Git seguro — V11.2 a V11.4.2

Gerado por leitura apenas (sem git CLI). Nenhum commit, push, tag, reset ou clean foi executado. Nenhum arquivo do projeto foi alterado, exceto este relatório.

## 1. Estado do repositório
- Branch: `feature/v11-hud`
- HEAD: `1a943a4db4d1dba84a222735187afb6108b4c4c5` (igual a `main`)
- Todo o trabalho V11.2–V11.4.2 está fora de commit.
- Método: leitura de `.git/HEAD` e `.git/index` (451 entradas) comparada com a árvore de trabalho. **Confirme com `git status`**, pois isto não substitui o git.
- Árvore (excluindo diretórios ignorados): 507 arquivos, 285 rastreados, 222 não rastreados. Nenhum rastreado está ausente.

## 2. Arquivos necessários para reproduzir a V11

**Código, shaders e testes (devem entrar no commit)**
- `godot/presentation/`: `gem_destruction_vfx.gd`, `hud_presenter.gd`, `vfx/glass_shatter.gd`, `vfx/glass_fragment.gdshader`, `vfx/glass_surface.gdshader`.
- Modificados e rastreados: `cs_arena.gd`, `main.gd` (e demais arquivos V11 listados por `git status`).
- `godot/tests/`: `test_glass_v11_4_2.gd`, `bench_glass_v11_4_2.gd`, `test_glass_v11_4_1.gd`, `bench_glass_v11_4_1.gd`, `test_gem_destruction_v11_4.gd`, `test_hud_next.gd`, `test_hud_presenter.gd`, `test_hud_presenter_scene.gd`.

**Assets (devem entrar no commit)**
- `godot/assets/vfx/glass/`: `gem_fracture.png`, `grain.png`, `plate_fracture.png`, `shards.png` e seus `.import`.
- `godot/assets/sprites/*.import` (128) e `godot/assets/audio/coin_*.wav.import` (2). Os PNG/WAV correspondentes já são rastreados.
- `.import` e `.uid` são necessários para que os UIDs do Godot permaneçam estáveis. Os 12 `.uid` já rastreados confirmam que o projeto os versiona.

**`.uid` (53 não rastreados)**: 6 em `core`, 12 em `presentation`, 32 em `tests`, 3 em `tools`. Recomendo versionar, por consistência com os 12 já rastreados. Não há `.uid` órfão.

**Documentação**
- `planejamento/V11_PLANO_HUD.md` e `planejamento/v11_1/` (14 arquivos, incluindo `GALERIA.html` de cerca de 3,8 MB, PNG e SVG).
- `relatorios/v11_4_2/*.md` e os `*_summary.json` aprovados, que as regras do `.gitignore` já permitem.

## 3. Temporários, caches e gerados (não commitar)
- `.godot/` (ignorado), `__pycache__`, `*.tmp`, `*.log`: já ignorados.
- `relatorios/v11_4_2/evidence/` (26 subpastas), `backup_pre_v11_4_2/` e os `run_validation.py`: ignorados pela regra `/relatorios/**`. Preservados no disco, fora do commit.
- `planejamento/v11_1/referencia_atual/captura.log` e `execucao.json`: são saídas de captura. Pequenos (189 e 407 bytes), mas gerados. O `*.log` é ignorado, então fica fora do commit sem ação.
- `arte/v9/rejeitados/phoenix_win_three_hands.png`: pasta `rejeitados` já coberta pela regra `/arte/**/rejeitados/`. Se `git status` ainda o listar, não use `git add` nele.
- `planejamento/v11_1/GALERIA.html` (3,8 MB, base64 embutido): decisão sua entre commitar ou ignorar.

## 4. Arquivos não rastreados: preservação
Nenhum será removido. Não use `git clean` nem `git reset --hard`. Todos os 222 continuam intactos no disco.

## 5. Caminhos de recurso do Godot
- Todo literal `res://` nos `.gd`, `.gdshader` e `project.godot` verificados resolve para um arquivo existente.
- Nenhum `.import` órfão e nenhum `.gd.uid` órfão.
- Limite: foram verificados literais estáticos. Caminhos montados em tempo de execução não são cobertos. A abertura real no Godot já foi validada por você (integration, bench2, focused, regression aprovados nos resumos em disco).

## 6. Segredos e arquivos pessoais
- `.ai/cezar/launch-key` (37 bytes, formato UUID): chave local da ferramenta Cezar. **Já está ignorada** pelo `.ai/cezar/.gitignore`, junto com `runs/`, `config.json.*.tmp` e outros. Meu levantamento anterior a listou como não rastreada por não aplicar o `.gitignore` aninhado. O valor não foi exibido.
- `.ai/cezar/.gitignore` pode ser commitado, mas é opcional.
- Varredura de 46 arquivos de texto (código, testes, planejamento, JSON, MD): nenhum token, chave de API, senha ou e-mail.
- Achado: `relatorios/v11_4_1/run_validation.py` e `relatorios/v11_4_2/run_validation.py` contêm o caminho local `C:\Users\MauTrIX\.codex\...`. Ambos estão ignorados, então não vão para o commit. Se um dia forem versionados, remova esse caminho.
- Limite: não varri os 128 sprites nem os PNG por metadados. Também não varri todos os arquivos de `relatorios/`.

## 7. Proposta de commit (para você executar)
O item 7 da sua mensagem chegou truncado ("Prepare uma…"). Assumi que era uma proposta de commit. Corrija se era outra coisa.

Conferir antes:
```
git status --short
git check-ignore -v .ai/cezar/launch-key relatorios/v11_4_2/evidence
```

Sugestão em três commits:
```
git add godot/presentation godot/core godot/tools godot/tests
git add godot/assets/vfx godot/assets/sprites godot/assets/audio
git add godot/project.godot
git status --short   # revisar o que está staged
git commit -m "feat(v11): HUD, NEXT e explosões de vidro (V11.2-V11.4.2, desligado por padrão)"

git add planejamento
git commit -m "docs(v11): planejamento do HUD e comparação de layouts"

git add relatorios
git commit -m "docs(v11.4.2): relatórios e resumos de validação"
```
Não inclua `git add -A` nem `git add -f`. Se o Godot tiver regenerado `.import` de assets não alterados, o `git status` mostrará. Revise antes de commitar.

Se preferir um commit único, use só o primeiro bloco mais os dois `git add` de documentação.

Mensagens de commit feitas por mim devem terminar com:
```
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HDVWyzhnVkkNAxqmxFB1B6
```
Isso só vale se eu fizer o commit. Tags e push não estão incluídos, por regra sua.

## 8. Pendências
- Relatório `RELATORIO_INTEGRACAO_GLASS.md` ainda mostra os testes como PENDENTES. Está desatualizado em relação aos resultados reais.
- Aprovação visual: consta da sua mensagem. Não revisei as capturas da integração real.
- Glass segue DESLIGADO por padrão (`glass_enabled` = false; ativação via `PF_GLASS=1`, tecla `G` ou `set_glass_presentation`).
