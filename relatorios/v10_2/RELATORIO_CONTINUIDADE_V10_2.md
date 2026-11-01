# Relatório de Continuidade V10.2 — Física Temporal de Gemas e Integração CPS-2

**Projeto:** `C:\Projetos\CS-Puzzle-Fighter-96`
**Branch:** `feature/v10-gem-physics`
**Base preservada:** `v0.9.0` (`03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`)
**Status Git:** Sem commit e sem push; alterações do Codex integralmente preservadas e complementadas com correções pontuais de integração.

---

## Etapa 1 — Estado Encontrado e Preservação do Trabalho

1. **Branch e Árvore Git:**
   - Branch ativa confirmada: `feature/v10-gem-physics`.
   - `main` e tag `v0.9.0` intocadas em `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`.
   - Nenhum comando destrutivo (`reset`, `clean`, `checkout`) foi executado.
2. **Arquivos criados/modificados pelo Codex encontrados na árvore:**
   - Novos:
     - `godot/core/gem_motion.gd` (máquina temporal por jogador: queda, contato de 16 quadros, perda de apoio, limite de 8 contatos, limite de 3 upkicks, depósito e fases de resolução `1..19`).
     - `godot/tests/test_gem_timeline.gd` (comparador quadro a quadro contra as 112 fixtures MAME / 14.072 amostras).
     - `relatorios/v10_gem_physics/` (diagnóstico V10, relatório de medições MAME 0.289, `mame_contact_fixtures.json`, `verify_contact_fixtures.py` e runs).
     - `relatorios/v10_2/` (evidências iniciais da V10.2).
   - Modificados pelo Codex:
     - `godot/core/match_model.gd`
     - `godot/core/resolution.gd`
     - `godot/presentation/cs_arena.gd`
     - `godot/presentation/main.gd`
     - `godot/tests/test_character_select_ui.gd`
     - `godot/tests/test_duel.gd`
     - `godot/tests/test_match_flow.gd`
     - `godot/tests/test_models.gd`
     - `godot/tests/test_rules.gd`

---

## Etapa 2 — Validação da Comparação Física (112 Cenários / 14.072 Amostras)

- Reexecutado `test_gem_timeline.gd` contra `relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json` e `verify_contact_fixtures.py`:
  - **Cenários aprovados:** `112 / 112` (`cases_passed: 112`)
  - **Amostras correspondentes:** `14.072 / 14.072` (`field_failures: {}`)
  - **Hashes iniciais de RAM verificados:** `112 / 112` dumps de 64 KiB (`_initial.bin`).
  - **Campos confrontados por amostra:** `x`, `y`, `offset`, `rotation` (orientação), `contact`, `phase`, `turn`, `pivot` e `satellite` (cores), `pair_age` (idade), `contact_count`, `score` (placar), `grid` (tabuleiro lógico canonizado) e `upkick_count` / `rotation_disabled` onde capturados.
  - **Ressalva explícita:** `strict_native_state_complete = false` — a coincidência desses campos comprova a trajetória física/temporal medida nesses 112 cenários, mas **não** equivale à igualdade integral dos 64 KiB de RAM nativa nem de todos os consumidores globais de RNG do CPS-2.

---

## Etapa 3 — Validação da Integração e Bugs Identificados/Corrigidos

Foram auditados e validados os 10 pontos da janela de contato e resolução:

