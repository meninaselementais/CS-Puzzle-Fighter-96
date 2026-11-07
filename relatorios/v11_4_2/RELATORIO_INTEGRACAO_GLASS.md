# V11.4.2 — Relatório de integração das explosões de vidro

**Status: VALIDADO NO WINDOWS; APROVADO ARTISTICAMENTE PELO USUÁRIO.** Em 07/11/2026 foram consultados os resumos e logs reais de `integration`, `bench2`, `focused` e `regression`: 26 execuções aprovadas, todas com exit code 0 e sem SCRIPT ERROR/ERROR nos logs consultados. Os testes não foram reexecutados neste checkpoint. O usuário confirmou a aprovação artística das explosões integradas durante uma partida. O vidro continua desligado por padrão; esta preparação não altera código nem configurações gráficas.

Data: 2026-11-06 · Branch `feature/v11-hud` · HEAD `1a943a4` · Nenhum commit, push ou tag foi criado. Nenhum `.cmd` foi executado.

## 1. Arquivos alterados
SHA-256 (16 primeiros caracteres). "Antes" = backup verificável em `relatorios/v11_4_2/backup_pre_v11_4_2/` (`SHA256SUMS_backup.txt`).

| Arquivo | Antes | Depois | Mudança |
|---|---|---|---|
| `godot/presentation/vfx/glass_shatter.gd` | `dcaf39b44833bd8d` | `819fc435eecbd099` | seleção completa, cache, qualidade, superfície em blocos |
| `godot/presentation/vfx/glass_surface.gdshader` | `843b8c41ed6e3cf8` | `14986d9b33cdba7c` | uniforms de recorte (padrões = comportamento V11.4.1) |
| `godot/presentation/gem_destruction_vfx.gd` | `3218cbb0e01d3571` | `015afd8fad726a3b` | força do efeito antigo, dica de Crash Gem |
| `godot/presentation/cs_arena.gd` | `5c2313dabebccce3` | `8e0a5da8bc8c1a1b` | `glass_enabled` + `set_glass_presentation()` |
| `godot/presentation/main.gd` | `fde25ac9e37dd4d8` | `f3ac716cc1b29b5e` | `PF_GLASS`, `PF_GLASS_QUALITY` e tecla `G` |

Arquivos novos (não existiam):
| Arquivo | SHA-256 (16) | Função |
|---|---|---|
| `godot/tests/test_glass_v11_4_2.gd` | `e6309740bfeb5476` | testes de contrato da integração |
| `godot/tests/bench_glass_v11_4_2.gd` | `d0733d48493d1635` | orçamento por tamanho e perfil |
| `relatorios/v11_4_2/run_validation.py` | `97a226c3acff4031` | cópia do runner V11.4.1 + fases `glass2`, `bench2`, `integration` |
| `relatorios/v11_4_2/CHECKPOINT_PRE_INTEGRACAO.md`, `PLANO_INTEGRACAO_GLASS.md`, `backup_pre_v11_4_2/` | — | documentação e backup |

**Não alterados** (conferido por hash após a edição, contra o checkpoint): `match_model.gd`, `board_model.gd`, `arcade_rng.gd`, `gem_motion.gd`, `gem_rules.gd`, `resolution.gd`, `attack_rules.gd`, `pair_model.gd`, `control_model.gd`, `match_session.gd` e `hud_presenter.gd`. O `run_validation.py` e as evidências da V11.4.1 também não foram tocados. Não foram criados assets novos (sem reimportação no Godot).

## 2. Pontos de integração
1. **Ativação** (`cs_arena.gd`): `set_glass_presentation(enabled, profile)` carrega `glass_shatter.gd` com `load()` tardio, chama `configure_integrated(profile)` e atribui `destruction.prototype`. Desligar faz `clear()` e volta `prototype = null` (V11.4 intacta).
2. **Seleção** (`glass_shatter.gd`): `full_scope=false` (padrão) é exatamente a seleção aprovada da V11.4.1 (`selected_prototype`). Com `full_scope=true`, `selected_full`:
   - gemas comuns das 4 cores (linhas visíveis, `y >= 2`);
   - Crash Gems (`code & 8`);
   - Power Gems completas de qualquer largura×altura (região de `powers_before` com todas as células removidas);
   - **ficam com a V11.4**: o diamante da C4 (`code & 7 == 5`) e as Counter gems.
