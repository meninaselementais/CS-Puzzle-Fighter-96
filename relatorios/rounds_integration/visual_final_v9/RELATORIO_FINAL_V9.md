# Validação visual final V9 — Windows

**Conclusão: V9 pronta para fechamento quanto às pendências de validação visual no Windows.**

Execução concluída em 2026-10-31T23:24:02-03:00. Projeto existente: `C:\Projetos\CS-Puzzle-Fighter-96`. Commit base: `2daf6aea9dc0992f2aa9bd81a26ffa8cae845490`. Git inicialmente limpo; ao final, somente esta pasta de relatórios está sem rastreamento. Nenhum arquivo rastreado foi alterado, nenhum commit ou push realizado e V10 não iniciada.

## Ambiente e procedência

Godot 4.7.2 stable oficial `ed1daf0bf`, Windows, execução gráfica sem `--headless`, OpenGL 3.3 Compatibility, NVIDIA GeForce RTX 5070, driver 591.86. Os arquivos `Validar V9 Windows.bat` e `Checklist V9 Windows.md` não foram encontrados na busca recursiva do projeto; foram usados os testes existentes.

`godot/data/replay_mame.json`: 1132700 bytes, SHA-256 `e7628c8629e0ec7a0ce47476c0771524c67f639ac195f825b5ed3c7741a48f42`. Igual byte a byte ao replay original de `relatorios/automacao_20261028_consolidada/replay_mame.json`. Sem substituição ou regeneração.

## Testes realmente executados

| Teste | Resultado | Evidência |
|---|---|---|
| `test_models.gd` com replay original | PASS, limites, colisão, assentamento, dois tabuleiros e geometria MAME | `test_models.log` |
| `test_art_v9.gd` | PASS, 102 verificações | `test_art_v9.log` |
| `render_preview.gd` | PASS, replay renderizado | `prototipo_godot.png` |
| `render_mechanics.gd` | PASS, controles P1/P2, rotação, reinício, replay e três cenários | `render_mechanics.log`, `demo_visual_cps2_*.png` |
| `test_character_select_ui.gd` | PASS, 12 capturas, teclado e eventos de gamepad, lados invertidos, confirmações, três rounds, novo sorteio e duas dimensões de janela | `test_character_select_ui.log`, capturas `01_` a `12_` |
| Quatro partidas gráficas, tentativa original | FAIL na transição Coin Flip → seleção; 0 partidas completas, 8 verificações | `four_matches/` |
| Quatro partidas gráficas, cópia com espera corrigida | PASS, **4/4 partidas, 10 rounds, 276 verificações, zero falhas** | `four_matches_retry/integration_summary.json`, `matches.ndjson`, `engine.log` |

As quatro séries concluídas foram CT 2×0 TR, CT 0×2 TR, CT 2×1 TR e CT 1×2 TR. O teste verificou manutenção de equipes/personagens/padrões entre rounds, contagem única de vitória, limpeza dos tabuleiros e efeitos, terceiro round após 1×1, encerramento em duas vitórias e novo sorteio local seguido de retorno à seleção.

## Inspeção visual e capturas reais

Dust2, Mirage e Inferno foram renderizados com os assets originais e inspecionados nas capturas: fundos distintos, dois tabuleiros, personagens, gemas, efeitos, placares e textos visíveis, sem quadro vazio ou recurso ausente aparente. Também foram inspecionadas as imagens de 1×1, início do terceiro round, vitória 2×0 e vitória 2×1, coerentes com os registros de sessão.

`janela_godot_partida.png` e `janela_godot_serie.png` são capturas da **janela nativa do Windows com barra de título**, obtidas pelo controle de janela durante a bateria. As demais imagens são capturas do framebuffer real do Godot em execução gráfica, não montagens. A série aprovada gerou 30 imagens de framebuffer.

## Falha identificada e tratamento

O teste original espera 0,4 + 1,2 segundos antes de pressionar Enter. A moeda revela em 1,5 segundo, mas `coin_flip.gd::skip()` somente continua após 1,7 segundo. Assim, Enter pode chegar durante a guarda de 0,2 segundo e a asserção seguinte encontra a cena da moeda. Isso ocorreu nesta máquina. A primeira tentativa e seu aviso de objetos vazados durante a saída antecipada foram preservados em `four_matches/`.

Para validar o fluxo sem mudar originais, foi salva `test_match_flow_windows.gd` nesta pasta: cópia integral do teste com **uma espera adicional de 0,22 segundo após a captura do resultado da moeda** e um comentário explicativo. Não foram removidas asserções nem alteradas regras. Essa cópia foi executada com `--script <caminho absoluto> -- --visual` e `PF_REPORT` apontando para `four_matches_retry`. O teste original continua sujeito a essa falha de temporização; para reproduzir o resultado aprovado, use a cópia anexada.

As execuções finais aprovadas não apresentaram `ERROR`, `SCRIPT ERROR` ou `WARNING` nos logs. A análise estática suplementar retornou zero erros e dez avisos de caminhos `res://../...` em ferramentas/capturas antigas (`lint_before.json`); não são avisos das execuções gráficas e não impediram carregar o jogo ou os assets testados. Não houve alterações de código do jogo.

## Limites e fechamento

As séries automatizadas usam fixtures de top-out acionadas pelo resolvedor original para controlar os vencedores; não representam quatro partidas naturais completas. Eventos de gamepad foram simulados pelo teste, sem validação de controle físico. Os resultados Linux de 1.000 partidas informados pelo Muse não foram repetidos nem contabilizados como execução desta sessão. Não foi feita nova sincronização integral com o MAME.

Todas as pendências visuais solicitadas foram exercitadas e aprovadas na repetição documentada. **V9 pronta para fechamento**, com a ressalva registrada sobre a temporização do harness original. Preservar a cópia de teste corrigida junto às evidências.