1. **Contador de contato de 16 quadros:** Inicializado em `16` ao tocar apoio (`enter_contact()`), decrementando de `16` até `1` e depositando no quadro seguinte (`contact == 0`), com exceção fiel ao arcade no 8º episódio de contato (`contacts == 8 -> contact = 1`).
2. **Rotação permitida nos contadores 15 até 2:** Confirmada nas duas direções (`CW` bit `512`, `CCW` bit `256`) e quick-turn em corredor (`768`).
3. **Rotação ignorada nos contadores 16 e 1:** Bloqueada em `gem_motion.gd` (`contact in [1, 16]`) tanto no primeiro quadro de contato (`16`) quanto no último (`1`).
4. **Movimentação lateral permitida de 16 até 2:** Permitida em `contact == 16..2` (incluindo o quadro `16` de entrada em contato) e bloqueada em `contact == 1`, respeitando a supressão de movimento lateral no mesmo ciclo em que ocorre wall/floor kick (`kicked` / `$397(A6)`).
5. **Perda de apoio e reinicialização do contato:** Quando `supported()` deixa de ser verdadeiro durante `contact > 0`, `contact` zera imediatamente, `horizontal_timer` zera, a dupla desce uma linha com `offset = fall_offset` e `fall_countdown = 10`, e ao encontrar novo suporte reinicia `contact = 16` incrementando `contacts`.
6. **Depósito das duas gemas:** Executado ao expirar a janela (`contact` `1 -> 0`) enquanto apoiada, gravando pivô e satélite em `board.cells` e avançando para `phase = 1`.
7. **Queda independente no quadro seguinte:** Em `phase == 1`, `Rules.gravity_step(board)` move gemas sem suporte 1 linha por quadro até assentar, com 1 quadro de confirmação ao estabilizar.
8. **Formação de Power Gems após gravidade:** Executada em `phase == 4` (`Rules.form_powers(board)`), somente após a conclusão da queda independente em `phase == 1` e do avanço de contadores/gravidade em `phase == 2..3`.
9. **Entrada simultânea dos dois jogadores:** P1 e P2 processam máscaras independentes no mesmo `model.tick()`.
10. **Transição para a próxima dupla:** Em `phase == 19`, incrementa `pair_index[player]` e chama `spawn(player)` retornando a `phase = 0`.

### Bugs de integração identificados e corrigidos (Gemini)

1. **Borda falsa na transição para a próxima dupla (`gem_motion.gd` e `match_model.gd`):**
   - **Causa:** Em `phase == 19`, `resolve_frame()` chamava `model.spawn(player)`, que instanciava um novo `Motion.new()` com `previous_input = 0` e `horizontal_timer = 0`, enquanto `step()` gravava `previous_input = mask` na instância antiga descartada. Se o jogador mantivesse um botão de rotação ou direção pressionado durante a transição `phase 19 -> 0`, o primeiro quadro da nova dupla via `previous_input == 0` e disparava uma rotação/movimento fantasma sem nova pressão de botão.
   - **Correção:** `step()` atualiza `previous_input = mask` antes de `resolve_frame()`, e `spawn(player)` preserva `previous_input` e `horizontal_timer` da instância anterior (tal como `$142(A6)` e `$188/$34e(A6)` na RAM nativa).
2. **Perda de ondas visuais/explosões na arena durante resolução temporal (`gem_motion.gd` e `cs_arena.gd`):**
   - **Causa:** `cs_arena.gd` reconstruía as ondas visuais somente quando `score_delta >= 200` usando `prev_cells[i]`. Com a resolução temporal (`gem_motion.gd`), `Rules.resolve(board, false)` limpa o tabuleiro em `phase == 8`, mas a pontuação só é somada em `phase == 11` após `40 * waves.size()` quadros, quando `prev_cells[i]` já havia sido sobrescrito pelo tabuleiro limpo.
   - **Correção:** `gem_motion.gd` preserva `pre_resolve_cells = board.cells.duplicate()` imediatamente antes de `Rules.resolve(board, false)` em `phase == 8`, e `cs_arena.gd` enfileira `enqueue_visual_waves(i, model.motion[i].pre_resolve_cells, board_origins[i], false)` ao entrar em `phase == 9`.
