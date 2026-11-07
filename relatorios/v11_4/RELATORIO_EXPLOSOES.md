# V11.4 — Reconstrução visual das explosões

**Estado: implementação validada tecnicamente; aprovação artística pendente do usuário. V11.4 permanece aberta.**

Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`. Coordenador: GPT-6 — ChatGPT. Data: 06/11/2026, America/Sao_Paulo. Branch `feature/v11-hud`, HEAD `1a943a4db4d1dba84a222735187afb6108b4c4c5`, base estável `v0.10.0`. Nenhum commit, tag, push, merge ou alteração de refs.

## Recuperação após a interrupção

A inspeção retomou o trabalho existente, sem recriar a implementação ou repetir baterias aprovadas. A execução final que estava em andamento terminou e gravou às 03:19:50 **14.018 verificações, zero falhas**, depois da mudança de cotas P1/P2. Seu teste inclui explicitamente `mote_counts == [160,160]`, o recorte dos efeitos e a ausência de interceptação dos controles. O resultado não se limita às duas baterias anteriores de 12.949 e 13.934 checks.

Os timestamps das fontes finais antecedem esse resultado. Foram conferidos console, JSON, resumos de execução e fontes. Na retomada foram gerados a galeria, este relatório, o resumo consolidado e as verificações de integridade; os testes Godot/Python já concluídos não foram repetidos desnecessariamente.

## Auditoria e recursos reaproveitados

A apresentação já possuía explosão e shatter com seis quadros cada, shockwave, relâmpago, flashes, estilhaços em cinco paletas e três variantes, rotação, gravidade visual e dissipação. Esses recursos foram mantidos. Nenhum PNG de jogo foi substituído, nenhuma imagem de ROM foi importada e nenhum pacote foi instalado.

Foram examinados os documentos/testes V8, V9, V10 e V11. A V10 liga o impacto à remoção lógica da onda e corrige o reaparecimento de gemas removidas. Essa fronteira foi preservada. O Showcase já tinha antecipação, mas o caminho temporal não recebia integralmente seus acentos visuais. As Power Gems temporais retornam do renderer antes de determinados efeitos decorativos legados; a nova camada observa a onda corrente sem mudar esse renderer ou sua geometria.

Recursos reutilizados: `vfx_explosion_0..5.png`, `vfx_shatter_0..5.png`, seus sprites base, `vfx_shockwave.png`, `vfx_lightning.png`, `vfx_shard_<cor>_<variante>.png`, sprites Crash, C4 e cristais Power. Permanecem as animações dos personagens, projéteis, banners e facetas Power já existentes. Não foi introduzido bloom de tela inteira nem um novo sistema genérico de partículas.

## Arquivos modificados e criados

Único arquivo preexistente alterado pela V11.4:

- `godot/presentation/cs_arena.gd`: instancia o componente visual; observa a antecipação; emite VFX no impacto real; atualiza e limpa o componente; liga a camada aditiva; acrescenta transparência/reflexo aos estilhaços existentes e escalonamento visual curto em cadeias grandes. Corrige também a identificação da cor **somente de apresentação** da C4 temporal: código 5 recebe a paleta especial 5, em vez do zero retornado pelo extrator de cor normal.

Criados:

- `godot/presentation/gem_destruction_vfx.gd`: observação determinística de ondas e camadas aditivas recortadas por poço.
- `godot/tests/test_gem_destruction_v11_4.gd`: casos reais de resolução, comparação com a apresentação V11.3, invariância do modelo, limites, desempenho e captura.
- `relatorios/v11_4/RELATORIO_EXPLOSOES.md`: este relatório.
- `relatorios/v11_4/GALERIA_EXPLOSOES.html`: revisão antes/depois, etapas e animações.
- `relatorios/v11_4/run_validation.py` e `make_gallery.py`: executores locais.
- Evidências, logs, referências derivadas, inventários e JSONs nesta pasta; resumo principal em `summary.json`.

O inventário inicial contém 860 arquivos preexistentes, incluindo as evidências V11.3. Os hashes finais indicam alteração somente em `cs_arena.gd`. Permanecem intactos `match_model.gd`, `board_model.gd`, todo o núcleo inventariado, dados, assets, controles, `main.gd`, HUD Presenter, testes V11.2/V11.3, planejamento, continuidade já modificada e os demais arquivos inventariados. A função completa de desenho do HUD/NEXT e as quatro constantes de geometria NEXT foram comparadas com a cópia pré-V11.4 e são idênticas. O Cezar e outros projetos não foram modificados.

A comparação é com a base local V11.3, que já continha trabalho não commitado. `main.gd` e a continuidade continuam modificados perante o HEAD por etapas anteriores; não são mudanças novas da V11.4. Não houve staging.

## Efeitos implementados

### Gemas comuns e Crash

O brilho interno cresce em seis estágios discretos durante o `clear_timer` real. O corpo da gema não desaparece antecipadamente. No impacto há núcleo aditivo curto, acentos luminosos e o shatter existente. Os estilhaços mantêm rotação/gravidade visual, recebem transparência limitada a 0,86 e reflexo facetado intermitente. Faíscas em pixels deixam pequenos rastros e se dissipam.

As quatro cores foram exercitadas. As Crash preservam os sprites circulares e recebem núcleo pulsante, anel de ativação e explosão na paleta correspondente. A antecipação é observada da onda; nenhuma espera foi acrescentada à simulação.

### Power Gems

A emissão de vidro existente ocorre por célula destruída e cresce com a área. Há um evento luminoso por formação e partículas distribuídas pelo perímetro. A onda usa a proporção real da formação: 2×2 compacta, 2×3 vertical e 5×2 horizontal, esta com acento transversal adicional. Asserções conferem os extents contra as dimensões reais da Power.

| Formação | Pico de fragmentos de vidro existentes | Pico de novas partículas luminosas |
|---|---:|---:|
| 2×2 | 22 | 18 |
| 2×3 | 30 | 24 |
| 5×2 | 46 | 47 |

Os números incluem a Crash que dispara a destruição e o cenário usado. O flash aditivo de cada evento tem dois ticks; o flash de impacto legado mantém cinco ticks. Em aproximadamente 59,637 ticks/s, isso corresponde a 33,5 e 83,8 ms. As ondas novas duram 12, 18 ou 22 ticks conforme o tipo; as partículas têm vida e atraso limitados. Os fragmentos legados continuam com suas próprias durações curtas e desaparecem completamente.

### Combos

A intensidade combina número de células removidas e nível real da cadeia, em três faixas. Ondas maiores adicionam anéis, partículas e acentos em camadas; células podem distribuir esses acentos por até dois ticks visuais. A ordem real da resolução permanece intacta e não há atraso de física, gravidade, ataque ou troca de turno.

O teste de cadeia média observou impactos nos frames **54, 121 e 191**; o grande, **54, 121, 191, 250 e 322**. Cada evento visual corresponde à contagem real de ondas. As capturas incluem o flash de cada onda, inclusive a quinta.

### C4

A LED acelera em períodos visuais de seis, quatro e dois ticks ao longo da antecipação. No momento da remoção real são emitidos um evento central especial, flash, onda de choque, faíscas radiais e dissipação; os sprites C4 existentes continuam sendo desenhados. O teste exige um único evento central C4 e compara o estado completo do modelo com a versão anterior.

### Determinismo, recorte e simultaneidade

Não existe chamada a RNG no componente. Ângulos e variações são calculados por índices de células, cadeia e número da partícula. Eventos iguais produzem os mesmos dados e o mesmo ciclo de vida. Redraws em pausa não avançam os relógios.

A luz aditiva usa `CanvasItemMaterial.BLEND_MODE_ADD` em dois filhos, recortados em 192×384 px dentro dos poços. Eles ignoram mouse e não capturam controles. São reutilizados nas mudanças de cenário/reset; não são recriados por partícula. O componente não altera o material do tabuleiro ou do HUD.

O limite total do componente novo é **192 eventos de brilho e 320 partículas luminosas**, com reservas de 96 e 160 por jogador. Assim P1 não esgota o orçamento de P2 em uma explosão simultânea. Esses limites não representam o total de todos os VFX legados do jogo. No estresse de duas formações com 60 células cada, foram observados 122 eventos novos, 320 partículas novas e 484 estilhaços legados.

## Testes realmente executados

Todos os resultados abaixo pertencem à implementação V11.4 desta execução contínua. Foram recuperados dos artefatos após a pausa; não são resultados históricos copiados da V10. O resumo consolida **27 execuções finais aprovadas**, sem somar novamente as baterias intermediárias.

| Teste | Resultado |
|---|---|
| Explosões V11.4 | **14.018 checks, zero falhas**, 13 cenários |
| Equilíbrio sob carga máxima | cota explicitamente testada: **160 partículas por jogador** |
| V11.2 presenter, inalterado | 3.931 checks, 7 suítes, zero falhas |
| V11.2 cena, inalterada | 1.013 checks, 1.000 consultas, pixels idênticos entre leituras |
| V11.3 NEXT, inalterado | 1.072 checks, zero falhas; próxima dupla real e referência V10 |
| Modelos | `GODOT_TESTS_OK` |
| Regras | 34 checks |
| Fidelidade | 247/247 |
| Controles / RNG | 33/33; 866 amostras |
| Partidas naturais | 119/119 endpoints |
| Duelo | 1.500 turnos; 28 partidas; 227 ondas |
| Apresentação | 3.285 checks |
| Coin Flip / seleção | 40.195 / 3.351 checks |
| Timeline V10.3.2 | 123.863 checks; sem retorno de gemas removidas |
| Rotação V10.3.3 | 119.052 checks; 80 passos principais, 11.957 amostras ativas |
| Power V10.3.4 | 394 checks |
| Animação V8 / arte V9 | 145 / 102 checks |
| Física | 112/112 casos; 14.072/14.072 amostras |
| Cadeias / Counter Gems | 22/22 casos; 5.066/5.066 amostras; 54 checks |
| Showcase UI | aprovado |
| Seleção UI | aprovado; 12 capturas, dois tamanhos de janela |
| Fluxo gráfico MD3, adaptador V10.3.4 | 4/4 séries; 10 rounds; 276 checks |
| Python | 28 testes OK |
| Lint | zero erros; 11 avisos |
| Validação nativa | zero erros; 72 avisos |
| Smoke com fuzz | 4/4 cenas; zero erros; 98 avisos acumulados |
| Galeria, verificada na retomada | referências de imagens existentes; JavaScript com sintaxe válida |

Os avisos mantêm as contagens da V11.3; aprovação não significa ausência de avisos. O smoke tem uma observação informativa porque a moeda avança para seleção; a seleção também foi exercitada separadamente.

O teste V11.4 roda dois modelos idênticos e duas apresentações: a atual e a cópia V11.3 guardada antes da edição. A cada tick verifica que a apresentação não escreve no modelo e que os estados continuam iguais, incluindo RNG/seed, stream, duplas, índices, turnos, timers, scores, tabuleiros e ataques. Também verifica que as células desenhadas acompanham as células reais, que todos os impactos esperados ocorreram e que os efeitos expiram. Os casos são controlados por fixtures/resolvedor real; não representam novas partidas completas sincronizadas ao MAME.

Os três relatórios de fidelidade escritos em caminhos fixos foram guardados e restaurados pelo executor. `historical_restoration.json` confirma a restauração byte a byte. Os resumos detalhados são `vfx_summary.json`, `focused_summary.json`, `regression_summary.json` e `checks_summary.json`; comandos/saídas ficam em cada subpasta de `evidence/`.

## Desempenho e leitura

Ambiente observado: Windows, Godot 4.7.2, OpenGL/NVIDIA RTX 5070, canvas 1000×700. Sem outro teste Godot concorrente durante a medição final de VFX.

| Atualização da apresentação na CPU | V11.3 de referência | V11.4 |
|---|---:|---:|
| Mediana | 0,056 ms | **0,066 ms** |
| Percentil 95 | 0,115 ms | **0,134 ms** |
| Máximo observado | 2,928 ms | **2,983 ms** |

A diferença entre medianas é 0,010 ms nesse ensaio. Isso mede `step_from_model`, não o custo completo de desenho dos novos acentos. A medição de redraw abaixo inclui agendamento/sincronização e ambos os viewports da comparação; os draw calls também são globais ao ensaio. Não se convertem esses números em promessa de FPS nem em benchmark isolado de GPU.

| Cenário | Redraw/sincronização mediana | P95 | Máximo |
|---|---:|---:|---:|
| Power 5×2 | 4,296 ms | 5,449 ms | 5,644 ms |
| Combo de cinco ondas | 5,143 ms | 5,692 ms | 6,029 ms |
| C4 | 4,644 ms | 6,060 ms | 6,443 ms |
| Simultâneo 5×2 | 4,795 ms | 7,492 ms | 7,560 ms |
| Estresse, 120 células simultâneas | 5,745 ms | 12,552 ms | 14,312 ms |

No estresse foram registrados até 2.437 draw calls globais aos dois viewports. Essa carga é deliberadamente extrema e permanece mais densa e custosa. A medição isolada de uma única cena/GPU, proposta antes do bloqueio de créditos, não chegou a ser executada; os resultados efetivamente disponíveis são os descritos acima.

Nos frames amostrados aos 5, 12 e 25 ticks após o primeiro impacto, a fração máxima de pixels quase brancos do poço foi **0,3418%**. O teste usa amostragem a cada dois pixels e exige menos de 12%. Isso detecta um apagamento branco amplo, mas **não mede toda a oclusão causada por fragmentos coloridos nem aprova a legibilidade artisticamente**. O estresse produz uma massa visível de estilhaços verdes; sua densidade e a clareza durante o movimento devem ser avaliadas pelo usuário.

## Evidências visuais para avaliação

Abrir a galeria local:

`C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\GALERIA_EXPLOSOES.html`

Há 13 cenários, seletor de etapa, visão completa/poço P1 e comparação lado a lado. As sequências animadas têm PNGs capturados a cada dois ticks, sem saltos: Power 5×2 (90 quadros), combo grande (179 quadros) e C4 (90 quadros), com versão anterior e atual sincronizadas. São recortes reais do poço P1, não imagens retocadas. A reprodução HTML usa aproximadamente 29,82 imagens/s e depende do browser/disco; não é uma medição de FPS.

Cada cenário contém pares `_before.png` / `_after.png` para antes, ativação, flash, fragmentação, partículas, dissipação e resultado final. Também há flash por onda e detalhes do poço. `06_result` significa 55 ticks após o primeiro impacto, podendo haver outras ondas; `07_final` é a captura após o término do ensaio e a drenagem dos efeitos. A drenagem avança apenas a apresentação por mais 100 ticks, com a simulação congelada, para testar a limpeza.

Os caminhos completos dos pares representativos são:

| Cenário | Antes | Depois |
|---|---|---|
| Azul / Crash azul | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_1\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_1\03_fragments_after.png` |
| Amarelo / Crash amarela | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_2\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_2\03_fragments_after.png` |
| Verde / Crash verde | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_3\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_3\03_fragments_after.png` |
| Vermelho / Crash vermelha | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_4\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\color_4\03_fragments_after.png` |
| Power 2×2 | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_2x2\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_2x2\03_fragments_after.png` |
| Power 2×3 | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_2x3\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_2x3\03_fragments_after.png` |
| Power 5×2 | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_5x2\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\power_5x2\03_fragments_after.png` |
| Combo pequeno | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_small\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_small\03_fragments_after.png` |
| Combo de três ondas | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_medium\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_medium\03_fragments_after.png` |
| Combo de cinco ondas (quinta onda) | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_large\wave_05_flash_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\combo_large\wave_05_flash_after.png` |
| C4 | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\c4\04_particles_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\c4\04_particles_after.png` |
| Simultâneas 5×2 | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\simultaneous\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\simultaneous\03_fragments_after.png` |
| Estresse simultâneo 120 células | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\stress_simultaneous\03_fragments_before.png` | `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_4\evidence\explosions\stress_simultaneous\03_fragments_after.png` |

