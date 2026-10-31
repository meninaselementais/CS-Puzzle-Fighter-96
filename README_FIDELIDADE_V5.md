# Counter-Strike Puzzle Fighter '96 — Relatório de Fidelidade v5

## 1. Resumo Executivo

Esta iteração (**Fidelidade v5**) retomou o projeto a partir da Fase 4 (`relatorios/fidelidade_v4`), investigou no MAME 0.289 (`spf2tu` — *Super Puzzle Fighter II Turbo*, USA 960620, CPS-2 / Motorola 68000) as 7 divergências restantes em partidas naturais sem injeção de RAM, implementou e validou a **Diamond Gem (`0x0005`)**, corrigiu a sincronização de ataques simultâneos/assíncronos e preparou a apresentação visual arcade anos 1990 com tema **Counter-Strike** (`CT SAS com M4A1-S` vs `Phoenix com AK-47`, cenários `Dust2`, `Mirage` e `Inferno`).

### Resultados Consolidados de Validação

| Bateria de Testes | Resultado v4 (Anterior) | Resultado v5 (Atual) | Evidência Gerada |
| :--- | :---: | :---: | :--- |
| Comparações Controladas MAME vs Godot (`test_fidelity.gd`) | 247 / 247 | **247 / 247** | `relatorios/fidelidade_v5/comparacao.json` |
| Controles, Rotação, Gravidade e RNG (`test_controls_fidelity.gd`) | 33 / 33 (RNG 866) | **33 / 33 (RNG 866)** | `relatorios/fidelidade_v5/controles.json` |
| Endpoints de Partidas Naturais sem Injeção (`test_natural_fidelity.gd`) | 112 / 119 (7 divergências) | **119 / 119 (0 divergências)** | `relatorios/fidelidade_v5/partidas.json` |
| Verificações Unitárias de Regras (`test_rules.gd`) | 28 / 28 | **34 / 34** | Inclui 6 cenários de Diamond Gem |
| Simulação de Duelo (`test_duel.gd`) | 1.500 turnos | **1.500 turnos (26 partidas)** | Sem anomalias |
| Geometria e Modelo de Tabuleiro (`test_models.gd`) | Aprovado | **Aprovado** | `GODOT_TESTS_OK` |
| Renderização e Apresentação CS '96 (`render_mechanics.gd`) | Aprovado | **Aprovado** | `relatorios/fidelidade_v5/prototipo_mecanicas.png` |
| Testes Unitários Python (`unittest discover -s tests`) | 17 / 17 | **17 / 17** | Validação binária, RNG e Diamond Gem |

---

## 2. Engenharia Reversa Motorola 68000 (`spf2tu`)

### 2.1. Máquina de Estados Completa de Resolução por Jogador (`0x00BFC0` / Tabela `0x00C034`)

O deslocamento `$17E(A6)` (`0xFF847E` para P1 e `0xFF887E` para P2) indexa a tabela de saltos em `0x00C034` (`move.w ($6A,PC,D0.w), D1; jsr ($66,PC,D1.w)`):

