# Correções finais da V10 — complemento da auditoria

Data: 04/11/2026, America/Sao_Paulo. Projeto `C:\Projetos\CS-Puzzle-Fighter-96`.
Branch `feature/v10-gem-physics`; HEAD preservado `4575f17a706d91df3ff009fb8b4d96d0cba06699`.

## 1. Problemas e causas

1. `godot/tests/test_gem_timeline.gd`: sucesso dependia apenas de `matching == total`. Uma fixture externa com `{"cases":[]}` satisfazia `0 == 0`, imprimia `cases=0/112 samples=0/0` e encerrava com código 0. O número 112 era somente apresentado no relatório. Assertions e acesso direto ao JSON também não ofereciam uma rejeição explícita e consistente de arquivos inválidos.
2. `godot/tests/test_power_facet_capture_v10_3_4.gd`: uma lista `[]` não executava nenhuma verificação; `failures.is_empty()` aprovava `checks=0 captures=0`. Não havia contrato de cobertura, validação prévia de metadados ou proteção suficiente antes do acesso a pixels.
3. `scripts/validar_fluxo_partidas.py --visual`: selecionava o teste histórico, que confirma após aproximadamente 0,1 s de revelação. `coin_flip.gd` aceita confirmação a partir de 0,2 s depois dos 1,5 s de giro. O adaptador existente espera mais 0,25 s depois da captura `*_coin_result`, herdando integralmente as verificações e os inputs históricos. A diferença está exclusivamente na sincronização da automação.

Os dois falsos positivos foram reproduzidos antes da correção usando JSONs sintéticos em `work/probes`, com saída 0. Nenhuma fixture foi ajustada para obter aprovação.

## 2. Arquivos modificados nesta sessão

- `godot/tests/test_gem_timeline.gd`.
- `godot/tests/test_power_facet_capture_v10_3_4.gd`.
- `scripts/validar_fluxo_partidas.py`.
- `tests/test_validadores_v10.py` — novo.
- `relatorios/v10_final/RELATORIO_CORRECOES_FINAIS_V10.md` — este relatório novo.
- `CONTINUIDADE_PROJETO.md` — novo estado corrente acrescentado, histórico preservado.

README e arquitetura já modificados na abertura foram preservados byte a byte. Os relatórios anteriores, inclusive os não rastreados, foram preservados. Não foram alterados `main.gd`, Coin Flip, núcleo físico, RNG, controles ou fixtures. O teste histórico e o adaptador existente permanecem idênticos aos recebidos.

## 3. Correções

O validador físico exige os 112 identificadores esperados da matriz auditada, sem duplicatas, com a quantidade de amostras de cada cenário e o total 14.072. Exige frames contíguos desde zero, campos inteiros válidos e tabuleiros de 84 células hexadecimais. Verifica arquivo, RAM inicial de 65.536 bytes, SHA-256 e abertura da saída. Qualquer erro de entrada encerra com código 1 e mensagem `GEM_TIMELINE input:`. A aprovação final exige também 112 cenários aprovados e todas as 14.072 amostras coincidentes.

O validador estrutural exige os 181 pares cenário/frame: `power_2x2` 1–65, `power_growth` 35–90 e `power_union_5x2` 35–94, sem duplicatas. Valida 84 idades inteiras por registro e regiões retangulares dentro do tabuleiro; exige manifesto válido, imagens existentes e pares legíveis de 1000×700 antes de ler pixels. Erros encerram com código 1 e mensagem `POWER_FACET_CAPTURE input:`. A comparação diferencial de facetas, perímetro e células ativas permanece em vigor.

O executor usa `test_match_flow_visual_v10_3_4.gd` para `--visual` e `--movie`. O lote headless continua com `test_match_flow.gd`. Não há mudança de tempo no jogo. A seleção nos três modos está coberta por teste com subprocesso simulado; a execução real em janela foi realizada separadamente. Não foi gravado novo AVI.

## 4. Testes executados e comparação