3. **Captura de toques rápidos entre ticks do acumulador arcade (`main.gd`):**
   - **Causa:** Como o relógio CPS-2 roda a `59,637 Hz` via `arcade_accumulator` dentro de `_physics_process`, um evento rápido de tecla/botão pressionado e solto antes do próximo tick do acumulador (ou com `keycode` sem `physical_keycode`) podia ser limpo de `keyboard_masks`/`joy_masks` antes de `model.tick()` lê-lo.
   - **Correção:** Adicionado `latched_masks` em `main.gd` para reter bordas de subida até o consumo efetivo por `model.tick()`, além de fallback `event.physical_keycode if event.physical_keycode != 0 else event.keycode`.

---

## Etapa 4 — Resultados das Baterias de Regressão

Todas as baterias foram executadas e aprovadas sem erros (`relatorios/v10_2/gemini_validation/`):

| Bateria | Resultado | Detalhes |
|---|---|---|
| Comparação física temporal (`test_gem_timeline`) | **PASS (112/112)** | 14.072/14.072 amostras idênticas às fixtures MAME |
| Verificador Python (`verify_contact_fixtures.py`) | **PASS (112/112)** | 14.072 linhas verificadas |
| Testes unitários Python (`unittest`) | **PASS (17/17)** | Exportadores, traços de RNG, geometria Power e repetição |
| Modelos e geometria (`test_models`) | **PASS** | Limites, colisão, assentamento temporal, 2 tabuleiros |
| Regras (`test_rules`) | **PASS (34/34)** | 34/34 verificações de regras e economia |
| Fidelidade controlada MAME (`test_fidelity`) | **PASS (247/247)** | 247/247 comparações com o arcade |
| Fidelidade de controles/RNG (`test_controls_fidelity`) | **PASS (33/33)** | 33/33 controles, 866/866 amostras RNG |
| Partidas naturais MAME (`test_natural_fidelity`) | **PASS (119/119)** | 119/119 endpoints naturais |
| Duelo completo (`test_duel`) | **PASS** | 1.500 turnos, 26 partidas, 239 ondas, 908 ataques |
| Apresentação (`test_presentation`) | **PASS (3.285/3.285)** | 3.285 verificações de ondas visuais e sincronismo |
| Animações V8 (`test_animation_v8`) | **PASS (145/145)** | 145 verificações de combate, projéteis e showcase |
| Arte V9 (`test_art_v9`) | **PASS (102/102)** | 102 verificações de sprites e proporções |
| Seleção de personagens (`test_character_select`) | **PASS (3.351/3.351)** | 3.351 verificações de bloqueio de lados e padrões |
| Coin Flip (`test_coin_flip`) | **PASS (40.195/40.195)** | 40.195 verificações de sorteio e sessão |
| UI Seleção + Coin Flip + Rounds (`test_character_select_ui`) | **PASS (12 capturas)** | Janela real, teclado/gamepad, 2 resoluções |
| Integração de Rounds Headless (`validar_fluxo_partidas.py`) | **PASS (4/4 partidas)** | 10 rounds, 204 verificações |
| Integração de Rounds Visual + Vídeo (`--visual --movie`) | **PASS (4/4 partidas)** | 10 rounds, 276 verificações, vídeo AVI e 19 PNGs |
| Validação Visual de Física V10.2 (`visual_physics`) | **PASS (46/46 checks)** | 10 PNGs e vídeo `fisica_gemas_v10_2.avi` (168 quadros) |

---

## Etapa 5 — Evidências Visuais Geradas

- **Física de Gemas em Janela Real (`relatorios/v10_2/gemini_validation/visual_physics/`):**
  - Vídeo: `fisica_gemas_v10_2.avi` (1000×700 @ 60 FPS, 168 quadros).
  - Capturas PNG:
    - `01_contact_16_rot_ignored_move_ok.png`
    - `02_contact_15_rotation_and_lateral_move.png`
    - `02b_contact_02_rot_accepted.png`
    - `03_contact_01_last_frame_rot_ignored.png`
    - `04_lost_support_contact_reset.png`
    - `05_deposited_before_independent_fall.png`
    - `06_independent_fall_step.png`
    - `07_power_gem_formed_after_gravity.png`
    - `08_next_pair_spawned_cleanly.png`
    - `09_live_combo_explosion_and_attack.png`
