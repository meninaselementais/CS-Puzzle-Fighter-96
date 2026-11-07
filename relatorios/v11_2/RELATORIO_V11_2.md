# Relatório de encerramento documental — V11.2 (camada de leitura de dados do HUD)

Data: 05/11/2026 (America/Sao_Paulo). Branch `feature/v11-hud`. Base `v0.10.0`, commit `1a943a4db4d1dba84a222735187afb6108b4c4c5`.

**Escopo deste documento:** encerramento apenas documental. Nenhum código, teste, fixture ou arquivo de regra foi alterado. Não houve commit, push, tag, merge ou rebase.

## 0. Como ler as evidências

| Tipo | Quem | Quando | Natureza |
|---|---|---|---|
| **A. Execuções do Codex** | Codex | 05/11, 01:10–01:13 | Testes realmente executados (Godot 4.7.2, Python). Registrados em logs. |
| **B. Verificações estáticas** | Claude | 05/11, sessão de retomada | Leitura de código, logs, datas de arquivo e arquivos de `.git`. **Nenhum teste foi executado pelo Claude.** |
| **C. Execuções manuais do usuário** | Usuário, no Windows | 05/11, 02:16–02:30 | Os seis testes pendentes, mais `git status`. Saídas em `C:\Projetos\validacao_v11_2\` (fora do repositório). O Claude apenas leu os logs (seção 7). |

Não havia terminal na sessão de retomada. O Claude não reexecutou testes e não rodou `git status`.

## 1. Arquivos que pertencem à V11.2

Novos, não rastreados, criados em 05/11 às 01:10 (únicos arquivos de código/teste com data posterior ao checkout da branch, às 00:40):

| Arquivo | Tamanho | Função |
|---|---|---|
| `godot/presentation/hud_presenter.gd` | 3.474 B | Projeção somente leitura dos dados do HUD |
| `godot/tests/test_hud_presenter.gd` | 10.649 B | 7 suítes, headless |
| `godot/tests/test_hud_presenter_scene.gd` | 3.675 B | Cena real, 1.000 consultas, comparação de framebuffer |

Documental desta etapa: `relatorios/v11_2/RELATORIO_V11_2.md` (este) e a entrada nova no topo de `CONTINUIDADE_PROJETO.md`.

Não pertencem à V11.2 (herdados de V11.0/V11.1/V10, preservados): `planejamento/V11_PLANO_HUD.md`, `planejamento/v11_1/*`, `relatorios/v10_3_4/revalidacao_codex/*`.

O presenter **não está ligado** a `main.gd` nem a `cs_arena.gd`; só os testes o usam.

Evidências do Codex ficam fora do repositório: `C:\Users\MauTrIX\Documents\Codex\2026-11-04\continuar-counter-strike-puzzle-fighter-96\outputs\v11_2\`.

## 2. A. Resultados das execuções do Codex (lidos dos logs)

20 de 20 execuções com `passed: true`; script concluiu e restaurou os históricos (`historical_restoration.json`, tudo `true`).

| Verificação | Resultado | Linha de base V10 |
|---|---|---|
| `test_hud_presenter` | 3.931 checks, 7 suítes, 0 falhas | novo |
| `test_hud_presenter_scene` | 1.013 checks, 1.000 consultas, framebuffer idêntico | novo |
| Física (`test_gem_timeline`) | 112/112 casos, 14.072/14.072 amostras | 112 / 14.072 |
| Cadeias e Counter Gems | 22 casos, 5.066 amostras, 54 checks | 22 / 5.066 / 54 |
| Controles e RNG | 33/33, 866 | 33 / 866 |
| Naturais | 119/119 | 119 |
| Regras | 34 checks | 34 |
| V10.3.2 temporal | 123.863 checks | 123.863 |
| V10.3.3 rotação | 119.052 checks (80 principais, 11.957 ativas) | idem |
| V10.3.4 Power | 394 checks | 394 |
| Coin Flip | 40.195 checks | — |
| Seleção / apresentação / duelo / modelos | 3.351 / 3.285 / 28 partidas e 227 ondas / OK | — |
| Python | 28 testes OK | 28 |
| Partidas headless | 40/40, 100 rounds, 2.040 checks | — |
| Partidas em janela | 4/4, 10 rounds, 276 checks | 4 / 10 / 276 |
| Lint | 0 erros, 11 avisos | 11 |
| Validação nativa | 0 erros, 73 avisos | 73 |
| Smoke | 4 cenas, 102 avisos acumulados | 102 |

A coluna "linha de base" foi comparada pelo Claude contra os números registrados na continuidade da V10; é conferência documental, não execução.

**Falha registrada:** a primeira rodada focada do Codex reprovou `hud_presenter` (exit 1) porque o teste atribuía `Array` a propriedades tipadas do modelo (`pending`, `pair_index`). O defeito era do teste, corrigido com `.assign(...)`; a segunda rodada passou. Nenhuma regra mudou. O teste foi salvo às 01:10:58, no mesmo segundo da execução aprovada; o arquivo atual contém a versão corrigida.

**Cobertura não repetida pela regressão do Codex:** `test_animation_v8`, `test_art_v9`, `test_showcase_ui`, `test_character_select_ui`; as 1.000 séries integradas; as 80 comparações gráficas de rotação.

## 3. B. Verificações estáticas do Claude

| Requisito | Resultado |
|---|---|
| Somente leitura | Sim. Nenhuma atribuição ao modelo ou à `Session`; `duplicate(true)` em `last_results` e `round_wins`. |
| Sem RNG, sem peças, NEXT não avança | Sim. Não chama `get_next_colors`; lê `stream[pair_index+1]` só se o índice existir. |
| Independência P1/P2 | Sim, cada slot lê só os próprios índices. |
| Dados sem fonte | Nickname, patente, id, vitórias de sessão e ataque enviado: `available=false` com motivo, nunca zero. |
| Ataque bruto × enviado | `generated_attack` é bruto; `sent_attack` é indisponível (`net_sent_attack_not_exposed`). |
| Núcleo, `main.gd`, RNG, controles intactos | Por data de arquivo: todos em 04/11 23:56:06 (fast-forward da `main`), anteriores à branch. Não é prova por hash. |
| Git | Pelo `.git`: ref da branch igual ao commit-base; sem commit após o checkout; tags só `v0.9.0` e `v0.10.0`; índice com data anterior à branch. |

## 4. Riscos identificados

### 4.1 `warning_for`
Reimplementa em `hud_presenter.gd` a regra de `CsArena.is_board_in_danger` (pending ≥ 6 ou qualquer célula nos índices 12..35, valores fixos no código). Há teste de paridade (pending 0, 1, 5, 6, 17, 18, 98, 99, 100, 250 e células 0, 11, 12, 35, 36, 83), mas são duas cópias. Se a arena mudar o critério, o presenter diverge sem aviso, a menos que o teste de paridade seja rodado. Não é defeito atual.

### 4.2 `generated_attack`
Vem de `last_results[player].attack`, que **persiste** depois do fim da resolução. Diferente de `combo`, não leva marca de escopo, e um leitor pode tomá-lo por evento atual. É ataque **bruto**: não representa o que entrou na fila do adversário depois de cancelamento e teto de 250. Não deve ser rotulado "ENVIADAS". A fonte exata do ataque aceito ainda não é exposta pelo núcleo.

### 4.3 Validação do NEXT
- O teste de cena compara o NEXT do snapshot com `stream[pair_index+1]`, a mesma expressão do presenter. Sozinha, essa comparação é circular.
- Mitigação feita pelo Claude: leitura de `main.gd:get_next_colors()` confirmou o mesmo índice (`pair_index+1`) e a mesma ordem (`[0]` pivô, `[1]` satélite). É verificação estática, não teste.
- `main.gd:_draw()` ainda gera o NEXT consumindo `model.rng` (dívida anterior à V11.2, citada no plano). O presenter depende de o cache já existir: antes do primeiro desenho, `next_pair` é indisponível (`next_pair_not_generated`).
- O teste de framebuffer prova que as consultas não alteram pixels. Não prova neutralidade de uma futura ligação em `main.gd`.

### 4.4 Outros
- O critério de sucesso do runner do Codex é fraco (exit code e ausência de `ERROR:` no log). Por isso as contagens foram comparadas manualmente.
- `session_active` depende de quem chama; replay e showcase devem passar `false`.

## 5. Pendências

### Antes do checkpoint da V11.2
Os três itens que estavam pendentes (reexecutar os dois testes do HUD, conferir o Git e rodar os 4 scripts não cobertos) foram concluídos pelo usuário. Resultados na seção 7. Nenhum pendente resta para o checkpoint, além da decisão sobre quais caminhos incluir (seção 7).

### V11.3 — NEXT compacto
- Exige ligar o presenter ao jogo; isso toca `main.gd` e precisa de autorização explícita.
- Criar validação do NEXT que não seja circular: comparar o snapshot com o par realmente desenhado (por exemplo, conferindo `next_pairs` na chamada da arena), sem aumentar chamadas a `get_next_colors`.
- Registrar a dívida do RNG em `_draw()`; correção só com proposta separada e prova de que o stream não muda.
- Decidir dimensões da caixa (proposta do plano: 48×76, centros a 32 px), conforme o layout aprovado na V11.1.

### V11.4 — WARNING e contador de ataque recebido
- Decidir entre fonte única para o critério de perigo (sem mudar o comportamento V10) ou manter duas cópias com teste de paridade obrigatório na regressão.
- Contador 00..99 usa `pending_display`; manter `pending_attack` real. Testar 0, 1, 98, 99, 100, 250.
- Faixas cromáticas e posição aguardam aprovação do layout.

### V11.5 — pedras enviadas
- Bloqueada pela fonte de dados. Ataque efetivamente enviado exige exposição do valor aceito após cancelamento e teto, o que hoje não existe e envolve o núcleo. Requer autorização específica; não é permitido deduzir por pontuação ou diferença de pending.
- Enquanto isso, `generated_attack` deve ganhar identificação da resolução (ou escopo) antes de ser exibido, e nunca ser chamado de "enviadas".

## 6. Estado final desta etapa

- Arquivos alterados nesta etapa documental: `relatorios/v11_2/RELATORIO_V11_2.md` (novo) e `CONTINUIDADE_PROJETO.md` (entrada acrescentada no topo; conteúdo anterior preservado).
- Nenhum arquivo apagado. Nenhum commit, push ou tag.
- **Recomendação (atualizada na seção 7):** V11.2 pronta para checkpoint. Aguardando autorização do usuário.

## 7. Validação final — execuções manuais do usuário (logs lidos pelo Claude)

Fonte: `C:\Projetos\validacao_v11_2\`, gerada pelo usuário em 05/11 entre 02:16 e 02:30. O Claude não executou estes testes; leu os logs e os arquivos de saída.

| Teste | Resultado confirmado | Linha de base |
|---|---|---|
| `test_hud_presenter` (sem janela) | `HUD_PRESENTER checks=3931 suites=7 failures=[]`; código 0 (informado pelo usuário) | igual à execução do Codex |
| `test_hud_presenter_scene` (com janela) | `hud_scene.json`: 1.013 checks, `failures: []`, 1.000 consultas, `pixel_identical: true`; código 0 (informado pelo usuário) | igual à execução do Codex |
| `test_animation_v8` | `ANIMATION_V8_TESTS 145 checks; failures=[]`; código 0 | 145 (V10) |
| `test_art_v9` | `ART_V9_TESTS 102 checks; failures=[]`; código 0 | 102 (V10) |
| `test_showcase_ui` | `SHOWCASE_UI_OK` (seletores, pausa, passo de quadro, render C4, ida e volta com F4); código 0 | sem número de referência |
| `test_character_select_ui` | `COIN_SELECT_UI_OK`, 12 capturas, janelas 1000×700 e 1280×900; código 0 | sem número de referência |

Os códigos de saída dos quatro testes de regressão vêm de `resumo_graficos.txt` (todos 0). Os dois do HUD constam apenas como informados pelo usuário.

**Aprovados:** 6/6. **Reprovados:** nenhum. **Avisos ou erros:** nenhuma linha de erro nem aviso (`SCRIPT ERROR`, `ERROR`, `WARNING`) nos logs. **Diferenças em relação à V10:** nenhuma; as contagens de `animation_v8` e `art_v9` são idênticas à linha de base.

**Lacuna de evidência:** o log de console do teste de cena (`test_hud_presenter_scene.gd.log`, 02:16, 152 bytes) contém só o banner do Godot, sem a linha `HUD_SCENE`. O resultado vem do `hud_scene.json` (02:30), gravado pelo próprio teste após as verificações. Não tenho o console dessa execução. O log de 02:16 parece de uma tentativa anterior, o que é inferência minha. Os números batem exatamente com os do Codex (1.013 checks, tamanho idêntico do JSON).

### Estado do Git

Saída do `git.txt` gerada pelo usuário (arquivo em UTF-16):

| Item | Resultado |
|---|---|
| Branch | `feature/v11-hud` |
| HEAD | `1a943a4db4d1dba84a222735187afb6108b4c4c5` (igual à base `v0.10.0`; sem commit novo) |
| Modificado | `CONTINUIDADE_PROJETO.md` (+23 inserções, nenhuma remoção) |
| Em staging (`diff --cached`) | vazio |
| Não rastreados (V11.2) | `godot/presentation/hud_presenter.gd`, `godot/tests/test_hud_presenter.gd`, `godot/tests/test_hud_presenter_scene.gd`, `relatorios/v11_2/` |
| Não rastreados (anteriores) | `planejamento/` (`V11_PLANO_HUD.md` e `v11_1/*`), `relatorios/v10_3_4/revalidacao_codex/` (2 arquivos) |
| `main` | ref aponta para `1a943a4…`; arquivo de ref intocado desde 04/11 23:56:06 (lido pelo Claude em `.git`) |
| Tag `v0.10.0` | ref intocada desde 04/11 23:56:27. É tag anotada (objeto `6d8d2aef…`); o commit apontado não foi resolvido nesta sessão, pois o `git.txt` não incluiu `rev-parse` da tag |

Não há arquivo inesperado: o script de validação e suas saídas ficam em `C:\Projetos`, fora do repositório.

### Recomendação sobre o checkpoint

A V11.2 está **pronta para checkpoint**. Não foi encontrado defeito, nenhum código foi alterado e os riscos das seções 4.1 a 4.4 permanecem registrados. A decisão que cabe ao usuário é quais caminhos entram no commit: os três arquivos da V11.2, este relatório e `CONTINUIDADE_PROJETO.md` são da etapa; `planejamento/` (V11.0/V11.1) e `relatorios/v10_3_4/revalidacao_codex/` já estavam não rastreados antes e podem ir junto ou ficar de fora. Nenhum commit, push ou tag foi feito.
