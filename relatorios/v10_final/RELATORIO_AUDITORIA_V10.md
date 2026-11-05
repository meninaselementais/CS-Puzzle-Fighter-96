# Auditoria final da V10 — Counter-Strike Puzzle Fighter '96

Auditoria executada em 03/11/2026, America/Sao_Paulo. Escopo: versão de código do duelo local para dois jogadores, em Windows/Godot 4.7.2, sem servidor, clientes de rede ou carga multiusuário. O repositório reúne o jogo, a apresentação CS e ferramentas locais de comparação com observações do MAME.

**Recomendação: liberar v0.10.0 como versão funcional do duelo local, com as ressalvas deste relatório.** Não foi encontrado bloqueador funcional nos cenários reais executados. A recomendação não certifica equivalência integral de RNG, RAM ou pixels ao MAME, nem elimina os três achados de qualidade de validação/documentação descritos abaixo. Nenhuma tag, publicação ou alteração de código foi realizada nesta auditoria.

## 1. Identidade, Git e preservação

Branch auditada: `feature/v10-gem-physics`. HEAD e remoto confirmados em `4575f17a706d91df3ff009fb8b4d96d0cba06699`. A abreviação `4575f1a` fornecida na solicitação não resolve neste repositório; o hash auditado é o checkpoint efetivamente publicado na sessão anterior, identificado novamente por Git local e `git ls-remote`.

Base `v0.9.0`: commit `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`, que também continua sendo a branch `main`. As quatro revisões da V10 sobre essa base são `136238e`, `dde581f`, `70a52c5` e `4575f17`.

- A V9 tem 299 arquivos. Destes, **288 permanecem idênticos**, 11 foram modificados intencionalmente pela V10 e nenhum foi removido. Há 158 caminhos adicionados/modificados na comparação total da V10.
- Os 11 modificados são `.gitattributes`, `godot/core/{gem_rules,match_model,resolution}.gd`, `godot/presentation/{cs_arena,main}.gd` e `godot/tests/{test_character_select_ui,test_duel,test_match_flow,test_models,test_rules}.gd`. O arquivo `gem_motion.gd` é uma adição V10, não uma remoção/substituição de arquivo V9.
- `arcade_rng.gd`, `control_model.gd`, `attack_rules.gd` e as fixtures V9 `mechanics_fixtures.json`, `control_fixtures.json` e `natural_fixtures.json` têm os mesmos blobs da tag V9.
- O núcleo físico foi alterado na V10.2, como esperado pelo objetivo daquela versão. **Não houve alteração de `godot/core/` entre `136238e` e o HEAD atual**, nem qualquer alteração do núcleo nesta auditoria. A ponte de rotação em `main.gd` pertence à V10.3.3.
- `git fsck --full`: saída 0, sem objetos corrompidos. Relatou 23 blobs sem referência, compatíveis com preparações locais anteriores; nada foi apagado ou podado.
- `git diff --check v0.9.0..HEAD` sem ajuste de leitura acusa 124.782 ocorrências de CR no fim de linha em arquivos históricos preservados literalmente. O mesmo comando com `core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol`, limitado àquela execução, passa com saída 0. Não se alterou configuração, atributos ou arquivos para acomodar essa conferência.
- Antes dos testes, 448 arquivos rastreados/locais receberam SHA-256. Após todas as baterias, a conferência exige que permaneçam intactos; apenas a continuidade poderá ser atualizada ao encerrar a auditoria. Os dois arquivos não rastreados originais têm seus hashes verificados separadamente.

As bases, diferenças, hashes, referências e o estado final estão em `git_initial.json`, `v10_vs_v9_name_status.txt`, `v10_vs_v9_code.diff`, `preservation.json` e `git_final.json` na entrega externa. Não houve staging, commit, push, merge, rebase ou criação de tag.

## 2. Resultados executados nesta auditoria

Todos os números nesta tabela vêm de execuções novas no HEAD auditado. Não foram copiados dos relatórios anteriores.