- **Fluxo Visual de Coin Flip, Seleção e Rounds (`relatorios/v10_2/gemini_validation/rounds_visual/`):**
  - Vídeo: `fluxo_rounds_v10_2.avi` (1000×700 @ 30 FPS).
  - 19 capturas PNG cobrindo sorteio CT/TR, seleção de agentes, rounds 2-0 / 0-2 / 2-1 / 1-2 e novo sorteio.

---

## Etapa 6 — Cronologia de Cadeias (Estados 8..11) e Queda de Counter Gems (Estados 17..19)

### 1. Diferenças Encontradas entre a Implementação Inicial e o MAME 0.289 (`spf2tu`)

#### A. Estados `8..11` (Combos e Cadeias em `gem_motion.gd` e `resolution.gd`)
- **Estado anterior:** Em `phase == 8`, o código chamava `result = model.Rules.resolve(board, false)` de uma só vez, removendo imediatamente todas as ondas da cadeia do tabuleiro lógico (`board.cells`), atribuindo `clear_timer = 40 * result.waves.size()` e aguardando em `phase == 11` apenas para somar a pontuação consolidada no final.
- **Sequência real do MAME (`$17E(A6)`):**
  - **`phase == 8` (`$D1FE` / `$D26A` / `$D3D6` / `$D462`):** Executa `form_powers(board)` na entrada da onda e roda um passo de flood-fill síncrono de 3 bits (`0x10`, `0x20`, `0x40`) por passagem. Para cada passagem em que há propagação (`D5 == 1`, ou `1` passagem para onda de Diamond), define `clear_timer = 40` e retorna a `phase = 3` (`8 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8`, 6 quadros por passo de propagação). Quando não há mais propagação (`D5 == 0`), avança `8 -> 9 -> 10 -> 11`.
  - **`phase == 11` (`$F67C` / `$F72A`):** Mantém as gemas condenadas no tabuleiro lógico (`board.cells`) durante 39 quadros (`clear_timer` de `40` até `1`). No 40º quadro (`clear_timer: 1 -> 0`), remove **apenas a onda atual** (`resolve_single_wave(board, chain_count)`), soma o placar e o ataque daquela onda individual (com cancelamento imediato de `pending` no padrão CPS-2) e retorna para `phase = 3`.
  - **Gravidade intermediária entre ondas (`phase == 3`, `$CEC4`):** As gemas remanescentes caem 1 linha por quadro (`gravity_step(board)`). Quando `moved == 0` após ter havido movimento (`gravity_moved == true`), o arcade executa `00CFF6: move.b #$1, ($17e, A6)`, transitando `3 -> 1 -> 2 -> 3 -> 4` (com `counters_advanced` / `$252(A6)` impedindo novo decremento dos contadores de Counter Gems em `phase == 2`) antes de formar novas Power Gems em `phase == 4` e avaliar a próxima onda da cadeia em `phase == 8`.
  - **Flags temporárias de animação em Counter Gems colaterais (`gem_rules.gd`):** Durante `phase 8..11`, o MAME marca gemas condenadas nos bits `0x10..0x70` do byte baixo (ex.: `0x4437`, `0x4457`). A canonização foi ajustada de `(code & 255) in [6, 7]` para `(code & 15) in [6, 7]` (`00E55C: andi.w #$f, D3`).

