# Arquitetura Godot 4 — V10, duelo local

Estado documental final em 04/11/2026: V10.1, V10.2 e V10.3.1–V10.3.4 concluídas na branch `feature/v10-gem-physics`. A auditoria final do checkpoint `4575f17a706d91df3ff009fb8b4d96d0cba06699` recomenda a liberação no escopo medido, com ressalvas. As correções finais e o encerramento documental foram concluídos; o registro do checkpoint final está autorizado nesta etapa. A publicação de `v0.10.0` permanece pendente, sem push, merge ou criação da tag.

O projeto está em `godot/project.godot`. `Jogar.cmd` usa o Godot 4.7.2 portátil no caminho local `ferramentas/godot_4.7.2`. A apresentação combina desenho Godot com sprites, texturas e áudio próprios do tema CS. O jogo não depende da execução do MAME; as comparações de fidelidade usam observações coletadas anteriormente no arcade.

## Módulos e fluxo da partida

| Módulo | Responsabilidade atual |
|---|---|
| `core/gem_rules.gd` | Tipos, cores, códigos canônicos e contadores; inclui Diamond/C4 |
| `core/board_model.gd` | Grade 6×14, duas linhas ocultas, colisão, depósito e retângulos Power |
| `core/pair_model.gd` | Pivô, satélite e quatro orientações da dupla ativa |
| `core/gem_motion.gd` | Relógio por jogador: queda, contato, giro, depósito, ondas, gravidade intermediária, entrega/queda de Counter Gems e próxima dupla |
| `core/resolution.gd` | Formação/crescimento/união Power, gravidade, Crash, Diamond/C4, conversão e resolução de ondas |
| `core/attack_rules.gd` | Pontuação, cadeias, ataques, cancelamentos e padrões de Counter Gems |
| `core/arcade_rng.gd` | Transição aritmética de 16 bits observada no arcade; não é o gerador completo certificado de uma partida |
| `core/control_model.gd` | Repetição horizontal, aceleração de Down e frequência CPS-2 |
| `core/match_model.gd` | Dois tabuleiros, máscaras, stream de duplas, ataques pendentes, pontuação e vencedor; delega os ticks ao relógio de cada jogador |
| `core/match_session.gd` | Sorteio de lados, seleção e série melhor de três; RNG de sorteio separado do gerador das gemas |
| `core/character_catalog.gd` e `selection_state.gd` | Oito agentes CS, escolhas restritas à equipe sorteada e mapeamento dos padrões de ataque |
| `adapters/mame_replay.gd` | Importação validada das observações de movimento para replay |
| `presentation/main.gd` | Entrada, retenção de bordas de tecla, acumulador CPS-2, ponte com a apresentação, HUD, replay e transições de round |
| `presentation/pair_rotation_visual.gd` | Observador da trajetória orbital: oito passos discretos, sem fornecer geometria ao modelo |
| `presentation/cs_arena.gd` | Contornos, ondas/efeitos da apresentação, Power Gems por célula/região, personagens e cenários |

A dupla ativa permanece separada das células assentadas. `main.gd` acumula tempo no quantum `1 / (8.000.000 / (512 × 262))` e chama `Match.tick()`. A queda livre usa os intervalos e offsets do relógio; o contato percorre 16..1, com depósito na transição seguinte. Nos casos medidos, giro é permitido em 15..2 e bloqueado em 16/1. As decisões de colisão e giro pertencem ao modelo.

O jogo normal usa **resolução temporal**, quadro a quadro, em `GemMotion.resolve_frame()`. A remoção de uma onda precede sua gravidade intermediária e a próxima avaliação. Ataques podem chegar enquanto o outro jogador resolve seu tabuleiro; Counter Gems são entregues e caem nas fases observadas. `Rules.resolve()` e `Match.resolve_turn()` continuam disponíveis para cenários imediatos, fixtures, demonstrações e testes de integração. Essa existência não significa que a partida normal tenha voltado a resolver tudo instantaneamente.

Power Gems mantêm geometria rígida no modelo. A união medida tem um estágio visual 3×2+2×2 de dez ticks antes do 5×2, enquanto o retângulo lógico já pode estar consolidado. O observador orbital e as atualizações da arena foram verificados como somente leitura do estado do modelo nos testes específicos.

## Apresentação integrada na V10

- A V10.3.2 liga queda, contato, ondas e remoção ao estado corrente. O Ghost Gem Flicker não foi reproduzido nas regressões atuais: a apresentação não devolve gemas removidas por encerrar cedo uma fila visual independente.
- Pouso e ligação usam contornos discretos nos casos medidos, sem inventar squash elástico contínuo. O halo e a ligação vertical têm limites de geometria/cor registrados no relatório.
- A V10.3.3 desenha a rotação orbital por oito offsets discretos, preservando identidade, pausa, reinício e independência P1/P2.
- A V10.3.4 mantém fases internas Power A→B→C→D→C→B→A, com blocos de oito ticks e A final persistente. Os relógios pertencem à célula/região/cor; crescimento e fusão reiniciam apenas as regiões afetadas. Os overlays próprios preservam o perímetro da arte base.
- Os efeitos acompanham a onda corrente e a remoção lógica. **A cronologia detalhada de todos os tiles nativos de explosão não foi reproduzida integralmente.** Evitar o Ghost não prova equivalência visual completa.

## Dados e limites de RNG

As fixtures de regras, controles e endpoints naturais ficam em `godot/data/{mechanics_fixtures,control_fixtures,natural_fixtures}.json`. A física temporal usa `relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json`; cadeias usam `godot/data/chain_counter_timeline_fixtures.json`. Os testes comparam resultados esperados coletados no MAME, não valores inventados para a implementação.