| Verificação | Auditoria anterior | Nova execução |
|---|---:|---:|
| Python | 17 testes | 28/28, incluindo 11 novos métodos com subcasos |
| Baterias existentes, incluindo render/UI | 17/17 | 17/17 |
| Física | 112 casos / 14.072 amostras | 112/112 / 14.072/14.072 |
| Combos / Counter Gems | 22 casos / 5.066 amostras / 54 checks | mesmos totais, zero falhas |
| Fidelidade | 247/247 | 247/247 |
| Controles / RNG observado | 33/33 / 866 amostras | mesmos totais |
| Endpoints naturais | 119/119 | 119/119 |
| Regras | 34 checks | 34 checks |
| V10.3.2 | 123.863 checks | 123.863, zero falhas |
| Rotação orbital V10.3.3 | 119.052 checks | 119.052, zero falhas |
| Power V10.3.4 | 394 checks | 394, zero falhas |
| Estrutura Power, capturas novas | 181 pares / 1.407 checks | mesmos totais, zero falhas |
| Power × traços MAME preservados | 1.192 amostras de células | 1.192/1.192 |
| Séries integradas headless | 1.000 / 2.500 rounds / 51.000 checks | 1000 / 2500 / 51000 |
| Séries em janela com adaptador | 4 / 10 rounds / 276 checks / 30 PNGs | mesmos totais; executor corrigido |
| Teste gráfico histórico sem adaptador | falha na seleção | falha reproduzida, saída 1, preservado |
| Validação nativa | zero erros / 73 avisos | zero erros / 73 avisos |
| Lint estático | zero erros / 11 avisos | mesmos totais |
| Smoke de cenas | quatro aprovadas | 4/4, zero erros |

Coin Flip: 40.195 checks aprovados; seleção, transições de rounds e retorno a novo sorteio também passaram. Os testes de controles incluem eventos automatizados de teclado/gamepad; não houve ensaio de periféricos físicos.

O lote durou 309.391 s, contra 312,828 s na auditoria anterior; a janela durou 34.609 s. Os contadores funcionais coincidem. A duração é uma diferença de execução, com renderização/regressões concorrentes neste ambiente; não foi feito benchmark isolado para atribuir a diferença ao jogo.

Os novos testes rejeitam entradas vazias, JSON inválido, arquivos/argumentos ausentes, cenários/amostras/capturas incompletos ou duplicados, cenários desconhecidos, tipos inválidos, frames inválidos, tabuleiros inválidos, RAM ausente/hash incorreto, saída indisponível e PNGs inválidos ou com dimensões erradas. Também verificam que uma divergência física real e imagens sem facetas falham, enquanto os conjuntos completos continuam passando. Alterações sintéticas são restritas a temporários.

## 5. Falhas observadas e resolvidas durante a execução

A primeira rodada dos testes novos apontou que o diretório histórico Power escolhido como entrada tinha metadados antigos sem `ages` e não tinha imagens base. A preparação foi corrigida para gerar um conjunto completo novo, a partir do renderizador existente. Os arquivos históricos ficaram intactos. Um PNG de 1×1 inicialmente usado como dado negativo tinha CRC inválido; o teste foi corrigido para produzir um PNG válido com a biblioteca padrão e verificar especificamente dimensões. Esses ensaios intermediários estão registrados; o primeiro resumo de regressão mantém a falha Python original e é substituído, para o veredito atual, por `python_final_execution.json` e `summary_final.json`.

Estado final: 27/27 execuções principais aprovadas, considerando a reexecução Python final. A única falha mantida é a reprodução deliberada do teste gráfico histórico. Os retornos 1 dos casos negativos são o resultado esperado, verificado pelos testes.

O smoke registra 102 avisos acumulados nas quatro execuções de cenas, com repetições, e uma informação `scene_changed`: Coin Flip mudou para seleção durante o fuzz, e a seleção também foi exercitada separadamente. Esse total não é o inventário único de 73 avisos da validação nativa. Não foram suprimidos avisos para aprovar a regressão.

## 6. Evidências, reprodução e preservação