| Suíte / execução atual | Resultado |
|---|---|
| Python `unittest discover` | 17/17 testes, saída 0 |
| Modelos | `GODOT_TESTS_OK`, saída 0 |
| Regras | 34 verificações, zero falhas |
| Fidelidade de tabuleiro/pontuação/ataques | 247/247 casos |
| Controles | 33/33; 866 amostras RNG; dez fontes sintéticas inválidas excluídas explicitamente pelo teste original |
| Endpoints naturais MAME | 119/119 fixtures |
| Duelo com entradas geradas | 1.500 turnos, 28 reinícios/partidas, 227 ondas e 797 ataques brutos; invariantes aprovadas |
| Física temporal V10.2 | 112/112 cenários, 14.072/14.072 amostras |
| Cadeias/Counter Gems V10.2 | 22/22 cenários, 5.066/5.066 amostras, 54 verificações |
| Apresentação | 3.285 verificações, zero falhas |
| Animação V8 preservada | 145 verificações, zero falhas |
| Arte V9 preservada | 102 verificações, zero falhas |
| Seleção de personagens | 3.351 verificações, zero falhas |
| Coin Flip | 40.195 verificações; 10.044/20.000 sorteios atribuíram CT a P1; zero falhas |
| Showcase UI | Seletores, pausa, avanço de quadro, render C4 e retorno F4 aprovados |
| Coin Flip/seleção/rounds em janela | Fluxos, áudio, teclado/gamepad simulados, lados fixos, três rounds, novo sorteio e duas dimensões de janela aprovados; 12 capturas |
| Executor existente com renderização | 17/17 baterias aprovadas, incluindo os renderizadores preview, mecânicas e demonstração de cadeias/C4 |
| V10.3.2 | 123.863 verificações, zero falhas |
| V10.3.3 | 119.052 verificações; 80 passos principais; 11.957 amostras ativas; zero falhas |
| V10.3.4 | 394 verificações, zero falhas |
| Séries completas de integração, headless | **1.000/1.000**, 2.500 rounds, 51.000 verificações, quatro processos; saída 0 |
| Séries completas em janela, com adaptador | **4/4**, dez rounds, 276 verificações; 30 PNGs; saída 0 |
| Teste histórico em janela, sem adaptador | **REPROVADO**: 0/4 séries, oito verificações; falha na transição Coin Flip→seleção |
| Capturas novas Power | 181 quadros + 181 controles sem overlay |
| Power contra descritores MAME | 1.192/1.192 amostras de células compatíveis |
| Estrutura diferencial Power | 1.407 verificações/181 pares, zero falhas |
| Capturas novas V10.3.2 | 172 PNGs |
| Contato, ligação e halo contra MAME | 20/20 pares; zero diferenças de máscara |
| Queda independente contra MAME | 4/4 pares; zero diferenças de máscara |
| Rotação recapturada na cena atual | 340 registros com pares imagem/fundo, mais ponte P1/P2 e reinício; pausa e integração real aprovadas |
| Máscaras das novas capturas de rotação | 340/340 válidas; 26 quadros inativos sem resíduos |
| Novos PNGs de rotação contra MAME | 80/80 pares; zero diferenças de máscara; 36 quadros/268 pixels de oclusão corretos |
| Capturas antigas de rotação, reanalisadas agora | 80/80 pares; mesmos resultados, registrados separadamente da coleta Godot atual |
| Recursos Godot em modo debug | 59 itens, incluindo quatro cenas; zero erros, zero avisos de configuração; 73 avisos GDScript/lint |
| Smoke das quatro cenas com entradas geradas | 4/4, zero erros; 102 ocorrências de avisos; transição Coin Flip→seleção registrada como informação esperada |

Os 73 avisos da validação nativa têm os mesmos pares arquivo/mensagem da validação preservada da V10.3.4; os 11 avisos estáticos de caminhos estão incluídos nessa contagem. Não se declara “zero avisos”. Os checkpoints dos quatro processos do lote registram quatro nós em todos os checkpoints amostrados; isso não é uma medição de ausência absoluta de vazamento de memória.

**Limite das 1.000 séries:** `test_match_flow.gd` provoca o top-out com um tabuleiro preparado e chama o resolvedor existente, validando Coin Flip, seleção, placares 2×0/0×2/2×1/1×2, contagem única, reinício e mudança de round/partida. São séries completas daquele teste, não 1.000 duelos naturais jogados até top-out exclusivamente por entradas, nem comparações de partidas completas contra o MAME. Os 119 casos naturais comparam endpoints já coletados. O duelo de 1.500 turnos fornece cobertura adicional de evolução do jogo, com escopo separado.

