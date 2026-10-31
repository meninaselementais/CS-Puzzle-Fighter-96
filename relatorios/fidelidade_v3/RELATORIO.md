# Fidelidade — Counter-Strike Puzzle Fighter '96

Data: 28/10/2026. Projeto existente: `C:\Projetos\CS-Puzzle-Fighter-96`. Arcade ensaiado: **Super Puzzle Fighter II Turbo USA 960620, `spf2tu`, MAME 0.289**. Protótipo: Godot 4.7.2, dois jogadores locais. O projeto foi evoluído, preservando a revisão anterior em `revisoes/antes_mecanicas_20261028_163108`.

**Entrega jogável:** `Jogar.cmd`. Implementados Power Gems, Crash Gems, Counter Gems, combos, cadeias, gravidade, pontuação, ataques, contra-ataques e vitória/derrota. A interface distingue os tipos, mostra pontos e fila de ataque e permite reiniciar a partida. P1: setas e Z/X; P2: A/D/S e Q/E.

**Fidelidade medida: 80 de 86 comparações exatas.** Todas as 68 comparações de resolução e as seis de contra-ataque coincidiram. Das 12 recepções, seis coincidiram célula a célula e seis diferiram na escolha de colunas para linhas incompletas. Isso não representa 93% de fidelidade do jogo inteiro: é somente o resultado deste conjunto finito de ensaios.

## Evidência e repetibilidade

As sessões finais são:

- `laboratorio/auto_20261028_170224_464031`
- `laboratorio/auto_20261028_170328_077802`

Cada processo executou os mesmos **81 cenários**, com **23.700 quadros registrados**. O verificador confirmou **4.195 dumps de RAM idênticos**, nenhum dump diferente e CSVs idênticos entre os processos. O estado salvo e o hash da Lua também coincidiram. Resultado em `reproducibilidade.json`.

Cada cenário restaura uma cópia do estado reproduzível anterior, depois de soltar as entradas e avançar três quadros neutros. As configurações controladas são escritas **somente na RAM da emulação de laboratório**, com endereço, antes e depois em `injection.csv`. O arcade calcula os resultados. Capturas binárias e imagens são produzidas automaticamente, sem etapas manuais.

Esses testes isolam o resolvedor. Não demonstram que toda configuração sintética apareceria naturalmente numa partida, nem que cada quadro da animação do protótipo replica o original. O estado inicial contém Ryu e Ken e a mesma dupla conhecida; a sequência aleatória completa não foi reproduzida.

`fixtures_final.json` e `godot/data/mechanics_fixtures.json` guardam entradas e resultados extraídos do arcade, quadros de origem/destino e hashes do CSV e da Lua. A normalização remove flags gráficas, preservando cor, tipo, contador e geometria Power. O resultado esperado não é calculado pelo código Godot.

## Resultado por mecânica

| Mecânica | O que corresponde ao arcade nos casos medidos | Limite atual |
|---|---|---|
| Power Gems | Retângulos a partir de 2x2; linhas e L não formam Power; crescimento 2x2→2x3; união de dois blocos por ponte →5x2; limite de oito linhas nos retângulos altos ensaiados | Empates entre várias decomposições possíveis de formas irregulares ainda não foram esgotados |
| Crash Gems | Conexão ortogonal da mesma cor; destruição de normais, Crash e Power; duas Crash iguais bastam; diagonal isolada não conecta | Outras situações de animação/interrupção e todas as cores por combinação ainda não foram enumeradas |
| Counter Gems | Cor e contador preservados; 5→4→3→2→1→normal após cinco assentamentos próprios; destruição colateral por contato ortogonal, independentemente da cor | Tempos da transformação não são reproduzidos quadro a quadro |
| Colateral | Counter diretamente adjacente desaparece; efeito não se propaga por outra Counter; contato diagonal sobrevive | Colateral em ondas posteriores ainda precisa de calibração de pontos |
| Combos e cadeias | Dois componentes simultâneos e cadeia de duas ondas produzem o mesmo tabuleiro, pontos e ataque | Três ou mais componentes/ondas e misturas extensas ainda não foram validados |
| Gravidade | Queda após destruição; queda que dispara nova cor; Power permanece rígida se uma borda continua apoiada | Animação e duração de queda/resolução são simplificadas |
| Pontuação | 68 resultados de resolução coincidem, incluindo blocos grandes, Power conectadas, combo e cadeia; diferenciação entre queda natural e acelerada | Bônus de +10 de aceleração e primeiro ataque de +1000 foram observados neste perfil; variações não foram esgotadas |
| Envio/contra-ataque | Quantidades de ataque e seis pares de entrada/saída coincidem; teto observado de 99 | Acúmulos de várias ondas, ataques ímpares fracos e simultaneidade completa precisam de mais testes |
| Recepção | Quantidade e countdown=5; padrões medidos de Ryu e Ken; seis endpoints completos exatos | Seis endpoints diferem nas colunas das sobras; continuidade do padrão em vários ataques não confirmada |
| Vitória/derrota | Caso com entrada central bloqueada mostra LOSE/WIN no MAME; coluna lateral cheia não basta; protótipo usa a célula central correspondente | Empate, bloqueio nas linhas ocultas e resolução simultânea de perdas ainda não foram comparados |

