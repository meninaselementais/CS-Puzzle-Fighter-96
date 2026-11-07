# V11.3 — NEXT compacto

06/11/2026, America/Sao_Paulo. Projeto `C:\Projetos\CS-Puzzle-Fighter-96`, branch `feature/v11-hud`, HEAD/base V10 `1a943a4db4d1dba84a222735187afb6108b4c4c5` (`v0.10.0`).

**Implementação e validação técnica concluídas, submetidas à revisão do coordenador GPT-6 — ChatGPT.** O NEXT desenhado foi comparado com a dupla que o resolvedor real coloca em jogo no turno seguinte, em ambos os jogadores. A referência C é provisória e a aprovação estética continua pertencendo ao coordenador/usuário. Sem commit, push, tag ou alteração de refs.

## Escopo e inspeção

Antes da edição foram lidos os caminhos de geração/desenho, presenter, modelos de dupla/tipos de gema, plano V11 e layout C. O estado inicial do Git e hashes dos arquivos existentes foram preservados em `git_initial.txt` e `initial_manifest.json`.

Na V10, `_draw()` chama `get_next_colors(0)` e depois `get_next_colors(1)` uma vez cada. A consulta pode ampliar o stream usando o RNG se o cache ainda não existir. O modelo compartilha o stream, mas cada jogador tem seu próprio índice. `[0]` é pivô e `[1]` é satélite. A caixa antiga era 64×114, centros em y+32/y+76, distância 44. As gemas eram desenhadas em `main.gd`; a arena recebia `next_pairs`, mas não usava esse argumento.

Crash usa o bit 8 e os assets `gem_crash_1.png` a `gem_crash_4.png`; o código 5 é Diamond na lógica e C4 na arte CS, com `gem_c4_0.png`/`gem_c4_1.png` e fallback `gem_diamond.png`. Esses caminhos e seus relógios foram reutilizados.

## Arquivos

Alterados por esta etapa:

- `godot/presentation/main.gd`: preload do presenter; mesmas duas consultas NEXT, na mesma posição e ordem; snapshot imediatamente depois; envio à arena; remoção do desenho duplicado das gemas NEXT.
- `godot/presentation/cs_arena.gd`: geometria compacta, leitura de `next_pair` do snapshot e desenho pelo renderer já existente. Nome do agente acompanha a caixa.

Criados:

- `godot/tests/test_hud_next.gd`: teste gráfico, observação das chamadas reais ao renderer, comparação com spawn real e referência V10.
- `relatorios/v11_3/RELATORIO_V11_3.md`: este relatório.
- `relatorios/v11_3/run_validation.py`: executor local das baterias e checks.
- Evidências locais nesta pasta: `summary.json`, inventários, verificações de integridade, resumos, referências derivadas V10 em `.txt`, logs e capturas em `evidence/`.

O presenter e os dois testes da V11.2 ficaram byte a byte intactos. Também permaneceram intactos todo `godot/core/`, fixtures, scripts anteriores, configuração do projeto, planejamento, continuidade já modificada e demais arquivos locais. Nenhum arquivo do Cezar ou de outro projeto foi modificado. O manifesto final (`integrity.json`) confirma que só os dois arquivos de apresentação acima mudaram entre os preexistentes inventariados.

## Integração e dimensões

Fluxo: `_draw()` → consultas V10 P1/P2 → `Hud.snapshot(model, session_game and not replay_mode)` → `arena.draw_central_arena_and_hud(..., hud_snapshot)` → `draw_gem_sprite()`.

O presenter continua somente leitura, sem nova API ou reimplementação. Somente `next_pair` é utilizado pelo desenho novo. Perfis, WARNING, contadores e histórico não foram integrados. Em replay, dados de sessão não são associados ao snapshot. O caso de NEXT indisponível não inventa uma dupla.

| Elemento | P1 | P2 |
|---|---|---|
| Origem da caixa, conforme C | (284,108) | (668,108) |
| Caixa interna | 48×76 | 48×76 |
| Centro do satélite | (308,130) | (692,130) |
| Centro do pivô | (308,162) | (692,162) |
| Distância vertical | 32 | 32 |
| Baseline do nome de agente | y=212 | y=212 |

Offsets locais: satélite (24,22), pivô (24,54). Cada sprite genérico mantém destino nominal 31×31, com folga vertical de 6,5 px e lateral de 8,5 px; moldura externa, sombra e efeitos mantêm o renderer V10. 48×76 descreve a caixa interna, não o retângulo incluindo a sombra. Seeds visuais continuam `i*10+1` para satélite e `i*10+2` para pivô.

Foi aplicada somente a parte NEXT do layout C. Os poços continuam em passo 32 e os lutadores, placares e demais componentes permanecem no layout V10. O nome do agente, ainda sem nickname, foi reposicionado apenas para acompanhar o painel e evitar sobreposição.

