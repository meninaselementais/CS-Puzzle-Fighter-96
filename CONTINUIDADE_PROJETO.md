# Continuidade — V10.3.4 auditada em 03/11/2026

**V10.3.4 concluída no escopo temporal/estrutural documentado; checkpoint aguarda autorização.** Esta atualização substitui o estado corrente dos textos históricos abaixo. A retomada da V10.3.4 foi expressamente autorizada pelo usuário nesta sessão.

- Branch `feature/v10-gem-physics`, HEAD `70a52c58017d9560043d9a3f463edd01ff8816fd`, preservados. Preparação seletiva no índice autorizada pelo usuário; sem commit ou push.
- Implementação do DeepSeek aproveitada, incluindo os 12 sprites preservados. Corrigidos os relógios por região no crescimento e nas duas etapas da união, o recorte do perímetro e o comparador insuficiente.
- Power: 394 checks; confronto MAME: 1.192/1.192 amostras de células; estrutura: 181 pares de capturas/1.407 checks, sem falhas.
- V10.3.2: 123.863 checks; V10.3.3: 119.052; física V10.2: 112 casos/14.072 amostras; cadeias: 22 casos/5.066 amostras/54 checks. Todos aprovados.
- Suíte existente 17/17 PASS, incluindo regras, controles/RNG, 119 fixtures naturais, Coin Flip e seleção. Quatro partidas integradas headless (dez rounds/204 checks) e quatro em janela (dez rounds/276 checks) aprovadas.
- O teste gráfico histórico envia confirmação cedo demais; adaptador `test_match_flow_visual_v10_3_4.gd` aguarda a janela real. Jogo e teste histórico intactos; falha original registrada.
- Núcleo, main.gd, fixtures e testes anteriores à V10.3.4 preservados. Lint: zero erros/11 avisos herdados; validação nativa: zero erros/73 avisos, os mesmos do checkpoint em cópia isolada.
- Ler `relatorios/v10_3_4/RELATORIO_V10_3_4.md` e `summary.json`. Evidências selecionadas em `revalidacao_codex/`; coleção integral e backup DeepSeek na entrega externa `C:\Users\MauTrIX\Documents\Codex\2026-11-03\continuar-counter-strike-puzzle-fighter-96\outputs\v10_3_4`.
- Não declarar fidelidade visual integral: overlays CS não copiam pixels nativos. Não certificados todos os casos de P2, cores/geometrias/velocidades ou partidas naturais completas. Limitações anteriores de explosões permanecem.

**Próxima ação:** análise do usuário e autorização explícita para registrar checkpoint. Não fazer commit/push, merge/rebase, tag v0.10.0, alterações do núcleo ou iniciar V11 por inferência.

---

## Histórico preservado — conteúdo anterior à retomada V10.3.4

O texto abaixo é histórico; declarações de HEAD, estado limpo e autorizações antigas não descrevem o estado corrente acima. Cópia byte a byte anterior em `deepseek_preserved/CONTINUIDADE_PROJETO.md` da entrega externa.

# Continuidade — Counter-Strike Puzzle Fighter '96

Atualizado em **03/11/2026**, America/Sao_Paulo, após conclusão e regressão da **V10.3.3**. **V10.3.1, V10.3.2 e V10.3.3 concluídas** conforme as evidências disponíveis. Checkpoint Git local executado em 03/11/2026 — `dde581f`. **V10.3.4 ainda não autorizada.**

## Estado atual

- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`.
- Branch: `feature/v10-gem-physics`.
- HEAD local: `dde581fa9f7e9cf5217297173a5043b40f9597af` (`dde581f`), `checkpoint: V10.3.1-V10.3.3 gem physics and visual fidelity`, 03/11/2026 00:51, sobre a base `136238edf12b68761d72713b2225de9363e6ba94`. Árvore de trabalho limpa.
- Remoto `origin`: `https://github.com/mautrix666/CS-Puzzle-Fighter-96.git`. A branch remota `feature/v10-gem-physics` está em `136238e`; `dde581f` **não existe no GitHub remoto**. Branch local **à frente da remota em 1 commit**. `main` remota em `03cfd1e`. Nenhum push, merge ou staging realizado.
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

**Próxima ação: nenhuma de código autorizada. O checkpoint local autorizado foi concluído (`dde581f`); a V10.3.4 continua sem autorização de implementação.** O commit `dde581f` permanece apenas local: push, merge, rebase e publicação não foram autorizados. Não avançar à V10.3.4, alterar o núcleo, editar testes para acomodar resultados nem publicar alterações por inferência. Não houve merge, push ou staging. Ao retomar, conferir Git, hashes e eventuais mudanças posteriores antes de escrever.

## Checkpoint local autorizado — 03/11/2026

Após aprovação da V10.3.3, a auditoria e a validação final dos 90 caminhos foram analisadas pelo usuário. Foi autorizado um único checkpoint local na branch `feature/v10-gem-physics`, sobre a base auditada `136238edf12b68761d72713b2225de9363e6ba94`, com a mensagem `checkpoint: V10.3.1-V10.3.3 gem physics and visual fidelity`.

A seleção contém exclusivamente os 90 caminhos auditados, incluindo `.gitattributes` para preservar os bytes das adições e evidências textuais. As versões históricas da continuidade permanecem intactas. Nenhuma ROM, dump, captura, ferramenta externa ou cache foi incluído. O núcleo competitivo e os testes anteriores permanecem preservados.

A validação em cópia isolada, sem laboratório ou ferramentas locais, aprovou 20/20 execuções. As cadeias funcionam sem dumps (22 casos/5.066 amostras/10 checks); os 44 checks adicionais de integridade dependem das RAMs locais. Permanecem documentados os caminhos locais das ferramentas históricas, as dependências externas dos comparadores e o aviso de duas instâncias ObjectDB no encerramento do teste de partidas.

O plano V10.3.4 limita-se às animações internas de Power Gems e continua separado da implementação. Não iniciar essa versão automaticamente. Push, merge, rebase, reset, alterações do núcleo e exclusão de evidências não foram autorizados. O resultado e o hash deste checkpoint devem ser consultados no Git e no relatório externo em `outputs/checkpoint_local_v10_3_3`, preservando este documento como conteúdo do próprio commit.

### Resultado do checkpoint — confirmado em 03/11/2026

O checkpoint foi **executado e confirmado** no Git local: commit `dde581fa9f7e9cf5217297173a5043b40f9597af` (`dde581f`), mensagem `checkpoint: V10.3.1-V10.3.3 gem physics and visual fidelity`, autor MauTrIX, 03/11/2026 00:51, parent `136238e`. A árvore de trabalho está limpa. Este documento foi atualizado após o commit e, por isso, aparece como alteração local pendente até um próximo checkpoint autorizado.

Verificação remota (somente leitura): `refs/heads/feature/v10-gem-physics` no `origin` aponta para `136238e`; `refs/heads/main` aponta para `03cfd1e`. Consequentemente, `dde581f` **não existe no GitHub remoto** e a branch local está **1 commit à frente** da remota. Nenhuma operação de escrita remota foi feita.
