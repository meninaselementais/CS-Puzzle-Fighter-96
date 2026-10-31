# Counter-Strike Puzzle Fighter '96 — resultado da automação

Data: 28/10/2026. Sistema analisado: **Super Puzzle Fighter II Turbo, spf2tu USA 960620**, no **MAME 0.289**. O trabalho anterior foi confirmado em `C:\Projetos\CS-Puzzle-Fighter-96` antes da continuação.

## O que foi executado

A automação Python criou cópias verificadas do executável, ROMs e EEPROM. A Lua fez o boot, inseriu créditos, iniciou P1 e depois P2, confirmou as seleções e salvou um estado completo. Cada ramo restaurou esse estado, aplicou entradas por quadros e capturou RAM, imagens e contexto das escritas.

Resultado consolidado: **25 casos**, **1.981 capturas de teste**, incluindo as bases dos 25 ramos, e **17 verificações aprovadas**. Uma segunda execução limpa, em outro processo, produziu os mesmos **1.981 dumps**, byte a byte. Os ramos começam com RAM idêntica e entradas neutras. Os logs das duas execuções não contêm erros Lua.

Sessão principal: `laboratorio/auto_20261028_155033_010970`.

Réplica: `laboratorio/auto_20261028_155222_821526`.

Evidências e resultados estão em **`relatorios/automacao_20261028_consolidada`**. As sessões anteriores são exploratórias; algumas foram rejeitadas por partida ainda não controlável, cache residual de entrada ou erros do limite de quadros. Elas foram preservadas, mas não são a base destas conclusões.

## Mapa comprovado no conjunto de testes

| Campo | P1 | P2 | Formato |
| --- | --- | --- | --- |
| X lógico da dupla | **FF8310** | **FF8710** | u16 big-endian; colunas 0–5 |
| Y lógico da queda | **FF8314** | **FF8714** | u16 big-endian; combinar com o deslocamento abaixo |
| Deslocamento vertical | **FF8542** | **FF8942** | s16 big-endian; valores negativos e zero nos testes |
| Orientação | **FF8470** | **FF8870** | byte: 0=cima, 1=direita, 2=baixo, 3=esquerda |
| Grade com bordas | **FFAB00** | **FFAD00** | 14 linhas de oito palavras, sendo seis internas |

Os blocos dos jogadores têm bases observadas FF8300 e FF8700, separadas por 0x400. O trace registra o A6 usado pelas rotinas e sustenta essa associação. As grades são separadas por 0x200.

Para a célula interna `(x,y)`, com x de 0 a 5 e y de 0 a 13:

```text
endereco = base_da_grade + 0x10*y + 2*(x+1)
```

As extremidades de cada linha contêm 00FF. O piso está em FFABE0/FFADE0. As duas primeiras linhas da grade ficam acima da área principal de 12 linhas representada pelo jogo.

## A posição visual não é somente Y vezes 16

O deslocamento assinado explica a posição intermediária durante a queda. Na imagem nativa 384×224, para o pivô:

```text
pixel_x_P1 = 24 + 16*X
pixel_x_P2 = 280 + 16*X
pixel_y    = 16*Y + deslocamento_vertical - 24

linha_visual_na_grade = Y - 1 + deslocamento_vertical/16
```

O satélite fica a 16 pixels do pivô, na direção indicada pela orientação. Essa composição foi conferida com os pixels da dupla em controle, esquerda, direita, duas direções de rotação e meia volta. Usar somente o Y inteiro foi uma hipótese rejeitada: desenhava a peça adiantada em relação à imagem.

Exemplo após 16 quadros, a partir da mesma base:

| Ação P1 | X | Y lógico | Deslocamento | Linha visual | Orientação |
| --- | ---: | ---: | ---: | ---: | ---: |
| Controle | 3 | 7 | -16 | 5 | 0 |
| Direita por um quadro | 4 | 7 | -16 | 5 | 0 |
| Esquerda por um quadro | 2 | 7 | -16 | 5 | 0 |
| Botão 1 por um quadro | 3 | 7 | -16 | 5 | 3 |
| Botão 2 por um quadro | 3 | 7 | -16 | 5 | 1 |
| Baixo mantido | 3 | 12 | 0 | 11 | 0 |

P2 respondeu da mesma forma nos seus campos, mantendo P1 igual ao controle. Direita e esquerda mantidas chegaram a X=5 e X=0. Duas rotações chegaram ao estado 2; quatro retornaram ao estado 0.

## Evidência das instruções

Além da comparação de RAM, foram instalados taps de escrita sem retorno de valores modificados. O depurador acompanhou os últimos escritores e produziu trechos de disassembly:

- **0121A4**: `addq.w #1,($10,A6)` — incrementa X.
- **012296**: `subq.w #1,($10,A6)` — decrementa X.
- **0117C8**: `addq.w #1,($14,A6)` — avança Y lógico.
- **011E56 / 011E5C**: incremento de orientação em `($170,A6)`, seguido de máscara 3.

O PC observado dentro de um tap pode apontar para a próxima instrução; por isso o relatório usa os endereços das instruções no disassembly e as consultas do depurador. As escritas parciais usam máscaras: FF8471 é adjacente à orientação, mas não deve ser confundido com o byte FF8470. As consultas que retornaram UNKNOWN PC foram mantidas no log; elas não foram usadas como prova de escritor.

## Cores

As células normais da RAM foram confrontadas com amostras de pixels das imagens sincronizadas. Houve 489 observações classificadas, com repetições da mesma célula em diferentes quadros; não são 489 experimentos independentes.

| Código | Cor | Observações classificadas |
| ---: | --- | ---: |
| 1 | **Azul** | 56 |
| 2 | **Amarelo** | 226 |
| 3 | **Verde** | 54 |
| 4 | **Vermelho** | 153 |

Não houve contradição de cor entre as observações aceitas. A classificação desconsidera pixels pouco saturados/escuros e amostras ambíguas. A tabela não decodifica todas as pedras especiais.

Os endereços das cores da **dupla ativa** ainda não foram isolados. No replay, essas cores são observadas nas imagens-chave, enquanto as células assentadas são lidas diretamente da RAM. O valor zero nas cores ativas significa ausência de observação, não uma cor do jogo.

## Associação dos tabuleiros

A queda de P1 até assentar mudou a grade FFAB00, mantendo FFAD00 igual ao controle no mesmo quadro. A queda de P2 fez o inverso. Isso confirma a propriedade das grades no cenário de dois jogadores, além da simetria estrutural identificada anteriormente.

Os antigos FF84F4/FF88F4 não responderam como X nos testes de esquerda/direita. FF8488 tampouco foi confirmado como coordenada ativa. FF851A/FF8522 continuam sendo referências de processamento; não foram promovidos a coordenadas da dupla. O antigo candidato assinado FF8542, por outro lado, passou a ter uma função explicada na composição vertical.

## Godot 4

Foi criada uma base executável em `godot/project.godot`, validada com **Godot 4.7.2 stable** portátil. Ela inclui dois tabuleiros, duplas, movimento, rotação, colisão, assentamento simples e replay dos dados reais. O núcleo não contém endereços do MAME. O visual usa formas próprias.

Foram executados testes do modelo, importação do replay, comparação geométrica com ações capturadas, 120 quadros da cena em modo headless e renderização real em OpenGL. A imagem resultante é `prototipo_godot.png`. Os oito testes Python também passaram.

O protótipo usa gravidade e geração provisórias. Ainda faltam as regras completas de crash gems, power gems, contra-ataques, contadores, pontuação, condições de vitória, repetição de entrada, ajustes de rotação em colisões e fidelidade dos tempos. A arquitetura e os comandos estão em `ARQUITETURA_GODOT.md`.

## Preservação e reprodução

As fontes do MAME foram apenas lidas. Todas as gravações do emulador foram direcionadas às sessões do projeto. A instalação da Steam e o conteúdo preexistente de `Original` não foram alterados. Não houve patch, serviço instalado ou escrita direta de testes na RAM/ROM do jogo.

Os manifestos contêm comando, hashes das fontes/cópias e cópias dos scripts por sessão. A checagem final está em `preservacao_atual.json`. Para repetir a bateria, consulte `README_AUTOMACAO.md`.

## Limites e próximos testes

O mapa foi validado para spf2tu USA 960620, com a EEPROM copiada usada nestas sessões. Validar outras versões, personagens, sementes, partidas prolongadas e velocidades antes de tratá-lo como universal. Prioridades: localizar as cores ativas na RAM, medir a gravidade e a repetição de entrada, testar rotações junto a paredes/piso e mapear a resolução de grupos/ataques.

Referências primárias de instrumentação: [API de memória Lua](https://docs.mamedev.org/luascript/ref-mem.html), [eventos da máquina](https://docs.mamedev.org/luascript/ref-common.html), [depurador Lua](https://docs.mamedev.org/luascript/ref-debugger.html) e [driver CPS2 0.289](https://github.com/mamedev/mame/blob/mame0289/src/mame/capcom/cps2.cpp). Os endereços e resultados acima foram obtidos dos arquivos e das execuções locais.