As etapas adicionais são `00_before`, `01_activation`, `02_flash`, `03_fragments`, `04_particles`, `05_dissipation`, `06_result` quando alcançada e `07_final`. Todos os cenários têm as etapas obrigatórias e um resultado final. Cada etapa possui os mesmos sufixos `_before.png` e `_after.png`. Para a quinta onda, a galeria inclui `combo_large/wave_05_flash_before.png` e `wave_05_flash_after.png`.

Foram inspecionadas visualmente as capturas finais de Power 5×2, quinta onda, C4 e estresse simultâneo, além de capturas intermediárias de ativação/fragmentação durante a implementação. Essa inspeção verifica a entrega e suas limitações; a aprovação artística continua pendente.

## Reprodução e preservação

Os executores ficam nesta pasta e escrevem suas próprias evidências no jogo. Não é necessário repetir os testes para revisar a arte. Se uma futura alteração exigir nova execução, preserve as evidências atuais antes de rodar, pois o executor usa nomes fixos:

```powershell
python -B relatorios/v11_4/run_validation.py vfx
python -B relatorios/v11_4/run_validation.py focused
python -B relatorios/v11_4/run_validation.py regression
python -B relatorios/v11_4/run_validation.py checks
python -B relatorios/v11_4/make_gallery.py
```