#### B. Estados `17..19` (Entrega e Queda Quadro a Quadro de Counter Gems)
- **Estado anterior:** Em `phase == 18`, o código chamava `model.receive_attack(player, 1 - player)` de forma instantânea no fundo do tabuleiro e avançava para `phase == 19` sem queda quadro a quadro.
- **Sequência real do MAME (`$CCC6` em `phase == 18` e `$D058` em `phase == 19`):**
  - **`phase == 18` (`$CCC6`):** Se `pending[player] > 0` e o oponente não perdeu, entrega no máximo **1 linha** por passagem na linha de topo `y = 0` (`board.cells[0..5]`): `6` Counter Gems quando `attack_slot == 0` e `pending >= 6`, ou `< 6` Counter Gems residuais usando a permutação `Economy.columns(residual_index[player])`, consumindo `attack_slot` e `pending[player]` gemas a gema e concedendo o bônus `first_attack` (`+1000`) na primeira entrega. Em seguida avança para `phase = 19`.
  - **`phase == 19` (`$D058`):** Executa `counter_gravity_step(board)`, onde todas as células não-Power sem suporte em cada coluna (`x = 0..5`, varrendo `y = 12` até `0`) descem 1 linha simultaneamente no mesmo quadro. Enquanto `moved > 0`, define `phase = 17` (`00D0E0: move.b #$11, ($17e, A6)`), ciclando `19 -> 17 -> 18 -> 19` (1 linha a cada 3 quadros, com novas linhas surgindo em `y = 0` a cada passagem por `phase == 18`). Quando `moved == 0`, define `phase = 0` (`00D0C2`), verifica derrota na casa de spawn (`board.cells[15] != 0`) e, se vivo, avança `pair_index` e gera a próxima dupla.

### 2. Novas Fixtures e Testes Reproduzíveis Criados
- `scripts/gerar_fixtures_cadeias_counter_v10_2.py` e `godot/data/chain_counter_timeline_fixtures.json`:
  - **22 cenários MAME (`5.066` amostras quadro a quadro)** extraídos de `laboratorio/auto_20261028_232043_038647/mechanics.csv` e `captures/*.bin`, com verificação SHA-256 dos 22 snapshots `*_seed.bin` de 64 KiB.
- `godot/tests/test_chain_counter_timeline.gd`:
  - Confronta quadro a quadro `turn1`, `turn2`, `score1`, `score2`, `phase1`, `phase2`, `pending1`, `pending2`, `grid1` e `grid2` nas **5.066 / 5.066 amostras** (`0` divergências) e executa **54 asserções explícitas** cobrindo as 7 categorias exigidas:
    1. Destruição simples (`crash_red4`, `crash_pair`, `power_crash4`, `counter_adjacent_same`, `counter_adjacent_other`).
    2. Combos de duas ou mais ondas (`chain_2`, `chain_3`, `chain_3_counter`, `combo_two_colors`, `combo_three_colors`, `combo_two_powers`).
    3. Queda intermediária entre cadeias (`chain_3_larger`, `power_rigid_gravity`, `chain_2`, `chain_3`).
    4. Entrega de Counter Gems (`attack_red8`, `attack_red12`, `attack_p2_red12`).
    5. Queda quadro a quadro das Counter Gems (`attack_red8`, `attack_red12`, `attack_p2_red12`, `chain_2`, `counterattack_8_5`).
    6. Ataques simultâneos (`attack_cancel`, `counterattack_4_4`, `counterattack_4_8`, `counterattack_8_5`, `counterattack_8_8`, `counterattack_large_2_4`).
    7. Transição para a próxima dupla (`phase: 19 -> 0`, `turn_number`, `pair_index` e spawn da dupla seguinte).

### 3. Limitações de RNG e Equivalência de RAM Nativa
- O avanço da semente global de 32 bits (`$FF8378`) e as tabelas de duplas (`$5B950` / `$5BC50`) estão validados nas 33 trilhas de `test_controls_fidelity.gd` (`866/866` amostras), mas consumidores globais fora do escopo do duelo lógico (ex.: sub-rotinas cosméticas/visuais do arcade que consultam `$362C` em momentos específicos de partida natural) e bytes auxiliares de RAM nativa fora do modelo não foram provados equivalentes bit a bit em 100% dos 64 KiB. Em `MatchModel`, `locked_residual` permite injetar o índice residual `$37B(A6)` medido no MAME para testes determinísticos de timeline sem alterar o cálculo padrão `global_seed & 7` em jogo normal.