- **Estado `0` (`0x00C176`)**: Queda livre e controle da dupla ativa (`jmp $1166C`).
- **Estado `1` (`0x00C2C6`)**: Gravidade inicial pós-assentamento (`jsr $CEC4`).
- **Estado `2` (`0x00C2D8`)**: Bônus de queda acelerada (`$376(A6)`) e decremento de Counter Gems (`jsr $D76E; jsr $D8BC; jsr $D824`), protegido por `$252(A6)` para executar apenas uma vez por turno.
- **Estado `3` (`0x00C2C6`)**: Gravidade pós-decremento (`jsr $CEC4`).
- **Estados `4..7` (`0x00C1FA..0x00C236`)**: Detecção de Power Gems 2x2 e expansão retangular (`$DCAA`, `$DCB6`, `$DCCA`).
- **Estado `8` (`0x00C28E`)**: Marcação de limpezas (`jsr $D3D6`), **Diamond Gem (`jsr $D26A`)** e **Crash Gem (`jmp $D462`)**.
- **Estado `9` (`0x00C2B0`)**: Pontuação base de células de Power Gem (`jmp $F8E0`, tabela em `0x00FFF8`).
- **Estado `10` (`0x00C2C6`)**: Gravidade intermediária (`jsr $CEC4`).
- **Estado `11` (`0x00C4EA` -> `0x00F72A`)**: Temporizador de animação de limpeza de 40 quadros (`$180(A6)`). Ao zerar, executa `bsr $FAB0` (pontuação da onda, bônus de cadeia, contra-ataque em `$19E(A2)` e envio em `$19E(A6)`). Se houver nova cadeia, retorna ao Estado `3`; caso contrário, avança ao Estado `12`.
- **Estados `12..15` (`0x00C24C..0x00C1FA`)**: União final de Power Gems após o término das cadeias (`$F060`, `$EEB0`, `$ECEC`, `$DCAA`).
- **Estado `16` (`0x00C4F0`)**: Copia a fila pendente do oponente `$19E(A2)` para `$244(A2)`.
- **Estado `17` (`0x00C500`)**: Contagem de células no tabuleiro e verificação de *All Clear* (`jmp $D76E`). Se `$19E(A2) == 0`, salta diretamente para o fim do turno (`0x00C524`).
- **Estado `18` (`0x00C5E2`)**: **Entrega de Ataque (`jsr $CCC6`)** — consome até 12 Counter Gems por passagem (2 linhas de 6 em `($2, A0)` [`y=0`] e `(A0)` [`y=-1`]), incrementa o contador de recebimento `$37D(A6)` e usa o índice residual `$37B(A6)` congelado no instante da entrega.
- **Estado `19` (`0x00C31E`)**: **Queda das Counter Gems Recebidas (`jsr $D058`)** — desce as Counter Gems recém-inseridas 1 linha a cada 3 quadros, ciclando `19 -> 17 -> 18 -> 19` até assentar todas as gemas e então zerar `$17E(A6) = 0` e gerar a próxima dupla (`jsr $11A1A`).

### 2.2. Resolução das 7 Divergências em Partidas Naturais

As 7 divergências observadas em `relatorios/fidelidade_v4/partidas.json` tinham três causas raízes:

1. **Amostragem prematura de `incoming` e `permutation` no script Lua (`partidas.lua`)**:
   - Na v4, `incoming` (`other + 0x19E`) e `permutation` (`base + 0x37B`) eram lidos no quadro inicial do turno (`state: 0 -> 1`).
   - Como o Estado `11` dura 40 quadros por onda, o oponente frequentemente concluía um ataque *durante* a animação do jogador atual (ou o índice residual `$37B` avançava pelo RNG global antes do Estado `18`).
   - Além disso, em `natural_e1_p1_t3_f48`, P2 depositou `2` gemas na fila de P1 durante o Estado `11` de P1; ao final do Estado `11`, `$FAB0` de P1 aplicou `cancel_attack(2)` contra `2` (`2 - counter_strength(2) = 1`) e entregou `1` no Estado `18`. Ao amostrar `other + 0x19E` nos Estados `11`, `17` e `18` (além do delta entregue em `$37D`), o valor exato pré-contra-ataque e na entrega é preservado.
2. **Bônus de Primeiro Ataque Assíncrono (`opponent_first_bonus`)**:
   - Em `natural_e4_p1_t5_f1134`, P1 iniciou um turno com 2 ondas de limpeza (duração total > 80 quadros). Durante a primeira onda de P1, P2 atingiu o Estado `18` (`$CCC6`), recebeu o ataque anterior de P1 e concedeu `+1000` pontos de *First Attack Bonus* (`0xFF8691: 0 -> 1`) a P1 no meio do turno de P1 (`deliver_opponent_pending`).
