# V11.5.1 — ENVIADAS (total líquido da jogada)

Data: 07/11/2026. Continuidade Codex → Claude. Nenhum commit, push ou tag foi criado. V11.6 não foi iniciada.

## FECHAMENTO — resultado final validado (Windows, Godot 4.7.2 Compatibility, RTX 5070)

**Status: V11.5.1 validada, 4/4 baterias aprovadas. Commit NÃO criado (sem terminal nesta sessão); inventário preparado na seção 8.**

| Bateria | Resultado | Onde conferi (Claude, por leitura) |
|---|---|---|
| `sent` | **18.167 checks, 0 falhas** | `evidence/sent/result.json` e `console.log`: `SENT checks=18167 failures=[]`; `sent_summary.json` `passed: true`, `exit_code: 0` |
| `hud5` | **5.718 checks, 0 falhas** | `evidence/hud5/console.log`: `HUD_V11_5 checks=5718 failures=[]`; `hud5_summary.json` aprovado |
| `focused` | aprovado | `focused_summary.json`: `hud_next`, `hud_presenter`, `hud_scene`, todos `passed` e `exit_code 0` |
| `regression` | aprovado | `regression_summary.json`: 19 itens, todos `passed` e `exit_code 0` |

Observações de integridade: os resumos e logs são posteriores à última edição de código e de teste (por data de modificação: `match_model.gd` e `test_sent_v11_5_1.gd` antes dos resumos), então valem para o código atual. Claude não executou nenhum teste; os números são os gravados pela execução do usuário. O `regression_summary.json` tem 19 itens, e não os 22 que citei antes: aquela contagem estava errada.

**Confirmações:**
- **ENVIADAS = total líquido acumulado da jogada:** confirmado no código (`record_sent_attack` soma o aceito; zera por `turn_number` ou por `resolve_turn`) e pelo teste de cadeias reais de 3 e 5 ondas com filas 0/2/200/250, cujo esperado é calculado de forma independente. Zero não apaga o total; o valor persiste após o spawn ou a derrota.
- **Cancelamento total e parcial:** fixture independente `[0,0,3] [20,0,0] [1,0,2] [0,249,1] [0,250,0]` e cálculo `maxi(0, bruto − fila própria)` por onda, aprovados.
- **Limite visual 99:** `clampi(...,0,99)` só no desenho; o valor interno 125 é preservado. Vi a captura `evidence/sent/sent_99_06.png`: P1 mostra `ENVIADAS 99` (com 125 interno) e P2 mostra `ENVIADAS 06`, ambos com `A RECEBER 00`; NEXT, personagens e placar intactos.
- **P1/P2:** acumuladores independentes; verificado no teste (P2 intocado quando P1 resolve, caso espelho, e a captura acima com valores distintos).
- **Equivalência com o modelo anterior:** comparação do estado completo, incluindo RNG, a cada tick (500 ticks, cadeias 1/3/5, filas 0/2/200/250) aprovada.
- **Preservação:** `board_model.gd`, `arcade_rng.gd`, `attack_rules.gd`, `resolution.gd`, `pair_model.gd`, `gem_rules.gd`, `main.gd` e os arquivos de vidro não foram alterados (hash contra o índice).

**Divergência preexistente (não modificada):** `MatchModel.resolve_turn()` soma `outgoing` à fila adversária sem o teto `mini(250, …)` que o caminho por ticks (`gem_motion.gd`) aplica. Já existia antes da V11.5.1; o modelo de referência (`reference_sent`) tem o mesmo comportamento e a paridade síncrona passa. Exige análise separada antes de qualquer mudança.

## 0. Diagnóstico da falha do teste `sent` (execução real do usuário, Windows)
**Evidência** (`evidence/sent/result.json` e `console.log`): `checks=18063`, 1257 falhas, **todas** com a mesma mensagem, `net total never exceeds raw production of the same resolution`, no `test_sent_v11_5_1.gd:47` (laço de 500 ticks). Todas as demais verificações novas passaram: acúmulo de 3 ondas, persistência, reinício na jogada seguinte, P2 independente, caso espelho, reinício da partida. O log antigo não imprimia valores esperados e obtidos, então os números exatos não puderam ser lidos.

