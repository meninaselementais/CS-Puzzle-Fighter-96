# V10 — diagnóstico de física das gemas (etapa 1)

Diagnóstico concluído em 01/11/2026. Não foi iniciada a implementação.

## Base e preservação

Branch criada: `feature/v10-gem-physics`. HEAD e tag anotada `v0.9.0` apontam
para `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`. A consulta `git ls-remote`
confirmou esse mesmo commit em `origin/main` e na tag remota desreferenciada.
A árvore estava limpa antes da criação da branch. Foram reconferidos os
198 hashes de `godot/`, `scripts/` e `tests/` do manifesto da V9: todos iguais.
Nenhum arquivo rastreado foi alterado, preparado no índice ou commitado.
Os arquivos novos são relatórios locais em `relatorios/v10_gem_physics/`.

Foram lidos integralmente os sete arquivos solicitados, além de
`pair_model.gd`, dos testes, dos exportadores, das Luas de coleta e dos
relatórios históricos. Não houve execução nova do MAME nem alteração de ROM.

## Linha de base executada antes de qualquer mudança de implementação

Godot 4.7.2 Windows, testes headless existentes via `scripts/validar_apresentacao.py`.
Execução válida: `--output C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v10_gem_physics\baseline_absolute`.

| Bateria | Resultado |
|---|---|
| Python | 17/17 |
| Modelos e geometria MAME | PASS |
| Regras | 34/34 |
| Fidelidade controlada | 247/247 |
| Controles | 33/33, 866 amostras RNG; 10 fontes sintéticas inválidas excluídas |
| Endpoints naturais | 119/119 |
| Duelo | 1.500 turnos, 26 partidas, 239 ondas, 908 ataques brutos |
| Apresentação | 3.285 verificações |
| Animação V8 / arte V9 | 145 / 102 verificações |
| Seleção / Coin Flip | 3.351 / 40.195 verificações |

As 12 baterias passaram. Logs e comandos completos estão em
`baseline_absolute/summary.json` e nos `.log` dessa pasta. Não foram repetidas
as 1.000 partidas de integração. Não foi feita nova validação gráfica do Godot.

**Tentativa inicial preservada em `baseline/`:** o argumento de saída relativo
gerou `ERROR: Could not create directory: 'user://C:'` nas execuções Godot.
As asserções imprimiram sucesso, mas o executor corretamente classificou os
logs como FAIL. Repetir com caminho absoluto eliminou os erros. Nenhum script
foi corrigido para isso. Não se trata de regressão lógica da V10.
Os testes legados também regravam JSONs de comparação em `relatorios/fidelidade_v5/`
por caminhos fixos; as evidências de execução desta baseline ficam separadas,
os logs da V9 permanecem preservados e nenhum arquivo rastreado mudou.

## Força da evidência

- **Comprovado no escopo ensaiado:** RAM/CSV do MAME 0.289, `spf2tu` USA 960620,
  com sessão válida e resultado comparável. Não significa todos os níveis,
  versões, situações de colisão ou parâmetros de velocidade.
- **Diferença demonstrada por código e traço:** arquitetura ou temporalidade
  atual incompatível com os registros, mesmo quando os endpoints coincidem.
- **Não determinado:** falta medir o comportamento; não será proposta uma
  constante arbitrária ou uma regra presumida como se fosse do arcade.

`control_fixtures.json` coincide com as **1.250 linhas e 40 casos** do CSV
de `laboratorio/auto_20261028_231304_380937/timing.csv`. As quatro fontes
de controles/RNG possuem manifestos válidos e SHA-256 da Lua conferido contra
`experimento.lua`. O hash do CSV de mecânicas da sessão
`auto_20261028_231155_374892` também confere. Detalhes em `provenance.json`.

## Tabela de diagnóstico