## 3. Física, combos e Counter Gems

O caminho foi revisado de `main.gd` e máscaras de entrada até `Match.tick()`, `GemMotion.step()/resolve_frame()`, tabuleiro, resolução de ondas, ataques, top-out e `MatchSession.record_round()`.

| Critério solicitado | Evidência atual e alcance |
|---|---|
| Rotação e quatro orientações | Física 112 casos, controles 33 e matriz orbital 80 passos; dois sentidos, paredes e corredores medidos |
| Colisão/contato de 16 quadros | Traços da física e V10.3.2; contador 16..1, depósito seguinte |
| Giro durante contato/travamento | Giro permitido em 15..2 e bloqueado em 16/1 nos ensaios; terceiro upkick e bloqueio cobertos pelas fixtures |
| Movimento lateral/perda de apoio | Repetição horizontal e máscaras; casos de saída de apoio na timeline; sem prolongar o contato para desenhar animação |
| Queda independente | Doze combinações de orientação/apoio/profundidade na V10.3.2 e quatro comparações PNG MAME |
| Próxima dupla | Transições das timelines e nova identidade visual; sem herdar resíduo orbital da dupla anterior |
| Destruição e duas/três ondas | Cinco cenários de destruição e seis de cadeias; teste adicional de três ondas na apresentação |
| Gravidade intermediária | Dois cenários específicos; queda por linha entre remoções, sem antecipação de ondas na arena |
| Ataques simultâneos/cancelamentos | Seis cenários medidos, além de fidelidade de ataques e invariantes de duelo |
| Counter Gems | Entrega na linha superior, fases 18/19, queda por quadro e retorno à próxima dupla; categorias específicas nas 22 fixtures |
| Pontuação/top-out/rounds | Fidelidade 247, regras 34, duetos e 1.000 séries MD3; placar e sorteio não são recalculados por efeitos gráficos |

A V10 preserva o RNG e o modelo de controles V9 como arquivos; o relógio físico e a resolução temporal foram mudanças deliberadas V10.2. Preservação da V9 significa manter suas fontes/fixtures/histórico e aprovar suas regressões, não manter idênticos os 11 arquivos que a V10 precisou evoluir.

## 4. Animações e fidelidade visual

- **Rotação orbital:** contadores 7..0 e deslocamentos discretos das tabelas observadas. A cena atual foi recapturada, com testes da ponte real, pausa, reinício e sentidos opostos de P1/P2. A comparação de 80 pares valida máscara, sobreposição e ordem dos corpos, sem exigir RGB igual entre as artes.
- **Ghost:** o teste atual percorreu o caso até a remoção e as três ondas, exigindo que uma célula desaparecida não reapareça. A arena acompanha a onda corrente; a máscara não retorna a uma gema lógica ainda pendente por terminar uma animação independente cedo demais.
- **Explosões:** a remoção e a gravidade acompanham os marcos lógicos reais e os efeitos são emitidos por onda. **Não há certificação integral da cronologia dos tiles nativos de explosão.** Em exemplos MAME, o corpo some antes da remoção lógica; a apresentação CS conserva o corpo até a remoção real. A ausência do Ghost não prova que essa diferença desapareceu.
- **Compressão/pouso:** não se aplicou squash elástico por estimativa. Os contornos isolado/intermediário/conectado e o halo nos casos medidos foram comparados em pixels normalizados. A ligação aferida é especialmente limitada ao par vertical azul apoiado e ao halo P1 azul/verde documentado.
- **Power:** formação 2×2, expansão 2×3 e união 3×2+2×2→5×2 acompanham as regiões e dimensões atuais. A fase final da união não é antecipada em dez quadros. A sequência A→B→C→D→C→B→A tem seis blocos de transição de oito ticks, terminando em A persistente após 48 ticks.
- **Por célula/região:** o crescimento reinicia as células cujos descritores mudam, inclusive células antigas. Regiões independentes e tabuleiros distintos mantêm relógios próprios. P1/P2 foram exercitados nos testes Godot; todas as cores/geometrias de P2 não foram certificadas contra MAME.
- **Bordas/interior:** controle com/sem overlays em 181 quadros confirma alteração apenas nas fases/células ativas e preservação do perímetro protegido da arte CS. Isso não equivale a uma comparação da silhueta nativa Power com o MAME. Os 12 overlays são arte procedural do projeto.