**Causa (comprovada por leitura do código; não confirmada por nova execução):** o defeito está na verificação do teste, não no acumulador. A verificação comparava `last_sent_attack` com `motion[i].result.attack` sempre que `sent_turn == turn_number`. Porém `MatchModel.spawn()` (linhas 66-74) cria um `Motion.new()` assim que a resolução termina e o próximo par aparece, com `result` vazio. O `turn_number` só muda no `deposit()`, depois que esse par cai. Entre o `spawn` e o `deposit` o total permanece visível (requisito 5), mas `result.attack` já vale 0, por isso a comparação falhava de forma persistente, centenas de ticks seguidos.

**Início e fim da resolução, conforme o código:** a resolução começa no `deposit()` (`turn_number += 1`, `chain_count = 0`, `result` novo); as ondas pertencem ao mesmo `turn_number` e ao mesmo `Motion`; a resolução termina quando `phase == 19` chama `spawn()`. O acumulador usa `turn_number`, que é estável durante toda a resolução e muda exatamente na próxima, então a identificação está correta. Não encontrei defeito em `record_sent_attack`.

**Correção (somente no teste, sem enfraquecer a verificação):** o teste agora observa, ele mesmo, a produção bruta por jogador e por `turn_number` (acompanhando o objeto `Motion` e o número de ondas novas a cada tick) e exige `total <= bruto observado do turno em que o total foi acumulado`. A verificação ficou mais estrita que antes, pois agora também vale depois do `spawn`. A mensagem de falha agora imprime cadeia, fila, tick, jogador, total, bruto e turno. Nenhum código de jogo foi alterado nesta correção.

**Novo teste com cadeia real:** `chain_board(3)` e `chain_board(5)`, filas iniciais 0/2/200/250. Avança só o P1 manualmente, na mesma ordem do `MatchModel.tick()`, até o `spawn`. O valor aceito por onda é calculado no próprio teste (`mini(250, fila + maxi(0, bruto - fila própria)) - fila`), sem usar `record_sent_attack`. Verifica o total corrente a cada onda, que a cadeia teve ao menos 2 ondas, que o total persiste após o `spawn` e nunca passa do bruto, que sem fila própria o total é a produção inteira (quando ela não passa de 250), que o total não é apenas o da última onda e que o P2 não é tocado. **Não executado.**

## 0b. Diagnóstico das quatro falhas restantes (execução real do usuário)
**Evidência informada:** `SENT checks=18143`. As falhas da comparação com a produção bruta desapareceram, o que confirma o diagnóstico da seção 0. Restaram quatro falhas, todas em `test_sent_v11_5_1.gd:120` (`expect(resolved, ...)` do teste de cadeia real): cadeia 3 e 5 com fila inicial 200 e 250. As filas 0 e 2 passaram. As demais verificações do mesmo bloco (total corrente a cada onda, persistência, não ser só a última onda, P2 intocado) não falharam nesses quatro casos, então o acumulador deu o valor esperado até o fim.

**Causa exata (leitura do código, não confirmada por nova execução):** erro de **expectativa do teste**, não defeito da mecânica nem erro de fixture. A linha 120 exigia que o fim da resolução fosse sempre `r.motion[0] != before_obj`, isto é, que um novo par fosse criado. Em `gem_motion.gd`, fase 19, a resolução termina assim: `phase = 0`; `lost[player] = lost[player] or board.cells[15] != 0`; e `spawn()` só é chamado `if not model.lost[player]`. Com fila própria de 200 ou 250 (33 a 41 fileiras de pedras, contra um poço de 14), a fase 18 despeja pedras (`spawn_counter_row`) até a célula de entrada ficar ocupada. O jogador é derrotado legitimamente, nenhum `Motion` novo é criado e o teste ficou esperando até o limite de 3000 passos. O limite de passos não é a causa: o ciclo só acabaria se houvesse spawn, e aumentar o limite não o produziria.

**Classificação:** erro de fixture — não (a cadeia de 3 e 5 ondas funcionou). Erro de expectativa — sim. Defeito real da mecânica — não encontrado: a derrota por entrada bloqueada é a regra existente.

**Ressalva honesta:** o log não guarda o estado final dessas quatro partidas (`lost`, `winner`, célula 15). A causa é a única explicação que bate com o código e com o padrão das falhas (só filas altas), mas o estado final não foi lido de uma execução. A correção abaixo faz o teste afirmar e imprimir esse estado.