O teste gráfico depende de `arena_before.gd.txt`, a cópia local exata da apresentação V11.3 pré-edição, e de `PF_REPORT`, configurado pelo executor. O `.gitignore` atual ignora a maior parte dos logs, imagens e scripts locais de relatórios; nenhum foi preparado para commit. `initial_manifest.json`, `integrity.json` e `validated_source_hashes.json` documentam a preservação e as fontes verificadas.

## Problemas, riscos e pendências

- A última alteração funcional dividiu as cotas de partículas igualmente entre os jogadores. A execução final de 14.018 checks confirma as cotas e a simultaneidade; não há falha técnica aberta identificada nesses ensaios.
- As baterias intermediárias aprovadas permanecem preservadas em `evidence/explosions_first_pass/` e `evidence/explosions_before_budget_balance/`. Os números finais e a galeria usam exclusivamente `evidence/explosions/`.
- O bloqueio de créditos interrompeu a criação de uma medição adicional de performance; não apagou a implementação. A bateria final já iniciada terminou e foi recuperada na retomada. Não foi instalado ou recriado um benchmark desnecessário.
- Os avisos herdados do projeto permanecem. A densidade em explosões de tabuleiro inteiro é uma limitação visual a avaliar, não algo certificado pelo teste de pixels quase brancos.
- Não houve nova coleta MAME, comparação integral pixel a pixel com CPS-2, teste em outra GPU/plataforma, periférico físico, exportação de binário nem repetição das 1.000 séries históricas. A referência CPS-2 é artística; não se declara equivalência integral de sprites ou cronologia nativa de explosões.
- O núcleo, RNG, geração, regras, gravidade, controles, turnos, score, ataques, HUD Presenter e NEXT foram preservados. Não foi iniciada a V11.5.

**Próximo passo: avaliação e aprovação artística pelo usuário, ou solicitação de ajustes visuais específicos. A V11.4 não está encerrada.**