3. **Sem duplicação**: já existente e reaproveitado. `handles()` retira a célula de `emit_wave`, de `observe_pre` e do `spawn_board_explosion` da arena (`cs_arena.gd` ~l.892).
4. **C4**: o diamante mantém LED, anel `c4`, 16 raios e flash (caminho V11.4). As gemas destruídas pela C4 recebem vidro. Para o diamante manter o mesmo visual, a "força" do efeito antigo passa a contar todas as gemas da onda (só em `full_scope`; com o vidro desligado o cálculo é idêntico ao anterior).
5. **Crash Gems**: viram vidro, mas o anel/estrela de antecipação (pulsante) é mantido por `anticipation.cues`.
6. **Power Gems de outros tamanhos** (largura×altura; 2×3 = 2 de largura, 3 de altura): a máscara `plate_fracture.png` (5×2 células) é recortada em blocos de até 5×2, **sem esticar** (1 texel = 1 pixel). O shader remapeia o recorte (`uv_rect`), o gradiente (`g_range`) e a poeira em coordenadas da formação inteira (`block_frame`, `formation_px`). 5×2 e 1×1 usam os valores padrão (idênticos à V11.4.1).
7. **Cotas e perfis**: tetos por jogador inalterados (48/4096/3072, P1 e P2 independentes). Perfis `high`=1.0, `medium`=0.5, `low`=0.25 multiplicam as contagens por célula. Sem milhares de nós: por evento, 3 `MultiMeshInstance2D` + 1 a 8 sprites de superfície.
8. **Desempenho da seleção**: `handles()` usa cache por identidade da onda (`is_same`), evitando custo O(n²) por detonação.

## 3. Como ativar e desativar (desligado por padrão)
- Iniciar o jogo com a variável de ambiente `PF_GLASS=1` (opcional: `PF_GLASS_QUALITY=high|medium|low`).
  PowerShell: `$env:PF_GLASS="1"; $env:PF_GLASS_QUALITY="high"` e abrir o jogo a partir do mesmo terminal.
- Durante a partida, a tecla **G** alterna (imprime `GLASS_PRESENTATION true/false` no console).
- Por código: `arena.set_glass_presentation(true, "high")` / `(false)`.
- Sem `PF_GLASS`, nada muda: o comportamento é o da V11.4.
- Recuperação total: restaurar os 5 arquivos a partir de `backup_pre_v11_4_2/*.bak.txt` (conferir com `SHA256SUMS_backup.txt`).

## 4. Verificações feitas nesta sessão (estáticas — NÃO são testes do jogo)
- Análise sintática (`gdparse`, gdtoolkit) de `glass_shatter.gd`, `gem_destruction_vfx.gd`, `cs_arena.gd`, `main.gd`, `test_glass_v11_4_2.gd` e `bench_glass_v11_4_2.gd`: sem erros de sintaxe. `py_compile` do runner: ok.
- Conferência de hash dos arquivos gravados e dos arquivos protegidos.
- Revisão manual da lógica. O parser **não** valida tipos, chamadas à API do Godot nem o shader.

## 5. Testes executados no Windows — resultados reais consultados em 07/11/2026

Fontes: `integration_summary.json` (3/3), `bench2_summary.json` (1/1), `focused_summary.json` (3/3), `regression_summary.json` (19/19) e respectivos `evidence/<nome>/console.log`/`godot.log`. Estas são execuções já realizadas no Windows, não novas execuções desta sessão de checkpoint.