**Correção (somente `godot/tests/test_sent_v11_5_1.gd`):**
- O fim da resolução passa a ser "novo par criado **ou** jogador derrotado".
- Verifica que ocorre exatamente um dos dois (`spawned != lost`).
- Se houve derrota: exige célula 15 ocupada, `winner == 1` e movimento ocioso (`phase == 0`). Se não houve: exige `winner == -2`, par existente e célula 15 livre.
- Filas 0 e 2 nunca podem causar derrota.
- A falha, se ocorrer, imprime `lost`, `phase`, fila e número de ondas.
- Nada foi relaxado: o total líquido, a persistência após o fim e as demais verificações continuam aplicadas nos quatro casos. Código do jogo (`match_model.gd`, `gem_motion.gd`, RNG, física, regras, teto de 250, NEXT, HUD, vidro) **não foi alterado**.

**Cobertura do pedido:** cadeias de 3 e 5 ondas com filas 0/2/200/250 verificam total líquido acumulado, cancelamento (cálculo independente), P2 intocado, estado final da resolução, spawn ou derrota, e a equivalência tick a tick com o modelo anterior (bloco dos 500 ticks, que já passou nessas combinações). **Os testes após esta correção NÃO FORAM EXECUTADOS.**

**Riscos restantes:** (1) a afirmação de que filas 0 e 2 nunca derrotam vem do que já foi observado; se falhar, será um dado novo, não um defeito do acumulador. (2) Se alguma das quatro partidas não terminar em derrota, a nova mensagem mostrará o estado real. (3) `hud5`, `focused` e `regression` ainda não foram executados com o acumulador atual.

## 1. Situação dos testes
**Histórico (substituído pelo FECHAMENTO acima):** o `sent` falhou duas vezes (seções 0 e 0b), foi corrigido apenas no teste e as quatro baterias foram depois executadas pelo usuário com 4/4 aprovadas. Claude não executou testes em nenhuma etapa.

Verificação feita por Claude: análise estática de sintaxe com `gdtoolkit` (parse OK em `match_model.gd` e `test_sent_v11_5_1.gd`) e `diff` contra as cópias anteriores. Isso não substitui a execução no Godot.

## 2. Git (leitura de arquivos)
- Branch `feature/v11-hud`, HEAD `9ea7dc8` (V11.5). A V11.5.1 continua sem commit.
- Modificados pela V11.5.1: `core/match_model.gd`, `core/gem_motion.gd` (Codex, sem mudança nesta etapa), `presentation/hud_presenter.gd`, `presentation/cs_arena.gd`, `tests/test_sent_v11_5_1.gd`.
- Criados: `tests/reference_sent/{model,motion}.gd`, `relatorios/v11_5_1/`.
- `board_model.gd`, `arcade_rng.gd`, `attack_rules.gd`, `resolution.gd`, `pair_model.gd`, `gem_rules.gd` e `main.gd` idênticos ao índice (hash, conferido antes desta etapa). Nesta etapa só editei `match_model.gd` e o teste.

## 3. O que o Codex implementou (confirmado)
Telemetria `last_sent_attack` e `sent_event_id` no modelo; registro em `gem_motion.gd` pela diferença da fila adversária depois de `cancel_attack` e do teto `mini(250, …)`; `Hud.snapshot` entrega `sent_attack`; `cs_arena.gd` desenha `ENVIADAS %02d` com `clampi(0,99)` e pulso de 12 ticks.

## 4. Mudança desta etapa: total líquido da jogada
Decisão do usuário: ENVIADAS mostra o total líquido da jogada, não só a última onda.

Arquivo alterado: `godot/core/match_model.gd` (acréscimos; mantida a codificação CRLF).
- Novo campo `sent_turn: Array[int] = [-1,-1]`: marca o turno (`turn_number`) da resolução que está sendo acumulada. Zerado em `restart()`.
- `record_sent_attack(player, accepted, new_resolution = false)`:
  - se `new_resolution` ou `sent_turn[player] != turn_number[player]`, zera `last_sent_attack[player]` antes de somar;
  - grava `sent_turn[player]` e soma `accepted`;
  - incrementa `sent_event_id` (pulso visual).
- `resolve_turn()` (caminho síncrono) passa `new_resolution = true`: cada chamada é uma resolução completa.
- `gem_motion.gd` **não foi alterado nesta etapa**. Ele continua passando só o valor aceito (diferença da fila após cancelamento e teto 250). Cada resolução por ticks começa em um novo `turn_number` (incrementado em `deposit()`), então a primeira onda do turno inicia o acumulador.
- `hud_presenter.gd` e `cs_arena.gd` não mudaram: `sent_attack` já lê `last_sent_attack`, agora acumulado.