| Comportamento | Implementação atual | Comportamento do MAME | Diferença encontrada | Correção necessária, ainda não implementada | Arquivos envolvidos |
|---|---|---|---|---|---|
| Rotação com pivô | Satélite em `pivot + offset`; primeiro elemento mantém identidade salvo quick turn. | Replay confirma satélite a 16 pixels do pivô; botões mudam orientação nas duas direções. | Nenhuma divergência geométrica nos casos cobertos. A animação entre estados não é certificada por endpoints. | Preservar geometria e cores; medir trajetória visual antes de adicionar interpolação. | `core/pair_model.gd`, `core/match_model.gd`, `presentation/main.gd`, `tests/test_models.gd` |
| Quatro orientações | `UP, RIGHT, DOWN, LEFT`, módulo 4. | Observadas as quatro orientações, meia-volta e retorno após quatro rotações. | Nenhuma no conjunto observado; desenho muda posição sem transição angular explícita. | Não reescrever a regra. Ampliar comparação por quadro se houver exigência de animação de giro. | `pair_model.gd`, `match_model.gd`, `main.gd`, `test_controls_fidelity.gd` |
| Paredes, piso e corredor | Kick lateral de uma coluna; kick para cima ao girar para baixo; vertical cercada troca cores mantendo orientação. | `wall_0_0_1` passa de X=0/R=0 para X=1/R=3; casos de piso válidos coincidem. `quickturn_1` troca cores 2/12 para 12/2 no quadro 2 e retorna no 12. | Geometria aprovada nos casos válidos. Dez fontes sintéticas são inválidas e excluídas; teto, encaixes irregulares e simultaneidade não estão esgotados. | Preservar kicks aprovados; coletar só lacunas antes de alterar prioridades de colisão. | `match_model.gd:75`, `board_model.gd:71`, `test_controls_fidelity.gd`, `lua/tempos.lua`, `control_fixtures.json` |
| Gravidade da dupla ativa | Uma linha a cada 32 ticks globais; fase e interpolação derivadas de `model.frame % 32`; Down usa 4/2/1 e idade >16. | No estado medido, mudanças Y em 15,47,79,111,143,175: intervalo 32. Desenho usa `Y-1+offset/16`; Down muda em 5,7,9,11,12,13. | Período e repetição cobertos, mas fase inicial, offset e cadência após spawn não são validados pelo teste atual. Rampa visual continua baseada na gravidade normal mesmo com Down. | Sincronizar por estado/fase observado por jogador e comparar offset por quadro; medir progressão antes de parametrizar velocidades. | `match_model.gd:175`, `control_model.gd:24`, `main.gd:67,209`, fixtures/testes de controles |
| Travamento após contato | Falha de descida chama `commit → resolve_turn → spawn` imediatamente, sem contador de contato. Pode haver espera incidental até o próximo tick de descida, mas não uma janela própria. | Em `neutral`, campo exportado como `rotation_lock`=16 no quadro 207 e 1 no 222; marcador de turno muda no 223. Em `down_held`, 16 no 14, 1 no 29, turno muda no 30. | Diferença temporal demonstrada: contato mantém estado por 16 quadros nessas duas amostras; modelo não tem equivalente. | Introduzir futuramente fase de contato/travamento com regra medida. Os 16 quadros (~0,268 s) são observação desses estados, não constante universal já autorizada. | `match_model.gd:97,108`, `control_model.gd`, `main.gd`; novos casos temporais |
| Rotação durante travamento | `rotate()` só consulta colisão, perda e vencedor. Depois do commit instantâneo, atua na próxima dupla. | CSV mostra intervalo de contato, mas `neutral`/`down_held` não pressionam giro nele; os casos `floor_*` giram antes de aparecer esse contador. | Falta o estado que permita representar a janela. Permissão, bloqueio, reset, extensão e eventual limite de giros no arcade ainda não foram comprovados. | Medir giro em cada fase da janela, com/sem Down, obstáculos e repetição. Só então definir bloqueio/reset; não presumir regras de outros puzzles. | `match_model.gd:75,97`, `control_model.gd`, entrada em `main.gd`, `lua/tempos.lua` e fixtures novas |
| Queda independente após assentamento | `commit()` grava ambas as células; `resolution.gravity()` move células livres separadamente e preserva Power Gems como retângulos rígidos, até estabilizar, numa chamada. | Endpoints de `gravity_after_clear` e `power_rigid_gravity` coincidem; Power apoiada por uma borda permanece rígida. Máquina de estados e quadros visuais mostram resolução temporal. | A queda independente lógica já existe. Falta sua cronologia, sobretudo dupla horizontal apoiada em apenas uma extremidade; esse caso de separação não tem fixture dedicada. | Preservar endpoints/rigidez. Medir separação da dupla e emitir/consumir estados de queda por gema; evitar recriar gravidade que já funciona. | `board_model.gd:79`, `resolution.gd:42,149`, `match_model.gd:108`, `cs_arena.gd:726,938`, `main.gd` |
| Contato, compressão e recuperação | Em célula nova: offset visual 22 px, queda 14 px/tick, squash 0,85/1 e recuperação -0,14/tick; escala `1+0,17*sin(sπ), 1-0,14*sin(sπ)`. Reconstrução por diferença de células, sem identidade persistente. | Capturas MAME existentes registram evolução visual real, mas não há fixture que compare escala, contato e recuperação por quadro. | Efeito atual existe, mas os números são apresentação própria, sem calibração MAME demonstrada. Não é possível afirmar a curva exata do arcade nesta etapa. | Extrair posição/contorno/escala no contato, separar gema ativa, gema solta e Power; testar por quadro antes de substituir constantes. | `cs_arena.gd:360,938`, `main.gd:149,190`, fixtures visuais/MAME |
| Formação/expansão de gemas iguais | `form_powers` cria/expande/une retângulos; desenho usa dimensões finais e flash de 14 ticks. Não há transição temporal de contorno nem animação específica por vizinho igual. | `power_growth_turn2`: 2×2 → 2×3; `power_union_turn2`: duas 2×2 → 5×2; linha 1×4 e L não viram Power. Capturas `power_0032/0040/0048` mostram mudanças de aparência. | Endpoints retangulares passam. Flash não comprova fidelidade da expansão visual. Não há evidência para afirmar que todo contato de mesma cor deva expandir. | Separar crescimento Power de deformação de contato comum; medir curva/duração. Não alterar `Gem.can_power` ou seleção de retângulos sem contraexemplo. | `resolution.gd:6`, `board_model.gd`, `gem_rules.gd:48`, `cs_arena.gd:987,1370`, `main.gd:155` |
| Cronologia de resolução e integração | Resolução imediata; arena reconstrói ondas em tabuleiro-sombra, com tempos próprios. Próxima dupla pode existir enquanto animação antiga é exibida. | A sessão visual válida percorre estados 1..19; em `power`, estado 11 ocupa quadros 58..97 e sai no 98 (40 quadros). | Fidelidade de resultado final não equivale a fidelidade temporal; temporização afeta controles, ataques concorrentes e consumo de RNG. | Planejar máquina temporal e eventos com testes de regressão antes de alterar. Nenhuma troca de ordem ou duração nesta etapa. | `match_model.gd`, `resolution.gd`, `cs_arena.gd:599,742,754`, `main.gd`, testes naturais/apresentação |