| Etapa | Execução | Resultado | Evidência no log |
|---|---|---|---|
| integration | glass | APROVADO | `GLASS_V11_4_1 checks=2152 failures=[]` |
| integration | glass2 | APROVADO | `GLASS_V11_4_2 checks=98 failures=[]` |
| integration | explosions | APROVADO | `EXPLOSIONS_V11_4 checks=14018 failures=[]` |
| bench2 | bench2 | APROVADO | `GLASS_BENCH done=21` |
| focused | hud_next | APROVADO | `HUD_NEXT checks=1072 failures=[]` |
| focused | hud_presenter | APROVADO | `HUD_PRESENTER checks=3931 suites=7 failures=[]` |
| focused | hud_scene | APROVADO | `HUD_SCENE checks=1013 failures=[]` |
| regression | test_models | APROVADO | `GODOT_TESTS_OK` |
| regression | test_rules | APROVADO | `RULE_TESTS 34 checks; failures=[]` |
| regression | test_fidelity | APROVADO | `FIDELITY_RESULT 247/247 matches` |
| regression | test_controls_fidelity | APROVADO | `CONTROL_FIDELITY 33/33; RNG 866; invalid_sources 10` |
| regression | test_natural_fidelity | APROVADO | `NATURAL_FIDELITY 119/119` |
| regression | test_duel | APROVADO | `DUEL_OK: 1500 turnos, 28 partidas, 227 ondas, 797 ataques brutos` |
| regression | test_presentation | APROVADO | `PRESENTATION_TESTS 3285 checks; failures=[]` |
| regression | test_coin_flip | APROVADO | `COIN_FLIP_TESTS 40195 checks; P1 CT=10044/20000; failures=[]` |
| regression | test_character_select | APROVADO | `CHARACTER_SELECT_TESTS 3351 checks; failures=[]` |
| regression | test_visual_timeline_v10_3_2 | APROVADO | `VISUAL_TIMELINE_V10_3_2 123863 checks; failures=[]` |
| regression | test_pair_rotation_visual_v10_3_3 | APROVADO | `ROTATION_V10_3_3 checks=119052 primary=80 active=11957 failures=[]` |
| regression | test_power_facet_v10_3_4 | APROVADO | `POWER_FACET_V10_3_4 394 checks; failures=[]` |
| regression | test_animation_v8 | APROVADO | `ANIMATION_V8_TESTS 145 checks; failures=[]` |
| regression | test_art_v9 | APROVADO | `ART_V9_TESTS 102 checks; failures=[]` |
| regression | physics | APROVADO | `GEM_TIMELINE cases=112/112 samples=14072/14072 failures={  }` |
| regression | chains | APROVADO | `CHAIN_COUNTER_TIMELINE cases=22/22 samples=5066/5066 checks=54 categories={"counter_delivery":1,"counter_fall":2,"intermediate_gravity":2,"multi_wave_chains":6,"simple_destruction":5,"simultaneous_attacks":6} failures=[] check_failures=[]` |
| regression | showcase_ui | APROVADO | `SHOWCASE_UI_OK: selectors, pause, frame step, C4 render, F4 round trip` |
| regression | character_select_ui | APROVADO | `COIN_SELECT_UI_OK: real viewport keyboard/gamepad events, coin/audio, skip/auto, locked sides, three rounds, fresh match, invalid-entry guard, two window sizes; 12 captures` |
| regression | match_flow_visual | APROVADO | `MATCH_FLOW_RESULT completed=4/4 rounds=10 checks=276 failures=[]` |

A integração passa 98 verificações de contrato; o protótipo passa 2.152 e os efeitos V11.4 passam 14.018. HUD/NEXT: 1.072 + 3.931 + 1.013 verificações. A regressão inclui RNG (866), 1.500 turnos/28 partidas/797 ataques brutos, física 112 casos e cadeias 22 casos. Isso não substitui um teste de todas as cadeias com `full_scope` ligado: os contratos integrados e as regressões existentes possuem escopos distintos.

**Aprovação artística:** o usuário declarou aprovadas as explosões integradas durante uma partida. Essa aprovação é registrada como observação do usuário; não foi realizada nova inspeção de partida ou produzida nova captura neste checkpoint.