A escala usa o canvas 1000×700 existente, sem configuração nova: `s=min(largura/1000,altura/700)`. Dimensões e distância são multiplicadas por s. O conteúdo com proporção preservada ocupa a área central e pode ter letterbox. Há arredondamento de pixels no viewport; asserções admitem diferença inferior a um pixel.

| Janela solicitada e confirmada | Framebuffer de conteúdo | Escala observada |
|---|---|---|
| 1000×700 | 1000×700 | (1,1) |
| 1280×896 | 1280×896 | (1,28;1,28) |
| 1280×900 | 1280×896 | (1,28;1,28), letterbox |
| 1600×900 | 1285×900 | (1,285;1,285714), arredondamento/letterbox |

Por exemplo, em 1280×896, NEXT mede 61,44×97,28 e o intervalo entre centros 40,96 px antes da rasterização. A textura retornada pelo Godot representa o conteúdo; não inclui necessariamente as barras da janela. Nenhuma física ou coordenada lógica foi escalada.

## Prova independente da próxima dupla real

O teste intercepta `draw_gem_sprite()` na arena de teste e continua chamando o renderer original. Registra códigos, centros e seeds efetivamente enviados ao desenho. Depois conclui o turno com `model.resolve_turn(player)` e compara esses códigos com `model.pairs[player].colors`, criado pelo `spawn()` real. A ordem conferida é satélite em cima e pivô embaixo.

O valor esperado não é calculado com `stream[pair_index+1]` nem com uma segunda chamada ao presenter. Foram exercitados 90 avanços de P1 e 45 de P2, com índices diferentes, quatro cores, Crash e C4 em ambos. Exemplos registrados:

- Primeiro NEXT: satélite 11, pivô 3; dupla real seguinte `[3,11]` em ambos.
- C4 P1 no passo 23: satélite 5, pivô 2; dupla real `[2,5]`.
- C4 P2 no passo 46: satélite 5, pivô 2; dupla real `[2,5]`.

Uma cópia da apresentação V10 preservada antes da edição roda em outro viewport com a mesma configuração de pixel snapping. A referência recebe apenas instrumentação de contagem de consultas e anotações de tipo para permitir substituir sua arena pela versão V10 preservada; expressões de geração, desenho e regras não foram alteradas. Após cada redraw e avanço, o teste compara recursivamente todas as propriedades do modelo, incluindo RNG/seed, stream, índices, tabuleiros, scores, pendências, duplas e movimentos.

Resultado: estado idêntico à referência V10; consultas por desenho exatamente `[0,1]`; nenhuma geração antecipada. Mil leituras adicionais do presenter e redraws em pausa/replay preservaram o estado. Na comparação de framebuffer inicial, **21.976 pixels mudaram dentro das áreas NEXT/títulos/nomes; zero pixels mudaram fora delas**. As regiões cobrem tanto as posições antigas quanto as novas.

Os 135 avanços são cenários controlados pelo resolvedor, não 135 turnos jogados por entradas. A cronologia temporal e as demais mecânicas foram verificadas separadamente pelas regressões V10 abaixo.

## Testes efetivamente executados nesta etapa

Ambiente: Windows, Godot 4.7.2, renderer gráfico OpenGL/NVIDIA RTX 5070, Python 3.11. Todos os resultados abaixo são desta execução, não históricos. Saída 0 nas execuções finais.

| Teste | Resultado |
|---|---|
| NEXT V11.3 | **1.072 checks, zero falhas**, P1/P2, 135 avanços, tipos, geometria, 4 janelas, pixels e paridade V10 |
| Presenter V11.2, inalterado | 3.931 checks, 7 suítes, zero falhas |
| Cena V11.2, inalterada | 1.013 checks, 1.000 consultas, `pixel_identical=true` |
| Modelos | `GODOT_TESTS_OK` |
| Regras | 34 checks, zero falhas |
| Fidelidade | 247/247 |
| Controles/RNG | 33/33; 866 amostras |
| Naturais | 119/119 |
| Duelo | 1.500 turnos, 28 partidas, 227 ondas |
| Apresentação | 3.285 checks |
| Coin Flip | 40.195 checks |
| Seleção | 3.351 checks |
| Timeline V10.3.2 | 123.863 checks |
| Rotação V10.3.3 | 119.052 checks; 80 passos principais, 11.957 amostras ativas |
| Power V10.3.4 | 394 checks |
| Animação V8 / arte V9 | 145 / 102 checks |
| Física | 112/112 casos; 14.072/14.072 amostras |
| Cadeias/Counter | 22/22 casos; 5.066/5.066 amostras; 54 checks |
| Showcase UI | `SHOWCASE_UI_OK` |
| Seleção UI | `COIN_SELECT_UI_OK`, 12 capturas, dois tamanhos de janela |
| Fluxo gráfico MD3, adaptador V10.3.4 | 4/4 séries; 10 rounds; 276 checks |
| Python | 28 testes OK |
| Lint | zero erros, 11 avisos |
| Validação nativa | zero erros, 72 avisos |
| Smoke com fuzz | 4/4 cenas; zero erros; 98 avisos acumulados |
| Git | `diff --check` sem erros; índice preservado vazio |