Os caminhos abreviados da tabela são relativos a `godot/`, exceto `lua/`.
`gem_rules.gd` classifica tipos/cores e elegibilidade para Power; não contém
física. Sua inspeção não revelou necessidade comprovada de modificá-lo.

## Por que os resultados atuais não certificam a física inteira

`test_controls_fidelity.gd` compara uma transição inicial para cada rotação
e duas trocas de quick turn. Down compara somente os primeiros **13 quadros**,
antes do contato no quadro 14. O ramo neutral verifica diferenças de Y no
próprio traço contra `GRAVITY_TICKS`; não reproduz a sequência com `model.tick()`.
Não compara `offset`, `rotation_lock`, forma do sprite nem estado por quadro.
Os testes de resolução e naturais comparam endpoints e pontuação, com filas,
seletor e outros estados observados fornecidos como entrada. Portanto, os
247/247 e 119/119 devem permanecer como regressão, sem virar alegação de
partida completa temporalmente sincronizada.

A formação Power resolve o maior retângulo compatível e mantém identidade de
retângulos existentes, mas o próprio código marca desempates complexos como
pendentes. Não há motivo para mudar essa regra só para animar expansão.

## Evidências examinadas e limites

`timing_evidence.csv` preserva as linhas relevantes sem ROM ou dump binário.
As fotos MAME `power_0032.png`, `power_0040.png`, `power_0048.png` da sessão
`auto_20261030_180156_204005` foram abertas e inspecionadas. Seu `visual.csv`
foi lido para as transições temporais; o manifesto e o hash da Lua conferem.
O caso visual `power` também envolve limpeza, logo não deve ser usado sozinho
para medir expansão pura sem Crash. O primeiro ensaio visual histórico
`auto_20261030_175915_731296` não concluiu e não foi usado como prova válida.