Alinhamento temporal Power: **Godot F = CPU MAME F+1**, sem realinhar cada ciclo. Foram comparadas 256 amostras da formação, 336 do crescimento e 600 da união, incluindo os preâmbulos. Godot F65 da formação permanece identificado como quadro sem CPU F66 na fonte: não foi inventado um par. PNG do MAME, CPU e callback de vídeo têm relógios distintos, com convenções registradas nos comparadores anteriores.

As fontes MAME são históricas, preservadas e reanalisadas nesta auditoria. Não foi feita nova coleta no emulador. As imagens Godot, logs e resultados citados como atuais foram produzidos nesta execução.

## 5. Achados de auditoria — sem correções de código

### Bloqueadores funcionais

Nenhum novo bloqueador funcional foi demonstrado nas execuções completas com dados reais desta auditoria. Os problemas abaixo continuam presentes e foram registrados, sem alterar arquivos do jogo, testes ou fixtures.

### Devem ser corrigidos em manutenção autorizada

1. **Dois validadores aprovam conjuntos vazios** — `godot/tests/test_gem_timeline.gd:89` e `godot/tests/test_power_facet_capture_v10_3_4.gd:45`.
   - O que são: verificadores da física contra fixtures e da estrutura das capturas Power.
   - Problema reproduzido: um JSON externo `{ "cases": [] }` produz `cases=0/112 samples=0/0` e saída 0; uma lista externa `[]` produz `checks=0 captures=0` e saída 0. Os arquivos sintéticos foram criados exclusivamente em `work/`, sem tocar nas fixtures originais. São **falhas dos validadores**, não testes negativos aprovados porque o processo encerrou sem erro.
   - Menor correção futura: exigir cobertura não vazia e os totais/cenários esperados antes de aprovar; no teste físico, também condicionar o sucesso aos 112 casos. O comparador Python Power já rejeitou corretamente o conjunto vazio na mesma auditoria.
   - Se adiado: uma automação que olhe somente o código de saída pode dar um falso verde após truncamento de dados. Isso não invalida os resultados atuais: 112/14.072 e 181/1.407 foram conferidos explicitamente, com os conjuntos originais intactos.

2. **O comando gráfico padrão ainda usa o teste histórico com espera insuficiente** — `scripts/validar_fluxo_partidas.py:42`, `godot/tests/test_match_flow.gd:99` e `:105`.
   - O que é: o executor seleciona `test_match_flow.gd` também para `--visual`.
   - Problema reproduzido: Enter chega antes da guarda de 0,2 s após revelar a moeda; a seleção não abre e o teste termina com 0/4 partidas. O adaptador V10.3.4, que espera 0,25 s adicionais após a captura do resultado, concluiu 4/4 mantendo as asserções herdadas.
   - Menor correção futura: o executor gráfico selecionar o adaptador existente. Nenhuma mudança em controles ou regras é necessária.
   - Se adiado: o comando gráfico padrão pode continuar falhando na reprodução/CI. A auditoria registra a falha original e a repetição com adaptador separadamente; não chama o conjunto inteiro de execuções de “tudo PASS”.

3. **Documentos de entrada ainda descrevem estados anteriores à V10** — `README.md:19`, `ARQUITETURA_GODOT.md:20` e `:26`.
   - O que são: as primeiras instruções que um novo usuário ou revisor encontra.
   - Problema concreto: o README ainda diz “A V10 não foi iniciada”; a arquitetura menciona sete falhas naturais e resolução imediata, embora os resultados atuais sejam 119/119 e resolução temporal.
   - Menor correção futura: marcar claramente os trechos como históricos e apontar para este relatório/continuidade, atualizando a descrição corrente. Nenhuma documentação histórica precisa ser descartada.
   - Se adiado: quem recebe v0.10.0 pode interpretar incorretamente o estado da implementação e seus limites. A continuidade foi atualizada como referência corrente; os outros documentos não foram editados nesta auditoria.