São 26 execuções finais aprovadas no resumo consolidado: NEXT + 2 testes V11.2 + 19 regressões Godot + 4 checks auxiliares. As contagens centrais das mecânicas coincidem com as linhas de base documentadas da V10. Os avisos nativos caíram de 73 para 72 e no smoke de 102 para 98; o parâmetro antes não utilizado pela arena atual passou a ser usado. Permanecem avisos herdados, inclusive em scripts de referência. O smoke registra uma observação informativa: Coin Flip mudou para seleção durante o teste; seleção também foi exercitada separadamente. Não é falha.

Os testes legados de fidelidade escrevem em três caminhos fixos. O executor guardou seus bytes, executou-os e restaurou-os; `historical_restoration.json` confirma os três resultados como verdadeiros. Dados temporários e dados de usuário das execuções foram direcionados para esta pasta do jogo.

Tentativas intermediárias do teste novo falharam na tipagem da referência dinâmica V10 e nas expectativas do próprio harness: distinguir framebuffer de conteúdo da janela com letterbox, igualar pixel snapping e incluir o título antigo na região de comparação. Foram corrigidas no teste, mantendo asserções de paridade e correspondência com spawn. Logs anteriores estão preservados em `evidence/hud_next_*_attempt/` e resumos correspondentes. A execução final está em `evidence/hud_next/` e `next_summary.json`; os dois testes V11.2 finais aprovados constam em `focused_summary.json`, cujo resultado antigo de NEXT foi substituído, no consolidado, pelo de `next_summary.json`.

## Evidências visuais e reprodução

- [V10 de referência](evidence/hud_next/v10_reference_1000x700.png).
- [NEXT compacto, 1000×700](evidence/hud_next/next_initial_1000x700.png).
- [C4 P1](evidence/hud_next/next_c4_p1_1000x700.png) e [C4 P2](evidence/hud_next/next_c4_p2_1000x700.png).
- [1280×896](evidence/hud_next/next_1280x896.png), [janela 1280×900](evidence/hud_next/next_1280x900.png), [janela 1600×900](evidence/hud_next/next_1600x900.png).
- C4 com relógios visuais 0/7: `evidence/hud_next/c4_clock_0.png` e `c4_clock_7.png`.
- Cada captura do NEXT tem detalhes `_p1.png`/`_p2.png`. A visão geral e detalhes de C4 foram inspecionados visualmente. Capturas da integração real com sessão também estão nas baterias `character_select_ui` e `match_flow_visual`.
- [Resumo consolidado](summary.json); logs, comandos e JSONs por bateria em `evidence/`.

Na raiz do jogo, usando o executor local desta entrega:

```powershell
python -B relatorios/v11_3/run_validation.py next
python -B relatorios/v11_3/run_validation.py focused
python -B relatorios/v11_3/run_validation.py regression
python -B relatorios/v11_3/run_validation.py checks
```

As referências `.txt` são evidências derivadas: se ausentes, o executor as recupera de `git show v0.10.0:godot/presentation/<arquivo>`, sem modificar refs. O teste NEXT depende dessas referências e de `PF_REPORT`, configurado pelo executor. Uma nova execução substitui os artefatos de mesmo nome; preserve esta evidência antes de repetir. O `.gitignore` existente mantém logs, imagens e o executor local de relatórios ignorados; nenhum arquivo foi preparado para commit.

## Limites e pendências

A validação técnica solicitada está demonstrada; resta a revisão visual do coordenador sobre a referência C provisória. Não há necessidade de mudança no núcleo para este NEXT.

A geração dentro de `_draw()` continua sendo a dívida V10 explicitamente preservada: não foi removida, adiantada ou chamada mais vezes. O teste de paridade usa o resolvedor imediato para provar identidade da dupla; a regressão temporal cobre as mecânicas quadro a quadro. Não foram executadas novamente as 1.000 séries históricas, as 80 comparações de máscaras MAME, coleta nova no MAME, periférico físico nem exportação de binário. Não se declara fidelidade visual integral ao arcade.

WARNING/contador, ENVIADAS, nickname, patente, histórico e ampliação dos poços seguem fora desta etapa. Os riscos de fonte de dados já registrados na V11.2 continuam válidos para essas futuras funcionalidades.