Atendimento dos requisitos:
| # | Requisito | Como é atendido |
|---|---|---|
| 1 | Somar só líquido aceito | `accepted` = diferença da fila adversária (ticks) ou `cancel_attack` (síncrono). |
| 2 | Sem produção bruta | A produção bruta `wave.attack` nunca é somada. |
| 3 | Onda com zero não apaga | Soma 0; só o evento visual pulsa. |
| 4 | Reinício na próxima resolução | Mudança de `turn_number` (ticks) ou `new_resolution` (síncrono). |
| 5 | Visível até a próxima resolução | Nada zera o campo fora de `record_sent_attack` e `restart()`. |
| 6 | Zerar em nova partida | `restart()` zera `last_sent_attack`, `sent_event_id` e `sent_turn`. |
| 7 | Limite visual 99 | `clampi(…,0,99)` só no desenho; valor interno real intacto. |
| 8 | P1/P2 independentes | Arrays por jogador; `sent_turn` por jogador. |
| 9 | Regras, RNG, física, resultados | Nenhum campo existente é lido de volta ou escrito; apenas campos novos. |
| 10 | Equivalência por tick | Teste compara o estado completo com `reference_sent` a cada tick (ver seção 5). |

Escolha de projeto a registrar: a resolução sem nenhuma onda (sem remoções) não toca o contador. O valor da jogada anterior permanece até a próxima resolução que de fato produza uma onda.

## 5. Testes preparados — NÃO EXECUTADOS
Arquivo: `godot/tests/test_sent_v11_5_1.gd`.
- Equivalência tick a tick de 500 ticks (cadeias 1/3/5; filas 0/2/200/250) contra `reference_sent`, comparando todo o estado, inclusive RNG e resultados. `sent_turn`, `last_sent_attack` e `sent_event_id` ficam fora da comparação por serem os campos novos.
- Limite: o total nunca excede a produção bruta da mesma resolução (substitui o antigo limite fixo de 250, que deixaria de valer para uma soma).
- Novo: acúmulo de 3 ondas consecutivas com filas iniciais 0/1/2/200, esperado calculado de forma independente (`maxi(0, bruto − fila própria)` e teto 250); total persiste após a resolução; próxima resolução reinicia; P2 independente de P1 e caso espelho P2.
- Mantidos: cancelamento total e parcial (fixture `[0,0,3] [20,0,0] [1,0,2] [0,249,1] [0,250,0]`), paridade síncrona, valor bruto 125 preservado com exibição limitada a 99, reinício zera tudo.
- Limitação: o teste novo usa a mesma placa de uma onda repetida em cada passo; não prova uma cadeia real de várias ondas em partida completa (isso só é coberto pela comparação tick a tick, que verifica o limite, não o valor exato do total).

### Como validar (PowerShell, na raiz do projeto)
```
python relatorios\v11_5_1\run_validation.py sent
python relatorios\v11_5_1\run_validation.py hud5
python relatorios\v11_5_1\run_validation.py focused
python relatorios\v11_5_1\run_validation.py regression
```
Depois confira `relatorios\v11_5_1\sent_summary.json` e `evidence\sent\result.json` (`failures` deve estar vazio). Esses resumos serão sobrescritos. Se os checks mudarem de 18030, é esperado.

## 6. Pendência técnica (não corrigida, por decisão)
`resolve_turn()` soma `outgoing` à fila adversária **sem** o teto `mini(250, …)` usado no caminho por ticks. A divergência já existia antes da V11.5.1 e não foi alterada. Requer análise separada. Efeito no HUD: no caminho síncrono o total pode superar o que o caminho por ticks aceitaria.

## 7. Outras pendências
- Criar o commit local (seção 8), que exige terminal e foi preparado, não executado.
- Análise separada do teto de 250 em `resolve_turn()`.
- Decisão sobre versionar os resumos JSON da V11.5.1 (seção 8).
- `test_sent_v11_5_1.gd` estava com fim de linha LF; `match_model.gd` mantém CRLF.
- Risco menor: nenhum item da V11.5.1 está em `.gitattributes`; o Git pode avisar sobre conversão CRLF/LF no `git add`. Isso é aviso, não erro, e a mistura já existe no projeto.

## 8. Inventário do checkpoint V11.5.1 (preparado, NÃO executado)