## 6. Procedimento no Windows
Na raiz `C:\Projetos\CS-Puzzle-Fighter-96`:
```
python relatorios\v11_4_2\run_validation.py integration   # glass (V11.4.1) + glass2 (V11.4.2) + explosões V11.4
python relatorios\v11_4_2\run_validation.py bench2        # orçamento por tamanho e perfil
python relatorios\v11_4_2\run_validation.py focused       # HUD/NEXT
python relatorios\v11_4_2\run_validation.py regression    # V10 e anteriores
```
Evidências vão para `relatorios\v11_4_2\evidence\` (as da V11.4.1 aprovadas não são sobrescritas). Godot: `ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe`.
Procedimento opcional de reprodução visual (a aprovação do usuário já foi recebida): jogar uma partida com `PF_GLASS=1`, comparar com a mesma partida sem a variável, e capturar frames/sequência (usar o padrão de `player_comparativo.html` da V11.4.1).
Se `glass2` falhar em `test_surface_blocks` ou nos shaders, ver riscos 1–3.

## 7. Riscos conhecidos
1. As quatro etapas foram executadas e aprovadas conforme a seção 5; não há erro de execução registrado nesses logs. Outras GPUs, Web e dispositivos móveis não estão certificados por essas execuções Windows.
2. **Shader alterado** (`glass_surface.gdshader`): os padrões deveriam reproduzir a V11.4.1 exatamente, com o protótipo gráfico aprovado na etapa integration; isso não constitui comparação pixel a pixel de todas as formações. Se a aparência da 5×2/1×1 mudar, restaurar o shader do backup.
3. **Costuras entre blocos**: Power Gems maiores que 5×2 (ou com altura ≥ 3) usam vários recortes da mesma máscara; as rachaduras podem ficar descontínuas na junção. O usuário aprovou a integração durante uma partida; não há registro separado de aprovação de cada tamanho.
4. **Cota esgotável**: uma Power Gem muito grande (ex.: 6×4 = 7200 micro pedidos) consome o teto do jogador (4096) e eventos seguintes na janela de 56 ticks recebem pouco ou nada. Os perfis não mudam os tetos. Pode exigir cota mínima por evento.
5. **Primeiro uso de tamanhos fora de `WARM_SIZES`** (ex.: 3×4, 4×3) constrói o layout na hora (hitch de poucos ms, estimado pelo histórico, não medido). Pré-aquecimento ao ligar custa tempo extra (não medido).
6. **Crash Gem**: o pulso de antecipação mantido é só anel+estrela (o brilho losango do caminho antigo não aparece). **Counter gems** e o diamante da C4 continuam no efeito V11.4 (decisão de escopo, não pedida explicitamente).
7. **Cache por identidade**: assume que `wave.removed` e `wave.powers_before` não são alterados in loco após a criação da onda (verdade no código lido).
8. **Força do efeito antigo na C4** muda só com vidro ligado; se o visual da C4 divergir, ajustar em `emit_wave`.
9. Arquivos `.uid` dos scripts novos serão criados pelo Godot e aparecerão como não rastreados.
10. Checkpoint local V11.4.2 autorizado pelo usuário em 07/11/2026; base anterior `1a943a4`. Sem push ou criação de tag.

## 8. Pendências
- Etapas Windows da seção 6 aprovadas; resultados documentados na seção 5. Web/móvel continuam sem validação nesta entrega.
- Escrever e executar testes de combos (3 e 5 ondas), simultaneidade P1/P2 e integridade de modelo/RNG/NEXT com `full_scope`.
- Capturas e sequência animada específicas da integração continuam opcionais de documentação; aprovação artística em partida recebida do usuário, sem inferir aprovação individual de todos os tamanhos.
- Decidir sobre cota mínima por evento e sobre Counter gems.
- Vidro permanece desligado por padrão por configuração existente; a aprovação artística recebida não foi usada para mudar essa configuração. V11.5 não foi iniciada.

## 9. Benchmark consultado e checkpoint

`bench2`: 21 cenários/perfis; adaptador NVIDIA GeForce RTX 5070, renderer `gl_compatibility`. GPU mediana registrada entre 0.035 e 0.046 ms; máximo registrado 0.970 ms. CPU update mediana até 45 µs; primeira construção até 7521 µs. Medições do ensaio, sem promessa de FPS em outros dispositivos.

Fontes anteriores e tabelas de hashes das seções 1 e 4 permanecem históricas. Preparação atual: branch `feature/v11-hud`, HEAD-base `1a943a4db4d1dba84a222735187afb6108b4c4c5`; tag anotada `v0.10.0` resolve para esse commit. Nenhuma mudança no núcleo. Três fontes anteriores são insumos indispensáveis dos testes de comparação e entram como fixtures; diretórios de backup e evidências ficam fora do commit.
