# Preparação do fechamento V9 / v0.9.0

Estado: pronto para revisão; commit, tag e push aguardam autorização expressa.

## Integridade e resultados

HEAD conferido: `2daf6aea9dc0992f2aa9bd81a26ffa8cae845490`. Nenhum arquivo rastreado estava modificado antes
desta preparação. `godot/`, `scripts/` e `tests/` continuam idênticos à base
validada. `source_sha256.json` registra 198 arquivos dessas pastas.
Os 76 arquivos do manifesto da validação visual foram conferidos
por SHA-256, sem divergências. A cópia do teste difere do original somente
pelo comentário e pela espera adicional de 0,22 segundo documentada.

Integração lógica preservada: 1.000 partidas, 2.500 rounds, 51.000 verificações.
Regressão preservada: fidelidade 247/247, controles 33/33, naturais 119/119,
regras 34/34, Python 17/17. Não são testes reexecutados nesta preparação.
Validação visual aprovada: 4 partidas, 10 rounds e 276 verificações.

## Problema conhecido

A tentativa original falhou ao pressionar Enter durante a guarda de 0,2 s
do resultado do Coin Flip. A cópia de validação espera mais 0,22 s após a
captura do resultado; passou sem modificar regras ou remover asserções.
O harness original permanece intacto e pode repetir a falha de tempo.
Logs da falha, inclusive o aviso de objetos vazados na saída antecipada,
e da execução aprovada estão incluídos. O relatório visual também preserva
os dez avisos estáticos de caminhos nas ferramentas antigas.

## Preservação dos bytes das evidências

`.gitattributes` desativa a conversão automática de fim de linha somente
nas evidências textuais selecionadas. Assim, os blobs preparados preservam
os bytes locais e os hashes do manifesto. Uma linha vazia final preexistente
na cópia do teste é mantida por integridade; a verificação de whitespace
desconsidera exclusivamente `blank-at-eof`, sem alterar o arquivo validado.

## Escopo de publicação

Somente os arquivos de texto listados abaixo são preparados. Nenhuma ROM,
dump, estado de emulador, credencial, executável, imagem, áudio ou outro
recurso proprietário é acrescentado ao commit. Capturas, ferramentas e
userdata permanecem no disco. O manifesto contém hashes e nomes, não os
conteúdos de mídia. Os relatórios de lógica existentes já versionados são
mantidos e os logs selecionados acrescentam evidência textual.

Esta conferência cobre o novo commit proposto. Não certifica a licença dos
assets já presentes no histórico; não há autorização de push nesta etapa.
Uma publicação do histórico existente exige considerar seu conteúdo prévio.

## Plano após autorização

Mensagem proposta: `chore: encerra validacao da V9 e documenta evidencias`.
Tag anotada proposta: `v0.9.0`, no novo commit de fechamento.
Mensagem da tag: `V9: validacao logica e visual Windows concluida; ver README para limites e temporizacao do harness`.
Nenhum commit, criação de tag ou push foi executado nesta preparação.

## Arquivos preparados (40)

- `.gitattributes`
- `.gitignore`
- `README.md`
- `relatorios/rounds_integration/bulk/worker_1/console.log`
- `relatorios/rounds_integration/bulk/worker_2/console.log`
- `relatorios/rounds_integration/bulk/worker_3/console.log`
- `relatorios/rounds_integration/bulk/worker_4/console.log`
- `relatorios/rounds_integration/regression/python.log`
- `relatorios/rounds_integration/regression/test_controls_fidelity.log`
- `relatorios/rounds_integration/regression/test_fidelity.log`
- `relatorios/rounds_integration/regression/test_natural_fidelity.log`
- `relatorios/rounds_integration/regression/test_rules.log`
- `relatorios/rounds_integration/visual_final_v9/FECHAMENTO_V9.md`
- `relatorios/rounds_integration/visual_final_v9/RELATORIO_FINAL_V9.md`
- `relatorios/rounds_integration/visual_final_v9/four_matches/console.log`
- `relatorios/rounds_integration/visual_final_v9/four_matches/engine.log`
- `relatorios/rounds_integration/visual_final_v9/four_matches/integration_summary.json`
- `relatorios/rounds_integration/visual_final_v9/four_matches/matches.ndjson`
- `relatorios/rounds_integration/visual_final_v9/four_matches/summary.json`
- `relatorios/rounds_integration/visual_final_v9/four_matches_retry/console.log`
- `relatorios/rounds_integration/visual_final_v9/four_matches_retry/engine.log`
- `relatorios/rounds_integration/visual_final_v9/four_matches_retry/integration_summary.json`
- `relatorios/rounds_integration/visual_final_v9/four_matches_retry/matches.ndjson`
- `relatorios/rounds_integration/visual_final_v9/four_matches_runner.log`
- `relatorios/rounds_integration/visual_final_v9/git_status_final.txt`
- `relatorios/rounds_integration/visual_final_v9/lint_before.json`
- `relatorios/rounds_integration/visual_final_v9/manifest_sha256.json`
- `relatorios/rounds_integration/visual_final_v9/render_mechanics.log`
- `relatorios/rounds_integration/visual_final_v9/render_mechanics_engine.log`
- `relatorios/rounds_integration/visual_final_v9/render_preview.log`
- `relatorios/rounds_integration/visual_final_v9/render_preview_engine.log`
- `relatorios/rounds_integration/visual_final_v9/source_sha256.json`
- `relatorios/rounds_integration/visual_final_v9/targeted_summary.json`
- `relatorios/rounds_integration/visual_final_v9/test_art_v9.log`
- `relatorios/rounds_integration/visual_final_v9/test_art_v9_engine.log`
- `relatorios/rounds_integration/visual_final_v9/test_character_select_ui.log`
- `relatorios/rounds_integration/visual_final_v9/test_character_select_ui_engine.log`
- `relatorios/rounds_integration/visual_final_v9/test_match_flow_windows.gd`
- `relatorios/rounds_integration/visual_final_v9/test_models.log`
- `relatorios/rounds_integration/visual_final_v9/test_models_engine.log`