**Estado do Git reconstruído por leitura** (`.git/HEAD`, `refs/heads/feature/v11-hud`, reflog, índice com 696 entradas e comparação de hash). Não é `git status` real: **confirme no PowerShell antes de commitar.**
- Branch `feature/v11-hud`, HEAD `9ea7dc8d160e9fbb2c11d8213e78f40453b09814` (checkpoint V11.5). O reflog mostra, nesta ordem, os commits V11.4.2 (`753722c`) e V11.5. Ambos estão preservados e nada foi tocado em histórico. Nenhum commit, push, tag, reset ou clean foi executado.

**Incluir no commit (8 caminhos, todos conferidos):**
| Arquivo | Estado | Conteúdo |
|---|---|---|
| `godot/core/match_model.gd` | modificado | `sent_turn`, `record_sent_attack` acumulador, zeragem em `restart()` |
| `godot/core/gem_motion.gd` | modificado | registro do aceito na fila (Codex) |
| `godot/presentation/hud_presenter.gd` | modificado | campo `sent_attack` |
| `godot/presentation/cs_arena.gd` | modificado | painel ENVIADAS, pulso, limite visual 99 (Codex) |
| `godot/tests/test_sent_v11_5_1.gd` | novo | teste 18.167 checks |
| `godot/tests/reference_sent/model.gd` | novo | referência pré-V11.5.1 usada na equivalência |
| `godot/tests/reference_sent/motion.gd` | novo | idem |
| `relatorios/v11_5_1/RELATORIO_V11_5_1.md` | novo | este relatório (`*.md` não é ignorado) |

`main.gd` está inalterado em relação ao índice, não entra. Não há `.uid` novo para os testes (não existe `test_sent_v11_5_1.gd.uid`; os testes rodam por `--script`).

**Opcional (decisão sua):** versionar `relatorios/v11_5_1/{sent,hud5,focused,regression}_summary.json` e `run_validation.py`, como foi feito na V11.5. Hoje o `.gitignore` os ignora (`/relatorios/**`). Para incluir, adicione antes ao `.gitignore`:
```
# V11.5.1 validation
!/relatorios/v11_5_1/sent_summary.json
!/relatorios/v11_5_1/hud5_summary.json
!/relatorios/v11_5_1/focused_summary.json
!/relatorios/v11_5_1/regression_summary.json
!/relatorios/v11_5_1/run_validation.py
```
Não alterei o `.gitignore`. O `run_validation.py` contém o caminho local `C:\Users\MauTrIX\.codex\...` (já existe nos anteriores da V11.4.x e V11.5); versionar é a sua escolha.

**Excluir (continuam no disco, preservados):**
- `relatorios/v11_5_1/evidence/` (24 subpastas, logs, PNG, `userdata`): ignorado por `/relatorios/**` e `*.log`.
- `relatorios/v11_5_1/gem_motion.before.txt`, `match_model.before.txt`, `historical_restoration.json`: cópias e artefatos de execução, ignorados. O baseline reprodutível já está em `godot/tests/reference_sent/`.
- `.ai/` (inclui `launch-key`, ignorada por `.ai/cezar/.gitignore`) e `planejamento/v11_1/referencia_atual/execucao.json`: já estavam não rastreados antes da V11.5; fora desta etapa.
- `.godot/`, `__pycache__`, `*.log`, `*.tmp`: ignorados.
- Backups `backup_pre_*`: ignorados.

**Credenciais:** não há segredo nos 8 caminhos (código GDScript, testes e relatório). Não varri os PNG/JSON de evidência, que ficam fora do commit.

**Comandos para o PowerShell (não executados por Claude):**
```
cd C:\Projetos\CS-Puzzle-Fighter-96
git status --short
git diff --stat
git add godot/core/match_model.gd godot/core/gem_motion.gd godot/presentation/hud_presenter.gd godot/presentation/cs_arena.gd godot/tests/test_sent_v11_5_1.gd godot/tests/reference_sent/model.gd godot/tests/reference_sent/motion.gd relatorios/v11_5_1/RELATORIO_V11_5_1.md
git status --short
git diff --cached --stat
git commit -m "feat(v11.5.1): registra envio liquido acumulado por jogada"
git log --oneline -3
git status --short
```
Confira que `git diff --cached --stat` mostra exatamente 8 arquivos antes do commit. Sem `git add -A`, `push`, tag, reset ou clean.