Os resultados de vitória/derrota usam os casos controlados `topout_center`/`topout_side`, imagens do arcade e testes do modelo. Não fazem parte das 86 comparações automáticas de células/pontos/filas. A variável de estado do ator, isoladamente, não foi usada como oráculo de derrota.

## Pontos e ataques inferidos

Para os componentes medidos, o resolvedor usa:

1. 100 pontos por pedra normal ou Crash destruída.
2. Para as células Power do mesmo componente, soma das áreas e taxa por célula conforme a faixa observada.
3. Mais `10 × max(células do componente − 2, 0)` por componente.
4. Fator de combo `1 + 0,5 × (número de componentes − 1)` e fator de cadeia igual ao índice da onda.
5. Counter colateral: +20 por célula nos casos de primeira onda medidos.
6. Ataque da onda: parte inteira dos pontos/100, limitado a 99 nos casos grandes observados.

| Área Power somada no componente | Taxa aplicada por célula |
|---|---:|
| Até 9 | 200 |
| 10–17 | 250 |
| 18–24 | 300 |
| 25–39 | 350 |
| 40–48 | 400 |

As faixas interpolam áreas entre os formatos possíveis ensaiados; não são uma tabela extraída integralmente do programa. Somas superiores a 48 e combinações de vários blocos grandes continuam extrapoladas e marcadas no código.

Exemplos de deltas de resolução, sem os +10 de aceleração:

| Caso | Pontos arcade = Godot | Ataque arcade = Godot |
|---|---:|---:|
| Seis vermelhas, incluindo Crash | 640 | 6 |
| Power 2x2 + normal + Crash | 1.040 | 10 |
| Power 2x3 + normal + Crash | 1.460 | 14 |
| Combo de vermelho e azul | 1.260 | 12 |
| Cadeia: vermelho, depois azul | 640 + 400 | 6 + 4 |
| Power 5x8 + Crash | 16.490 | 99 |
| Duas Power conectadas no caso 4x10 | 13.270 | 99 |

Contra-ataques: se o ataque supera a fila recebida, cancela essa fila e envia a diferença. Se não supera, nos ensaios reduz a fila em metade da quantidade do ataque e não envia sobra. Pares confirmados: fila/ataque `6/10→0 e envia 4`, `10/6→7`, `6/6→3`, `10/10→5`, `6/7→0 e envia 1`, `10/8→6`. O arredondamento de um ataque ímpar que não supera a fila ainda precisa de ensaio; o protótipo arredonda a redução para baixo.

## Diferenças registradas

`comparacao.json` conserva as seis falhas, incluindo coordenadas e valores. O teste estrito retorna **1**, deliberadamente, enquanto essas diferenças existirem.

| Caso de recepção | Células com valor diferente |
|---|---:|
| `delivery_attack_red8` | 2 |
| `delivery_attack_cancel` | 2 |
| `delivery_score_normal_1` | 2 |
| `delivery_score_normal_2` | 2 |
| `delivery_score_normal_7` | 4 |
| `delivery_score_normal_8` | 2 |

Exemplo: no ataque de três pedras, o arcade escolheu colunas 0, 2 e 5; o protótipo usa 0, 1 e 2. Uma pedra muda de coluna, produzindo duas células diferentes. Essa escolha afeta a estratégia e impede considerar a recepção concluída em fidelidade. A quantidade recebida, a cor segundo a coluna e o contador continuam preservados.

Outras aproximações explícitas: RNG com semente 96, Crash provisória a cada cinco duplas, queda em 32 ticks, repetição de teclas, ausência dos ajustes laterais de rotação do arcade, resolução imediata, momento de entrega simplificado, padrões limitados a Ryu/Ken, continuidade do padrão de Ken entre entregas, limites de pontuação fora dos casos medidos e desempate de retângulos concorrentes. O tema visual usa formas próprias e ainda é um protótipo.