Não foram propostos refactors por tamanho de arquivo, novas dependências ou mudanças cosméticas. As limitações já assumidas explicitamente não são apresentadas como bugs novos.

## 6. Limitações que permanecem

1. **RNG:** `ArcadeRng.advance()` e 866 observações estão validados, mas isso não prova igualdade de todos os consumidores globais CPS-2. `MatchModel` ainda gera as cores com `RandomNumberGenerator` do Godot, seed fixa 96, Crash periódico e Diamond a cada 25ª dupla. O gerador completo de peças do arcade não foi certificado. `locked_residual` injeta índices observados nas fixtures; resultados com ele não certificam o consumo RNG de uma partida natural inteira.
2. **Arte/tempo visual:** os sprites CS diferem dos originais. Permanecem os limites de explosão, cores/geometrias de ligação, P2 completo e todos os scripts nativos de facetas. Zero diferença de máscara em casos medidos não significa igualdade RGB ou fidelidade visual completa.
3. **Dependências locais:** os executores usam Godot portátil em `ferramentas/godot_4.7.2`; comparadores procuram coletas em `laboratorio/`, ignoradas no Git. ROM, save state e dumps não são parte da release. O comparador de facetas tem nomes de sessões fixos e o gerador tem `OUT_DIR` absoluto. A reprodução integral em outra máquina exige as fontes locais e ajuste dos caminhos apropriados. Os sprites próprios já estão rastreados e não precisam ser regerados para jogar.
4. **Testes gráficos:** teclado/gamepad são eventos programáticos; não se testou um controle físico. Foram abertas janelas OpenGL reais em NVIDIA RTX 5070 e inspecionadas capturas, mas não houve sessão humana prolongada nem teste em outros sistemas/GPU. A janela 1280×900 reportou framebuffer 1280×896 no teste existente; isso foi registrado pelo teste, sem erro de execução.
5. **Carga e duração:** o lote confirmou 1.000 séries integradas com desfechos controlados. Não certifica ausência de todo vazamento, sessões naturais ilimitadas ou sincronização bit a bit de partidas inteiras. Não houve teste de rede, pois o produto auditado é um duelo local de dois tabuleiros.
6. **Empacotamento:** não foram exportados nem certificados instalador/EXE independente, Web, Linux ou macOS. A recomendação é sobre a versão de código executada com o Godot local, não um binário novo distribuível.

## 7. Evidências, execução e distinção histórica

Coleção integral desta auditoria:

`C:\Users\MauTrIX\Documents\Codex\2026-11-03\continuar-counter-strike-puzzle-fighter-96\outputs\v10_final`

- `existing/`: 17 baterias, comandos, stdout/erros, render/UI e resumos desta execução; `legacy_current/` preserva os resultados novos de testes com destinos históricos fixos, restaurados depois.
- `gem_timeline/`, `chains/`, `v10_3_2/`, `v10_3_3/`, `v10_3_4/`: resultados atuais específicos.
- `matches_1000/`: quatro logs, relatórios completos, NDJSON por série e checkpoints; `summary.json` agrega os resultados novos.
- `matches_visual_historical/` e `matches_visual/`: tentativa sem adaptador e execução atual com adaptador, incluindo 30 imagens finais.
- `power_render/render/`: 181 capturas + 181 controles; `power_comparison/` e `power_structure/` contêm os confrontos atuais.
- `v10_3_2_render/render/`: 172 capturas novas; CSVs de contato/queda junto ao diretório de renderização.
- `rotation_render/render/`: novos registros de rotação e controles; `rotation_capture_masks/` e `rotation_current_comparison/`: validação das capturas atuais, incluindo os 80 pares MAME.
- `rotation_masks/`: reanálise atual das capturas Godot antigas, identificada separadamente.
- `rotation_current_sources.json`: proveniência. O comparador original não foi editado; uma estrutura temporária em `work/` usa hard links somente para leitura, apontando os caminhos esperados às novas capturas e às fontes nativas preservadas.
- `negative_probes.json`, `probe_empty_*`: reprodução das duas aprovações incorretas de dados vazios e da rejeição correta do comparador Python.
- `resources/`, `smoke/`, `summary.json`, `preservation.json`, `git_final.json`, `MANIFESTO_SHA256.json`, `GALERIA.html`: configuração, integridade, limites e seleção gráfica.