3. **Sobrescrita da Linha de Topo (`y = 0`) na Entrega em Coluna Cheia (`natural_e3_p1_t6_f1905`)**:
   - Em `$CCC6` (`00CD12: move.w D1, ($2, A0)`), a primeira linha da fatia de Counter Gems é escrita incondicionalmente em `$2(A0)` (`y = 0`), sobrescrevendo eventual gema já estacionada em `y = 0` quando a coluna inteira (`y = 0..13`) está preenchida, enquanto a segunda linha (`00CD68: move.w D1, (A0)`, `y = -1`) permanece fora da grade visível por não conseguir descer em `$D058`.

### 2.3. Regras Confirmadas da Diamond Gem (`0x0005` / Rotina `0x00D26A`)

Validadas na sessão MAME `laboratorio/auto_20261029_002212_706781` com `lua/diamante.lua`:

- **Geração (`0x011A1A`)**: A cada 25ª peça (`(pair_index + 1) % 25 == 0`, verificado por `cmpi.b #$19, ($19C, A6)` em `0x011AD8`), o satélite da dupla é substituído por `0x0005` (`Diamond Gem`).
- **Diamond Gem no chão (`y == 13`, `diamond_floor`)**: Remove a si mesma, concede **`+10.000` pontos** (`0x00D318`) e gera **`0` de ataque**.
- **Diamond Gem sobre gema normal, Power Gem, Crash Gem ou Counter Gem (`y < 13`)**:
  - Usa a cor (`1..4`) da gema imediatamente abaixo (`y + 1`) como cor-alvo.
  - Elimina todas as gemas daquela cor no tabuleiro inteiro — incluindo **Normal Gems**, **Power Gems**, **Crash Gems** e **Counter Gems** daquela cor.
  - **Conversão de Counter Gems (`0x00D2D0: andi.w #$600F, D0`)**: Counter Gems da cor-alvo têm os bits de temporizador limpos antes da contabilização em `$FAB0`, portanto pontuam como **gemas normais (`100` pts cada + bônus de tamanho)** em vez de colaterais (`20` pts).
  - **Power Gems eliminadas**: Contabilizam a pontuação de área normal da tabela de Power Gems (`200` pts/célula para 2x2).
  - **Redução do Ataque pela Metade (`0x00FB88: lsr.w #1, D6`)**: Quando a flag de Diamond Gem (`$250(A6)`) está ativa, o ataque calculado pela onda é dividido por 2 (`attack >> 1`).

---

## 3. Camada Visual Arcade CPS-2 — Counter-Strike '96 (Etapa 7)

Toda a apresentação visual foi reconstruída com **sprites e texturas reais em pixel art estilo Capcom CPS-2 (1996)** em `godot/assets/sprites/` (processados por `godot/tools/process_sprites.gd`), eliminando a aparência geométrica experimental e reproduzindo a composição de *Super Puzzle Fighter II Turbo*:

- **Gemas Cristalinas e Power Gems 9-Slice**:
  - **Normal Gems (`gem_normal_1..4.png`)**: Cristais octogonais lapidados (Safira, Topázio, Esmeralda e Rubi) com facetas internas, sombras profundas e reflexo especular animado.
  - **Crash Gems (`gem_crash_1..4.png`)**: Orbes luminosos engastados em garras douradas com núcleo pulsante.
  - **Counter Gems (`gem_counter_1..4_1..5.png`)**: 20 sprites cristalinos com aro metálico e numeral 3D sombreado (`5..1`).
  - **Diamond Gem (`gem_diamond.png`)**: Prisma iridescente ciano/arco-íris.
  - **Power Gems (`power_crystal_1..4.png`)**: Texturas cristalinas 9-slice (`96x96`) com chanfros octogonais 3D, reflexo diagonal, halo pulsante e brilho estelar proporcional à área da Power Gem.
