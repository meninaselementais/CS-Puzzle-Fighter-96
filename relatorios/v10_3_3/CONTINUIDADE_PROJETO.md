# Continuidade — Counter-Strike Puzzle Fighter '96

Atualizado em **03/11/2026**, America/Sao_Paulo, após conclusão e regressão da **V10.3.3**. Entrega aguardando análise do usuário. **V10.3.4 não iniciada.**

## Estado atual

- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`.
- Branch: `feature/v10-gem-physics`.
- HEAD: `136238edf12b68761d72713b2225de9363e6ba94`; permanece o checkpoint V10.2 publicado informado anteriormente. Nenhuma consulta remota nesta retomada.
- V10.3.1: medições concluídas no escopo P1 documentado.
- V10.3.2: implementação temporal local concluída, preservada.
- V10.3.3: rotação gráfica de oito passos integrada, validada e documentada no escopo medido. Alterações locais, **sem staging, commit, merge ou push**.

## Ler primeiro

1. `relatorios/v10_3_3/RELATORIO_V10_3_3.md`.
2. `relatorios/v10_3_3/comparacao_rotacao_summary.json`, `comparacao_rotacao_mame.csv` e `capture_masks.json`.
3. `relatorios/v10_3_3/verificacao_final.json`, `preservacao_final.json` e manifestos.
4. `relatorios/v10_3_3/COMPARACAO_VISUAL.html` para inspeção dos PNGs originais.
5. Relatórios V10.3.2 e V10.3.1/suplemento para limites anteriores e fontes.

A continuidade anterior, que ainda declarava V10.3.3 não iniciada, está preservada em `relatorios/v10_3_3/CONTINUIDADE_PROJETO.md.antes.txt`. Esse texto é histórico e não descreve mais o estado atual.

## Implementação e preservação

`godot/presentation/pair_rotation_visual.gd` observa snapshots antes/depois dos ticks, mantém contador/direção/deslocamento visual e desenha a dupla. Usa os valores discretos medidos nas tabelas `$12DA0/$12D00`, sem interpolação inventada. A ponte em `godot/presentation/main.gd` atualiza os dois observadores depois do tick e limpa o estado em reinício/transição de replay.

O componente não fornece geometria ao modelo. Colisões, contato, depósito e regras continuam no núcleo. `match_model.gd` e todos os arquivos em `godot/core/` permanecem intactos. A arena conserva exatamente a implementação V10.3.2. Nenhum teste anterior foi modificado. Foram conferidos **782 hashes de arquivos preservados**, sem divergências.

A retomada de 03/11 encontrou a integração já pronta e concluiu as análises/testes pendentes; não precisou alterar a implementação. Acrescentou validadores finais e documentação.

## Resultados revalidados

| Verificação | Resultado |
|---|---|
| V10.3.3 | 119.052 verificações, zero falhas; 80/80 passos principais; 11.957 amostras ativas |
| PNGs Godot × MAME | 80/80 pares, zero pixels divergentes de máscara |
| Oclusão | 36 quadros/268 pixels sobrepostos, identidade/ordem corretas em ambos |
| Capturas V10.3.3 | 340 pares imagem/fundo, zero máscaras inválidas; 26 capturas em fase sem dupla ativa |
| Resíduos nativos | 304 amostras inativas e 52 amostras de nascimento verificadas; nenhum resíduo transferido |
| V10.3.2 | 123.863 verificações, zero falhas |
| Suíte existente com render/UI | 17/17 baterias aprovadas |
| Física e cadeias | 112 casos/14.072 amostras e 22 casos/5.066 amostras/54 verificações aprovados |
| Partidas integradas | 4/4 partidas, 10 rounds, 204 verificações |
| Cena V10.3.2 atual | 172 PNGs recapturados; 20 comparações de contato e quatro de queda, zero pixels divergentes |
| Lint | Zero erros e os mesmos 11 avisos preexistentes de caminhos |

Os 340 registros V10.3.3 e seus testes gráficos de ponte real/pausa/reinício/dois jogadores já existiam no ponto de parada e foram inspecionados. A validação de suas máscaras foi executada nesta retomada; os demais testes da tabela foram reexecutados. Não confundir inspeção dos registros anteriores com uma nova coleta.

## Contratos importantes

- Oito passos: contador 7..0, incluindo alinhamento final. Quatro orientações, dois sentidos e dois casos de corredor medidos.
- Alinhamento destes PNGs: **Godot F ↔ bitmap MAME F+1**. CPU e RAM de `frame_done` têm índices distintos do bitmap. Não deslocar a física para corrigir captura.
- Comparação é de máscara/oclusão, com escala normalizada; não de RGB entre as artes CS e arcade. O halo é separado da máscara do corpo.
- No corredor as cores do pivô/satélite trocam: o comparador deve acompanhar a fixture, sem assumir identidade de cor fixa.
- Contato 15..2 permite rotação e 16/1 bloqueia nas condições ensaiadas. O componente acompanha a decisão do núcleo.
- Fase inativa, identidade nova, descontinuidade e reinício cancelam resíduos. Pausa, desenho e observação duplicada não avançam o contador.
- A RAM MAME pode retomar contador antigo no nascimento; a V10.3.3 **deliberadamente descarta esse resíduo**, conforme exigido pelo usuário. Não exigir igualdade com essa RAM obsoleta.

## Fontes e arquivos locais

Reutilizadas as coletas MAME já comprovadas: matriz primária `laboratorio/auto_20261101_222825_850720`, repetição `auto_20261101_222903_899708`, suplemento `auto_20261102_172410_209057`/`auto_20261102_172448_482209` e fixtures históricas de contato/cadeias. As fontes estão identificadas por hash nas fixtures/manifestos. Nenhuma coleta nova, execução MAME ou repetição das 1.000 partidas históricas foi necessária.

Preservar também arquivos ignorados: laboratório, capturas, ferramentas, fontes e relatórios históricos. O Git normal não os enumera integralmente. Não executar clean/reset nem apagar diretórios ignorados.

Dados e testes novos da rotação: `godot/data/pair_rotation_v10_3_3.json`, `godot/tests/rotation_fixture_v10_3_3.gd`, `test_pair_rotation_visual_v10_3_3.gd`, `render_pair_rotation_v10_3_3.gd`; preparação em `scripts/preparar_fixtures_rotacao_v10_3_3.py`. Validadores finais: `scripts/comparar_rotacao_v10_3_3.py` e `scripts/validar_capturas_rotacao_v10_3_3.gd`. Comandos no relatório final.

Cópia para o usuário: `C:\Users\MauTrIX\Documents\Codex\2026-11-03\continuar-v10-3-3-counter-strike\outputs\v10_3_3`.

## Limites e próxima ação

Não declarar fidelidade visual integral: a arte CS difere, Power/explosões mantêm limites internos registrados na V10.3.2, e não foram certificados todos os casos de P2, cores, geometrias ou partidas naturais completas. Os avisos preexistentes de lint continuam documentados.

**Próxima ação: o usuário analisa a V10.3.3 e suas evidências.** Não avançar à V10.3.4, alterar o núcleo, editar testes para acomodar resultados nem publicar alterações por inferência. Não houve commit, merge, push ou staging. Ao retomar, conferir Git, hashes e eventuais mudanças posteriores antes de escrever.