Coleção desta sessão: `C:\Users\MauTrIX\Documents\Codex\2026-11-04\continuar-counter-strike-puzzle-fighter-96\outputs\v10_correcoes_finais`. `summary_final.json` é o resumo corrente; cada bateria tem logs próprios, e as execuções principais têm `execution.json`. Inclui `python_final.log`, `resources_final.json`, `smoke.json`, `historical_preservation.json`, `preservation_final.json`, `git_final.txt`, capturas Power e as 30 imagens do fluxo visual. `regression_summary.json` e o log Python da primeira rodada são intermediários preservados, não o veredito final.

Comandos centrais, sempre com pastas novas:

```powershell
python -B -m unittest discover -s tests -v
python scripts/validar_fluxo_partidas.py --matches 1000 --workers 4 --output <saida_nova>
python scripts/validar_fluxo_partidas.py --visual --output <saida_nova>
# Godot com --path godot e --script:
# res://tests/test_gem_timeline.gd -- --fixtures=<fixture_fisica> --out=<novo_json>
# res://tests/test_chain_counter_timeline.gd -- --out=<novo_json>
# res://tests/test_visual_timeline_v10_3_2.gd
# res://tests/test_pair_rotation_visual_v10_3_3.gd
# res://tests/test_power_facet_v10_3_4.gd
# res://tests/render_power_facet_v10_3_4.gd (janela; PF_REPORT=<saida_nova>)
# res://tests/test_power_facet_capture_v10_3_4.gd -- <saida_nova>/render
```

Os testes Python novos geram capturas Power em temporário se `PF_POWER_CAPTURE` não for fornecido. Nesta execução, essa variável apontou para as novas capturas desta coleção, evitando repetir a mesma renderização. O Godot portátil e as fixtures físicas/RAMs locais são dependências reais: a falta delas causa falha, não aprovação nem skip silencioso.

Antes das alterações, 451 caminhos rastreados/não ignorados receberam SHA-256. A conferência identifica somente os três arquivos de código e a continuidade como mudanças em caminhos já existentes; os demais 447 permanecem idênticos. Novos teste e relatório são listados separadamente. Os três relatórios históricos de destino fixo regravados pelas baterias foram copiados para evidências atuais e restaurados byte a byte. Os manifestos, originais de trabalho e estado inicial estão em `work/`; a entrega contém o resultado de preservação. Relatórios anteriores não foram apagados.

## 7. Limitações e recomendação de publicação

**Recomendo a publicação de v0.10.0 como versão funcional do duelo local no escopo auditado. As três pendências de validadores/executor foram corrigidas e não apareceu regressão funcional nas execuções realizadas.** Publicação, tag e checkpoint aguardam autorização do usuário.

Mantêm-se os limites anteriores: sem certificação de RNG completo/consumidores globais CPS-2, equivalência integral de RAM/RGB/explosões, todas as geometrias/P2, MAME novo, outras plataformas, periféricos físicos ou binário exportado novo. A rotação foi revalidada por sua suíte de 119.052 checks; não foram refeitos nesta sessão os 340 pares de capturas e o comparador de 80 máscaras MAME, cujos resultados permanecem históricos. O confronto Power usa coletas MAME existentes, não uma nova coleta.

As 1.000 séries integradas usam top-out controlado por fixtures; não equivalem a 1.000 partidas naturais sincronizadas ao arcade. Os 119 endpoints naturais são uma bateria separada. Os 73 avisos nativos herdados permanecem documentados.

## 8. Git e próxima ação

Branch e HEAD permanecem os informados acima; `main` permanece em `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`. Índice vazio. Mudanças documentais e relatórios locais recebidos foram preservados, junto às correções novas. Não houve staging, commit, push, merge, rebase, reset, clean ou tag. V11 não foi iniciada.

Aguardar autorização explícita para registrar o checkpoint ou publicar a versão. O encerramento documental e a auditoria anteriores continuam preservados como registros do seu instante; este complemento registra o fechamento técnico das pendências.