Escrever apenas no campo visual da fila (`FF857A`) no início ou no quadro 105 não criou uma fila persistente: o jogo recalculou o valor no quadro seguinte. Esses ramos foram mantidos como evidência de hipótese rejeitada e excluídos das fixtures de contra-ataque. Os seis casos válidos usam ataques gerados pelos próprios jogadores. O tap experimental de pontos ficou sem eventos; as fórmulas são inferências de deltas, não confirmação do escritor de pontuação.

## Endereços e representação observados

Todos os endereços são da RAM emulada do 68000; palavras e números compostos são big-endian.

| Campo | P1 | P2 |
|---|---|---|
| Base do ator | `FF8300` | `FF8700` |
| X da dupla, u16 | `FF8310` | `FF8710` |
| Y lógico, u16 | `FF8314` | `FF8714` |
| Deslocamento vertical, s16 | `FF8542` | `FF8942` |
| Rotação, byte | `FF8470` | `FF8870` |
| Marcador de assentamento observado | `FF84A0` | `FF88A0` |
| Pontos, u32 nos ensaios | `FF83AA` | `FF87AA` |
| Fila exibida de ataque, u16 | `FF857A` | `FF897A` |
| Grade | `FFAB00` | `FFAD00` |
| Metadados Power | `FFAF00` | `FFB100` |

Célula `(x,y)`: `base + y×16 + 2×(x+1)`, seis colunas e 14 linhas; duas linhas ocultas. Cores: 1 azul, 2 amarelo, 3 verde, 4 vermelho. Normal: ID da cor. Crash: `cor | 8`. Power: bit `0x80`, além de flags gráficas. Counter: `(cor << 12) | (contador << 8) | 7`; a animação também usa low byte 6. Cantos Power no nibble inferior da grade auxiliar: superior esquerdo 2, superior direito 8, inferior esquerdo 1, inferior direito 4. O byte alto muda com animação; não foi tratado como ID de grupo.

Os taps registraram, entre outros, PC `E01C` escrevendo o flag Power na grade, PC `E020` nos metadados e PC `D91A` na atualização de Counter. São PCs observados, candidatos para breakpoints; não representam funções completamente desassembladas. `board_writers.csv` tem 6.039 eventos únicos de escrita registrados nesta execução.

## Testes executados no protótipo

- Python: **13 testes aprovados**, cobrindo ferramentas anteriores, normalização, tamanho de grade, quatro cantos Power, rejeição de execução inválida e detecção de divergência entre repetições.
- `test_models.gd`: regressão anterior aprovada, incluindo geometria observada no MAME.
- `test_rules.gd`: **28 verificações aprovadas**, com Power, Crash, Counter, cadeia, gravidade rígida, contra-ataque, entrega integrada e perda.
- `test_duel.gd`: **500 turnos, nove partidas, 63 ondas e 183 ataques brutos**, sem violar invariantes de grade/tipos/geometria. Teste de estabilidade, não uma comparação de 500 turnos com o arcade.
- `test_fidelity.gd`: **80/86 exatos**, seis diferenças conhecidas de recepção.
- `render_mechanics.gd`: controles P1/P2, rotação, reinício, alternância do replay e captura nativa OpenGL aprovados. `prototipo_mecanicas.png` combina estados de teste para inspecionar a interface; não é uma partida gravada.

Os logs finais estão nesta pasta. O erro inicial do script de captura por atribuição de Array tipado foi corrigido e a captura foi executada novamente com sucesso.

## Preservação e próximos ensaios

`preservacao.json` reconfere os 14 arquivos de referência do MAME e o `.pak` original já existente no projeto. As sessões também conferem hashes do executável, ROMs, EEPROM de origem e estado inicial. A instalação da Steam não foi alterada. Configurações, save states e saídas pertencem ao laboratório.

Prioridades seguintes:

1. Rastrear o seletor de colunas das linhas incompletas e eliminar as seis divergências.
2. Medir sequência/RNG, frequência de Crash, wall kicks e tempos de queda/assentamento por nível.
3. Validar três ondas, três componentes, Counter colateral em cadeia, valores ímpares e múltiplos ataques com continuidade do padrão.
4. Validar perda simultânea e bloqueios nas linhas ocultas; depois expandir personagens e casos de pontuação.

O protocolo e os comandos repetíveis estão em `README_MECANICAS.md`. A API usada para memória e depuração está documentada pelo [MAME — memória Lua](https://docs.mamedev.org/luascript/ref-mem.html) e [MAME — depurador Lua](https://docs.mamedev.org/luascript/ref-debugger.html). As regras relatadas acima se apoiam nos ensaios locais identificados, com as limitações indicadas.