Os relatórios antigos V9/V10.x foram lidos para escopo e comparações de integridade. Suas afirmações não substituem novas execuções. A validação nativa anterior foi usada somente para reconhecer avisos herdados; o relatório atual contém sua própria execução. Nenhuma aprovação atual depende de executar um MAME novo ou de aproveitar o total histórico das 1.000 séries antigas.

Comandos centrais reproduzíveis, sempre apontando `PF_REPORT`/`--output` para uma pasta nova:

```powershell
python scripts/validar_apresentacao.py --render --output <saida_nova>
python scripts/validar_fluxo_partidas.py --matches 1000 --workers 4 --output <saida_nova>
# Godot local, com --path godot:
# --headless --script res://tests/test_gem_timeline.gd -- --fixtures=<fixture> --out=<novo_json>
# --headless --script res://tests/test_chain_counter_timeline.gd -- --out=<novo_json>
# --headless --script res://tests/test_visual_timeline_v10_3_2.gd
# --headless --script res://tests/test_pair_rotation_visual_v10_3_3.gd
# --headless --script res://tests/test_power_facet_v10_3_4.gd
# Sem --headless: --script res://tests/test_match_flow_visual_v10_3_4.gd -- --visual
```

Os comandos completos, argumentos absolutos, duração e código de saída constam em `execution.json` de cada execução. O executor da auditoria guardou/restaurou os bytes dos relatórios históricos de caminhos fixos; não se alteraram testes para redirecioná-los.

## 8. Decisão e estado final

**Veredito: V10 estável no escopo funcional e visual medido; recomendo liberar v0.10.0 com as limitações explicitadas.** Os cenários solicitados com dados reais passaram; a falha conhecida do teste gráfico e as duas lacunas dos validadores foram reproduzidas e continuam abertas. Não são apresentadas como regressões do jogo nem ocultadas em um total agregado de aprovação.

Esta conclusão exige que a versão continue sendo apresentada como o duelo CS com física/tempos medidos, e não como réplica integral de MAME. Para CI/reprodução automática, priorizar os validadores de cobertura e o uso do adaptador gráfico em manutenção posteriormente autorizada. Antes de anunciar a versão, é recomendável alinhar os documentos de entrada ao estado atual.

Nenhuma funcionalidade foi implementada. Código, testes, fixtures, núcleo, RNG, controles, `main`, tags e os dois arquivos locais originais foram preservados. As únicas alterações esperadas no projeto são este relatório/resumos novos e a atualização necessária da continuidade. O índice permanece vazio; não houve commit, push ou tag. A criação de v0.10.0 depende de autorização posterior.

Não verificado: todos os consumidores RNG/64 KiB de RAM, MAME novo, igualdade integral de arte/explosões, todas as geometrias/P2, periféricos físicos, outras plataformas, exportação binária e mil partidas naturais sincronizadas com o arcade. A leitura de código se concentrou no caminho do jogo e seus validadores, não em revisar integralmente todas as ferramentas históricas de laboratório.

## 9. Nota posterior — preparação do encerramento documental

Em 03/11/2026, o usuário autorizou a preparação exclusivamente documental do encerramento da V10. README e arquitetura foram atualizados para o estado temporal/visual auditado, e a continuidade registra auditoria aprovada com ressalvas, aguardando registro autorizado e publicação de v0.10.0. O achado 3 descreve a situação encontrada na auditoria e foi tratado documentalmente nesta etapa; os achados 1 e 2, relativos aos validadores e ao executor gráfico, permanecem abertos.

Os resultados e contagens deste relatório e de `summary.json` não foram alterados. Não houve nova execução de testes, correção de código, teste ou fixture. A auditoria original foi preservada na entrega externa antes deste acréscimo. O estado documental corrente e a lista de documentos selecionados constam em [ENCERRAMENTO_DOCUMENTAL_V10.md](ENCERRAMENTO_DOCUMENTAL_V10.md). A preparação no índice não é um commit nem autorização automática de merge, push ou tag.