`attack_profiles.json` contém oito permutações e 11 padrões numéricos observados; o catálogo CS usa o mapeamento configurado em `character_patterns.json`. Isso não certifica a identidade gráfica/nome nativo de todos os padrões do arcade. SAS e Phoenix têm arte própria; seis agentes mantêm representações temporárias identificadas no catálogo.

O avanço de `ArcadeRng` passa nas 866 amostras observadas, mas os consumidores globais CPS-2 e o gerador completo de peças não são certificados. `MatchModel` ainda usa `RandomNumberGenerator` do Godot, seed 96, Crash periódico e Diamond a cada 25ª dupla para o stream compartilhado. `locked_residual` permite injetar índices observados em testes; não prova igualdade RNG de uma partida natural inteira. A seleção/Coin Flip não altera esse RNG determinístico das gemas.

## Validação e ressalvas da auditoria final

Os resultados a seguir foram executados na auditoria de 03/11/2026, não reexecutados nesta preparação documental:

| Grupo | Resultado |
|---|---|
| Física temporal | 112/112 cenários; 14.072/14.072 amostras |
| Cadeias/Counter Gems | 22/22 cenários; 5.066/5.066 amostras; 54 verificações |
| Fidelidade / controles / naturais | 247/247; 33/33 e 866 amostras RNG; 119/119 endpoints |
| Regras / Python | 34 verificações / 17 testes |
| V10.3.2 / V10.3.3 / V10.3.4 | 123.863 / 119.052 / 394 verificações |
| Power / rotação atual contra MAME | 1.192 amostras de células; 181 pares/1.407 verificações estruturais; 80 pares de rotação sem diferenças de máscara |
| Integração de séries | 1.000/1.000 séries MD3; 2.500 rounds; 51.000 verificações |
| Janela com adaptador | 4/4 séries; dez rounds; 276 verificações |
| Baterias existentes / cenas | 17/17 baterias; quatro cenas no smoke aprovadas |

As **1.000 séries têm desfechos controlados**: o teste prepara top-out e chama o resolvedor para validar Coin Flip, seleção, placar, troca de rounds e nova partida. Não são 1.000 duelos naturais jogados somente por entradas nem sincronizados integralmente ao MAME. Separadamente, `test_duel.gd` percorreu 1.500 turnos gerados e `test_natural_fidelity.gd` aprovou 119 endpoints preservados. A antiga declaração de sete falhas naturais não descreve a V10 atual.

**Executor gráfico corrigido:** `validar_fluxo_partidas.py --visual` e `--movie` agora selecionam `test_match_flow_visual_v10_3_4.gd`. O adaptador herda o teste e espera mais 0,25 s após capturar o resultado, sem mudar inputs, asserções ou a temporização do Coin Flip. O executor corrigido passou em janela real: 4/4 séries, dez rounds, 276 verificações e 30 capturas. O lote headless continua usando `test_match_flow.gd`. **O teste gráfico histórico, executado isoladamente com `--visual`, continua falhando** por confirmar cedo demais após a moeda; sua falha foi reproduzida e o arquivo preservado para referência. Eventos de teclado/gamepad são simulados; não houve teste de periférico físico.

**Validadores corrigidos e testados:** as aprovações indevidas de dados vazios, reproduzidas na auditoria de 03/11, foram encerradas nas correções finais de 04/11. O teste físico exige os 112 identificadores esperados, cobertura de amostras por cenário e o total 14.072; o estrutural exige os 181 pares cenário/frame, metadados válidos e imagens legíveis de 1000×700. Ambos rejeitam entradas vazias/incompletas, duplicatas e arquivos inválidos com saída 1 e mensagens claras. Foram preservadas as fixtures originais. A suíte Python passou de 17 para 28 testes (11 métodos novos com subcasos), incluindo dados negativos e conjuntos completos positivos. As regressões principais mantiveram os totais físicos, de combos, controles, Power, rotação, Coin Flip e partidas integradas da auditoria. O histórico das falhas e as execuções intermediárias permanecem no relatório complementar. Nenhum teste foi reexecutado neste encerramento documental.

**Limites visuais e de ambiente:** não há certificação visual integral ao MAME, de todas as cores/geometrias/P2, de todos os scripts de explosão ou de igualdade RGB. A validação nativa mantém 73 avisos herdados, incluindo 11 de caminhos do lint, sem erros. O Godot portátil e as coletas locais em `laboratorio/` não estão no Git; comparadores dependem dessas fontes, e o gerador Power contém um caminho absoluto. Sprites próprios já estão versionados; ROMs, dumps e save states não são distribuídos. Não se certificaram novos binários exportados ou outras plataformas.

Estado final e limites completos: [correções finais de 04/11](relatorios/v10_final/RELATORIO_CORRECOES_FINAIS_V10.md) e [continuidade](CONTINUIDADE_PROJETO.md). A [auditoria de 03/11](relatorios/v10_final/RELATORIO_AUDITORIA_V10.md), seu [resumo](relatorios/v10_final/summary.json) e a [preparação documental anterior](relatorios/v10_final/ENCERRAMENTO_DOCUMENTAL_V10.md) permanecem como registros históricos; suas pendências foram encerradas pelo complemento. Declarações de índice vazio, HEAD e autorizações na continuidade e nos relatórios retratam o instante de cada etapa. O registro do checkpoint final foi autorizado posteriormente, sem autorizar publicação.
