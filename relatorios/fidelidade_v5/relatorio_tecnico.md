# Relatório Técnico — Fidelidade v5 (`relatorios/fidelidade_v5`)

## Sessões de Laboratório MAME 0.289 Utilizadas

1. **Validação da Diamond Gem e Dump de Tabelas da ROM (`lua/diamante.lua`)**:
   - Sessão: `C:\Projetos\CS-Puzzle-Fighter-96\laboratorio\auto_20261029_002212_706781`
   - Resultados em `diamond.csv`:
     - `diamond_floor`: `score_before=0`, `score_after=10100` (`10000` bônus Diamond no chão + `100` queda acelerada), `pending_after=0`.
     - `diamond_normal_blue`: `score_before=0`, `score_after=1370` (`970` onda de 9 células + `400` queda acelerada), `attack=4` (`9 >> 1`).
     - `diamond_counter_blue`: `score_before=0`, `score_after=820` (`420` onda de 4 células, incluindo Counter Gem azul convertida em normal + `400` queda acelerada), `attack=2` (`4 >> 1`).
     - `diamond_power_blue`: `score_before=0`, `score_after=1440` (`1040` onda com Power Gem 2x2 azul + `400` queda acelerada), `attack=5` (`10 >> 1`).
     - `diamond_on_counter`: `score_before=0`, `score_after=710` (`310` onda de 3 células verdes ao pousar sobre Counter Gem verde + `400` queda acelerada), `attack=1` (`3 >> 1`).
     - `diamond_chain`: `score_before=0`, `score_after=1530` (`1130` em 2 ondas: `310` da Diamond Gem + `820` da 2ª cadeia vermelha + `400` queda acelerada), `attack=9` (`1 + 8`).

2. **Partidas Naturais sem Injeção de RAM (`lua/partidas.lua`)**:
   - Sessão: `C:\Projetos\CS-Puzzle-Fighter-96\laboratorio\auto_20261029_003820_341322`
   - Fixtures exportadas: `C:\Projetos\CS-Puzzle-Fighter-96\godot\data\natural_fixtures.json` (119 endpoints).
   - Resultado no Godot (`test_natural_fidelity.gd`): **119/119 aprovados** (`relatorios/fidelidade_v5/partidas.json`).

## Artefatos Gerados nesta Pasta

- `comparacao.json`: 247/247 casos controlados aprovados (`test_fidelity.gd`).
- `controles.json`: 33/33 casos de controle/rotação/gravidade e 866 amostras de RNG aprovadas (`test_controls_fidelity.gd`).
- `partidas.json`: 119/119 endpoints de partidas naturais aprovados (`test_natural_fidelity.gd`).
- `prototipo_mecanicas.png`: Captura visual 1000x700 da apresentação Counter-Strike '96 (`render_mechanics.png`).
