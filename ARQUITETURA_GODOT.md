# Arquitetura Godot 4 — duelo local

O projeto existente continua em `godot/project.godot`, com Godot 4.7.2 portátil. `Jogar.cmd` inicia o duelo. A apresentação usa formas próprias desenhadas pelo Godot, sem importar sprites, áudio ou conteúdo dos originais.

| Módulo | Responsabilidade |
|---|---|
| `core/gem_rules.gd` | Tipo, cor, representação canônica e contador de cada pedra |
| `core/board_model.gd` | Grade 6x14, duas linhas ocultas, colisão, assentamento e retângulos Power |
| `core/pair_model.gd` | Pivô, satélite e quatro orientações |
| `core/resolution.gd` | Formação/crescimento/união Power, gravidade rígida, Crash, contadores e cadeias |
| `core/attack_rules.gd` | Pontuação por onda, combo, cadeia e quantidade de ataque |
| `core/arcade_rng.gd` | Transição de 16 bits do RNG original, verificada por breakpoints |
| `core/control_model.gd` | Repetição horizontal, aceleração cumulativa de Down e frequência CPS-2 |
| `core/match_model.gd` | Dois jogadores, geração, fila de ataques, contra-ataques, recebimento, vitória e derrota |
| `adapters/mame_replay.gd` | Importação validada das observações de movimento |
| `presentation/main.gd` | Entrada, repetição de teclas, HUD, desenho e replay |

O núcleo não conhece endereços de memória nem depende do MAME. A dupla ativa permanece separada das células assentadas. `resolve()` devolve ondas, pontos e ataques; cada onda descreve componentes destruídos, Power Gems e Counter Gems colaterais. Power Gems mantêm sua geometria durante a queda.

Os dados reais estão em `data/mechanics_fixtures.json`, `control_fixtures.json` e `natural_fixtures.json`. Python os extrai do arcade. `test_fidelity.gd`, `test_controls_fidelity.gd` e `test_natural_fidelity.gd` comparam regras, controles e endpoints naturais. Os resultados esperados vêm do MAME. O teste de partidas mantém sete falhas conhecidas e retorna 1; não há tolerância que as esconda.

`test_models.gd` preserva as verificações anteriores. `test_rules.gd` cobre casos específicos. `test_duel.gd` executa 1.500 turnos com três sementes de movimentos e rotações. `render_mechanics.gd` verifica eventos físicos, o relógio CPS-2 e a captura nativa da apresentação.

`attack_profiles.json` contém oito permutações e 11 padrões numéricos de personagem, lidos das tabelas usadas pelo arcade. `Match.character_ids` escolhe o padrão de cada jogador. Apenas as identidades Ryu=2 e Ken=3 foram confirmadas neste trabalho; a associação dos demais IDs a nomes/gráficos não foi concluída.

O replay usa `render_y = y - 1 + fraction_y / 16`. O duelo agora usa o relógio CPS-2 de 8.000.000/(512×262) Hz, repetição horizontal após 12 quadros com intervalo de um quadro, aceleração de Down por estágios e ajustes de rotação medidos em paredes, piso e corredores estreitos. A renderização continua discreta e as resoluções são imediatas.

O RNG global exato já escolhe permutações na queda livre. O consumo durante outras fases ainda não replica o original. A geração de cores/Crash continua provisória; o gerador completo, Diamond Gem, animações, chegada de ataques durante a resolução e encerramentos simultâneos permanecem pendentes. O núcleo e seus eventos de onda, pontos e ataques estão disponíveis para uma apresentação com gráficos e animações próprias, sem acoplar as regras aos assets.