- **Personagens Chibi Expressivos e Efeitos de Combate**:
  - **P1 — Counter-Terrorist SAS (`sas_idle.png`, `sas_shoot.png`, `sas_grenade.png`, `sas_hit.png`)**: Capuz azul-marinho, máscara de gás com lentes ciano expressivas, colete tático e rifle **M4A1-S** com silenciador.
  - **P2 — Terrorista Phoenix (`phoenix_idle.png`, `phoenix_shoot.png`, `phoenix_grenade.png`, `phoenix_hit.png`)**: Balaclava clássica com expressões faciais intensas, colete Kevlar, calça camuflada, cápsulas deflagradas e rifle **AK-47**.
  - **Partículas e VFX (`vfx_muzzle_sas.png`, `vfx_muzzle_phoenix.png`, `vfx_grenade.png`, `vfx_explosion.png`, `vfx_shatter.png`, `vfx_shockwave.png`, `vfx_lightning.png`)**: Clarões de disparo, granadas HE em arco parabólico, ondas de choque, relâmpagos de combo e estilhaços cristalinos nas células destruídas do tabuleiro.
- **Cenários Panorâmicos CPS-2 (`1`/`F1`, `2`/`F2`, `3`/`F3` ou `M`)**:
  - `stage_dust2.png` (**DE_DUST2 — Bombsite A**)
  - `stage_mirage.png` (**DE_MIRAGE — Palace Courtyard**)
  - `stage_inferno.png` (**DE_INFERNO — Fountain & A-Site**)
- **HUD Arcade Premium Anos 1990**: Emblema central 3D `CS PUZZLE FIGHTER '96` sobre brasão estelar (`hud_logo.png`), caixas `NEXT` chanfradas no topo central, poços semitransparentes com barra de entrada aberta na coluna `x = 3`, placas `SCORE` metálicas, insígnia cromada `VS` (`hud_vs.png`) e troféus `V` (`hud_v.png`).

---

## 4. Arquivos Criados e Modificados

- `lua/diamante.lua`: Ensaio automatizado de MAME para os 6 cenários da Diamond Gem e dump de tabelas da ROM (`piece_tables.bin`, `power_table.bin`).
- `lua/partidas.lua`: Amostragem fiel de `incoming` nos estados `11`, `17` e `18`, `permutation` nos estados `17`/`18` e detecção de `opponent_first_bonus`.
- `scripts/exportar_mecanicas.py`: Preservação do código `5` (`Diamond Gem`) em `canonical()`.
- `scripts/exportar_partidas.py`: Exportação do campo `opponent_first_bonus` para `godot/data/natural_fixtures.json`.
- `godot/core/gem_rules.gd`: Adição de `Kind.DIAMOND` e `is_diamond()`.
- `godot/core/resolution.gd`: Implementação de `diamond_wave()` e integração no laço de cadeias de `resolve()`.
- `godot/core/match_model.gd`: Geração da Diamond Gem a cada 25ª dupla, `deliver_opponent_pending()` e sobrescrita da célula `y = 0` na primeira linha de `receive_attack()` quando a coluna está cheia.
- `godot/presentation/cs_arena.gd` e `godot/presentation/main.gd`: Arquitetura visual Counter-Strike '96, cenários Dust2/Mirage/Inferno, lutadores chibi SAS/Phoenix, caixa `NEXT` e renderização da Diamond Gem.
- `godot/project.godot`: Filtro `nearest` e alinhamento de pixels 2D.
- `godot/tests/test_natural_fidelity.gd`, `godot/tests/test_fidelity.gd`, `godot/tests/test_controls_fidelity.gd`, `godot/tests/test_rules.gd`, `godot/tests/test_duel.gd`, `godot/tests/render_mechanics.gd`, `tests/test_mecanicas.py`: Expansão dos testes e geração de relatórios em `relatorios/fidelidade_v5/`.