Os 16 quadros provam o intervalo observado do contador e da mudança do marcador
de turno, mas o nome CSV `rotation_lock` não prova, por si, que rotação esteja
permitida ou bloqueada, nem a rotina exata de reset. Isso exige entradas
controladas e, se necessário, confirmar os escritores via depurador.

## Arquivos candidatos e riscos antes de implementar

1. **Necessidade demonstrada:** `match_model.gd` para estado de contato e
   cronologia; `main.gd` para renderizar o estado físico correto; `cs_arena.gd`
   para remover suposições visuais após medir. Risco alto: atribuir uma rotação
   à próxima dupla, spawn antecipado, top-out e contagem de rounds fora de fase.
2. **Dependentes do desenho temporal medido:** `control_model.gd` e
   `resolution.gd`. Preservar APIs/endpoints durante uma futura mudança gradual.
   Risco alto: consumir RNG em fases erradas, mudar chegada/cancelamento de
   ataques, bônus de primeiro ataque e contagem de Counter Gems.
3. **Preservar até haver contraexemplo:** `board_model.gd`, `pair_model.gd` e
   `gem_rules.gd`. Separação lógica e Power rígida já funcionam nos casos
   ensaiados. Risco: quebrar a identidade dos retângulos ao animar células
   individualmente, ou mudar canonização/cores por um problema só visual.
4. **Ampliar primeiro:** `lua/tempos.lua` ou ensaio separado,
   `test_controls_fidelity.gd`, fixtures temporais/visuais e regressões
   `test_models`, `test_rules`, `test_fidelity`, `test_natural_fidelity`,
   `test_presentation` e fluxo de rounds. Não adaptar expectativas para fazer
   o código passar: exportar somente observações do arcade.

Próxima coleta proposta: apoiar a dupla horizontal alternando pivô/satélite,
alturas e cores; pressionar ambos os giros em contato+0/1/8/15/16 e repetir;
testar soltura/Down, paredes, corredor e teto; capturar RAM e imagem após vídeo
por quadro. Medir expansão Power sem limpeza, união por ponte e contato igual
que não forma 2×2. Validar P1/P2 e outras velocidades antes de generalizar.
Essa coleta e as alterações não foram executadas nesta etapa.

## Ferramentas e skills

As existentes são suficientes: skill Godot, Godot 4.7.2, Python padrão,
MAME 0.289 com Lua/depurador, save states e coletor `automatizar_mame.py`.
O necessário é ampliar a instrumentação e as fixtures, não instalar uma skill
nova ou substituir o motor. Computer Use já disponível só é útil para conferir
a janela; screenshots sincronizados do próprio MAME são melhores para medir
quadros. FFmpeg ou uma biblioteca de análise de imagens seriam opcionais para
comparativos/contornos, se a inspeção dos PNGs existentes não bastar; nenhuma
dependência adicional é exigida para o próximo ensaio de RAM e entrada.

## Estado final

Diagnóstico concluído; implementação não iniciada. Branch de desenvolvimento
criada, código e dados rastreados idênticos à V9. Sem commit, push ou estágio
de arquivos. A linha de base e as incertezas estão preservadas separadamente.
