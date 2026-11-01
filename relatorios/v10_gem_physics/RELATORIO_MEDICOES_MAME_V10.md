# V10 — medições de contato no MAME 0.289

Concluído em 01/11/2026. Branch `feature/v10-gem-physics`, base `v0.9.0` / `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`. **Nenhuma implementação lógica foi iniciada.**

Foram ensaiados **112 cenários distintos**, com **14.072 amostras esperadas** nas fixtures, além de uma sondagem inicial. Todos os cenários finais tiveram repetição; não houve divergências nos trechos confrontados. Os dois casos de perda de apoio foram estendidos até 280 quadros e repetidos integralmente em sessão própria. A regressão antiga foi novamente executada: **247/247**.

## Método, relógios e preservação

Usado o MAME **0.289**, máquina **spf2tu USA 960620**, com janela `gdi`, Lua, depurador Motorola 68000, observadores de escrita que não retornam dados modificados, capturas automáticas e dumps de 64 KiB da RAM principal. O coletor existente `scripts/automatizar_mame.py` verificou os hashes de executável, ROMs, EEPROM e save state nas fontes. ROM e instalação Steam não foram alteradas. O conjunto final principal produziu **2.957 PNGs e 6.200 dumps**; as repetições e a sondagem têm evidências adicionais.

São testes **sintéticos controlados**, não partidas naturais: cada caso restaura o mesmo save state, prepara tabuleiro/dupla na RAM da cópia emulada e depois usa somente entradas lógicas. Todos os endereços e valores injetados estão em `injections.csv`. Não há injeção durante o controle medido. A velocidade é preparada pelo índice de progressão 0, 7 ou 15 em `$186(A6)`; um turno preliminar deixa o próprio arcade calcular os parâmetros. Não é uma comparação de todas as opções de velocidade do menu nem de outras revisões da ROM.

**Convenção de quadros:** `contact.csv` amostra a RAM no callback de frame antes do processamento seguinte. `issued` registra a entrada solicitada após essa amostra; nos ensaios, ela aparece no campo `input` do jogo em **F+2**. Isso é a posição dos callbacks/coleta, não uma medição de latência física do teclado. O pré-turno com Down deixa uma leitura residual `input=4` no primeiro quadro de alguns casos neutros; ela está registrada, ocorre antes da elegibilidade de Down e muito antes do contato. Não foi apagada dos resultados.

No callback `frame_done`, `video.csv` e o dump `_video.bin` registram a RAM junto ao PNG. **Cada uma das 2.957 amostras de vídeo coincide, nos campos físicos e grades conferidos, com a amostra de CPU F+1.** Portanto, um PNG `..._f056.png` mostra o estado correspondente à linha CPU 57; não misturar esses relógios. Esse alinhamento foi verificado automaticamente.

Coordenadas: X nativo 0..5; linha lógica da dupla `Y−1`; linha visual `Y−1+offset/16`. A grade tem 14×6 células. Rotações: 0 cima, 1 direita, 2 baixo, 3 esquerda. Pivô e satélite usam cores distintas nos ensaios de separação.

Os anexos citados a seguir estão na subpasta contact_measurements/. Os dumps completos e a coleção completa de capturas permanecem em laboratorio/, referenciados pelos manifests.

## 1. Temporização por cenário

A tabela completa dos **112 cenários** está em `timing_by_scenario.csv`. Abaixo, os casos representativos; todos os números são índices de amostra CPU.

| Cenário | Primeiro contato | Contador inicial | Travamento/entrada no estado 1 | Intervalo contato → travamento |
|---|---:|---:|---:|---:|
| Progressão 0, sem Down | 41 | 16 | 57 | 16 quadros |
| Progressão 0, Down | 20 | 16 | 36 | 16 quadros |
| Progressão 7, sem Down | 25 | 16 | 41 | 16 quadros |
| Progressão 7, Down | 20 | 16 | 36 | 16 quadros |
| Progressão 15, sem Down | 17 | 16 | 33 | 16 quadros |
| Progressão 15, Down | 17 | 16 | 33 | 16 quadros |
| Orientações 0, 1, 2 e 3, sem entradas | 41 | 16 | 57 | 16 quadros |
| Giro CW solicitado em C+12 | 41 | 16 | 57 | 16 quadros; giro aceito em C+14 |
| Giro CW solicitado em C+13 | 41 | 16 | 57 | 16 quadros; giro ignorado em C+15 |
| Movimento retira o apoio | 41; novo contato 181 | 16; depois 16 | 197 | 16 após o segundo contato |
| Giro retira o apoio | 41; novo contato 181 | 16; depois 16 | 197 | 16 após o segundo contato |
| Contador de contatos anteriores preparado em 6 | 41 | 16, contato nº 7 | 57 | 16 quadros |
| Contador de contatos anteriores preparado em 7 | 41 | 1, contato nº 8 | 42 | 1 quadro |

O avanço de queda foi diferente entre os perfis: o parâmetro nativo `$27C(A6)` foi 1, 2 e 4. A janela permaneceu 16 nos seis casos de velocidade/Down. A rotina usa literalmente `#$10` em `0117EE`; não consulta a velocidade nesse ponto. **Há exceções:** contato nº 8 e a limitação de certos ajustes para cima. Não tratar 16 como única regra do sistema.

## 2. Rotação e movimento durante contato

| Contador observado na amostra em que a entrada foi processada | Giro | Movimento lateral válido | Reinicia o contador? |
|---:|---|---|---|
| 16, primeiro contato | Ignorado | Aceito | Não |
| 15 até 2 | Aceito, sujeito a colisão/limites | Aceito, sujeito a colisão | Não, enquanto o apoio continua |
| 1, último quadro da janela | Ignorado | Ignorado | Não |
| 0 após travamento, fase de resolução | Não modifica a dupla já depositada | Não modifica a dupla já depositada | Não se aplica |

Comandos foram solicitados em cada C+0..C+15 para ambos os giros; movimento foi solicitado em C+0,8,12,13,14,15 nas duas direções. Os ensaios adicionais também colocaram entradas antes do contato para observar exatamente os contadores 16 e 15.

Exemplo de borda: contato em F41. Solicitar CW em F53 faz o jogo lê-lo em F55, contador **2**, e a orientação passa 0→1. Solicitar em F54 faz a leitura em F56, contador **1**, e a orientação permanece 0. Em ambos os casos o travamento ocorre em F57. Não há prorrogação. No primeiro contato, CW lido em F41 foi ignorado; Right no mesmo F41 mudou X=2→3 sem impedir o contato.

Manter um botão de giro pressionado não repetiu o giro a cada quadro: o código usa borda de entrada (`current & ~previous`). Novas pressões separadas foram testadas. O contador exportado historicamente como `rotation_lock` é, de fato, um **temporizador de contato**, com permissão de giro dependente da fase; seu nome antigo não deve virar regra de bloqueio total.

### Perda de contato

Nos dois casos sobre plataforma, entrada em F43 (contador 14) retirou o apoio. Em **F44**, o temporizador estava **0**, a dupla avançava para Y=11 e continuava sob controle. Ele não continuou contando, não ficou pausado em 14 e não travou no vencimento antigo. Ao alcançar o chão em F181, surgiu **16**, com contador de contatos passando de 1 para 2; travou em F197.

O código `011674..01169C` confirma: testa o suporte antes de decrementar, zera `$176` se deixou de estar apoiada e retorna à queda. A rotina `0117EE..011800` incrementa `$1A8`; quando chega exatamente a **8**, substitui a janela por **1**. Esse ramo foi executado com o contador anterior preparado em 7; não foi feita uma sequência natural de oito contatos nesta bateria.

### Limite adicional de ajustes para cima

Foi executada uma sequência de entradas, sem novas escritas de RAM após o setup, alternando giro para baixo junto ao chão e retorno horizontal. Os contatos ocorreram em F41, F88 e F135. Ajustes para cima em F43 e F90 elevaram `$314(A6)` a 1 e 2. A tentativa seguinte, em **F137**, levou o campo a **5**, ativou `$316=1`, alterou Y de 14 para 13, deixou a orientação em 1 e forçou temporariamente `$176=1`.

**Isso não causou travamento imediato:** o apoio foi perdido, o temporizador zerou, houve novo contato em F179 e o travamento final ocorreu em F195. Os giros posteriores foram bloqueados. A mesma condição também foi ensaiada com `$314=2` preparado sinteticamente. O ramo está em `011ECA..011EEE`. Uma futura implementação deve reproduzir o efeito conjunto, não resumir a regra como “terceiro giro trava imediatamente”.

## 3. Entradas simultâneas, paredes e colisões

| Caso, entrada observada em F43 salvo indicação | Resultado medido |
|---|---|
| Right + CW, chão aberto | X 2→3 e orientação 0→1; contador 14 |
| Left + CCW, chão aberto | X 2→1 e orientação 0→3; contador 14 |
| Ambos os giros, chão aberto | Orientação final 0; os taps registram primeiro incremento CW e depois decremento CCW no mesmo ciclo |
| Left + Right, chão aberto | X final 2; não generalizar para todos os obstáculos |
| Down + CW | Giro aceito, sem reset do temporizador |
| Parede esquerda, CCW | X 0→1 e orientação 0→3 |
| Parede direita, CW | X 5→4 e orientação 0→1 |
| Parede direita, CW + Left | X final 4, **não 3**: o ajuste de giro suprime o deslocamento adicional nesse ciclo |
| Parede esquerda, CW + Right | X final 1 e orientação 1, sem ajuste de giro necessário |
| Corredor de uma coluna, B1 ou B2 | Orientação 0 mantida; cores 1/2→2/1; segunda pressão retorna 1/2; contador continua |
| Obstáculo irregular, CCW | X 2→3 e orientação 3 |
| Obstáculo irregular, CW | X permanece 2 e orientação 1 |
| Próximo ao piso, giros sucessivos | Ajuste vertical para orientação 2 observado; perda e recuperação de contato também observadas |

Esses são resultados dos tabuleiros explicitados nas fixtures. Não substituem a cobertura geométrica antiga nem autorizam mudar todos os kicks. A ordem nativa em `011814..011820` é: quick turn, rotina CW, rotina CCW e movimento. O flag `$397`, ativado pelo ajuste de giro, faz `0120F8..012106` pular o movimento. Isso importa para entradas simultâneas e pode divergir de um loop que mova primeiro e depois gire.

## 4. Queda independente e Power Gems

Foram medidos **12 casos**, combinando orientações horizontais 1/3, apoio apenas sob pivô/satélite e desníveis de 1/3/6 linhas.

| Desnível sem apoio | Depósito simultâneo na RAM | Primeira descida da gema solta | Alcança o apoio | Duração depósito → apoio |
|---:|---:|---:|---:|---:|
| 1 linha | F57 | F58 | F58 | 1 quadro |
| 3 linhas | F57 | F58 | F60 | 3 quadros |
| 6 linhas | F57 | F58 | F63 | 6 quadros |

Os mesmos tempos apareceram trocando qual gema está apoiada e invertendo a orientação. **Não é sempre o pivô que assenta primeiro.** Ambas são gravadas em F57 pela rotina `011974`; a que tem suporte já fica em sua posição final. A outra começa a descer em F58, uma linha lógica por chamada/frame no estado 1 (`00CEC4`), até encontrar apoio. Não confundir com a queda de Counter Gems recebidas no estado 19, cuja rotina é diferente.

Há imagens intermediárias: por exemplo, na série de três linhas, os PNGs de vídeo F56..F59 mostram a deposição e as três posições sucessivas. Seus dumps `_video.bin` e `video.csv` permitem associar a posição ao quadro sem depender de inspeção visual subjetiva.

No caso `split_forms_power`, a gema livre desceu nas amostras F58,59,60. A região inferior passou a 2×2; os códigos Power apareceram em **F65, estado 5**, depois da queda e antes da continuação da resolução. A queda, portanto, pode viabilizar a formação de Power. O resultado não demonstra que se deva formar um retângulo enquanto a dupla ainda está em contato controlável.

Também foi observada animação intermediária no giro: em `rotate_b2_issued_c00`, `$24C` é inicializado em 8 e aparece nas amostras seguintes como **7..0**; `$248/$24A` percorrem offsets assinados, começando em **−14/−15** e terminando em 0/0, mesmo com a orientação lógica já igual a 1. Esses campos foram preservados em `animation_ram`. **A curva exata de squash/expansão no contato não foi isolada quantitativamente**; os PNGs e dumps estão disponíveis, mas não serão convertidos numa curva presumida.

## 5. Diferenças comprovadas em relação ao Godot atual

| Área | Godot atual | Evidência MAME e consequência |
|---|---|---|
| Travamento | Descida bloqueada faz commit/resolução/spawn imediatamente | Há janela de contato, quadros com permissões distintas e teste de suporte antes do decremento |
| Giros/movimento no contato | Não há estado equivalente; depois do commit o alvo é a nova dupla | A dupla anterior continua controlável até a fronteira medida, sem reset por entrada válida apoiada |
| Perda e reentrada em apoio | Sem contador de contato e sem limite por episódios | Temporizador zera ao perder apoio, recomeça ao apoiar e há exceção no oitavo contato |
| Ajustes verticais repetidos | Não há os campos/limites `$314/$316` | Sequência medida altera contadores, permissão de giro e contato de forma conjunta |
| Separação | Gravidade resolve tudo numa chamada | Gemas livres descem por estados e quadros; Power só surge depois no caso observado |
| Entradas simultâneas | Movimentação no tick e giros por eventos separados | Ordem nativa e supressão de movimento por kick exigem fila determinística por quadro |
| Giro visual | Desenha a nova orientação sem os offsets nativos de transição | `$248/$24A/$24C` mostram evolução intermediária medida |

`match_model.gd`, `board_model.gd`, `resolution.gd` e `gem_rules.gd` não foram alterados. Os 198 hashes do manifesto de código/dados da V9 continuam idênticos. A implementação de gravidade independente e os endpoints antigos não devem ser descartados por causa da diferença temporal.

## 6. Fixtures e reprodução

- `mame_contact_fixtures.json`: 112 configurações, hash da RAM inicial, entradas emitidas, leituras de entrada, estados esperados por amostra, tabuleiros/auxiliares e campos de animação. Valores derivados **somente das observações do MAME**.
- `verify_contact_fixtures.py`: confronta CSVs com essas expectativas e, quando fornecida a sessão completa, também confere dumps de RAM contra as amostras. Não contém implementação da janela ou regras esperadas calculadas para fazer testes passar.
- `timing_by_scenario.csv`, `split_timing.csv`, `input_results.csv`: tabelas de temporização, separação e entradas.
- `runs/`: cópias exatas das Luas executadas, manifestos, injeções, CSVs, logs e disassembly. `ram_sha256.json` referencia os dumps preservados nas sessões originais em `laboratorio/`.
- `evidence/`: seleção de PNGs. As 2.957 capturas principais completas continuam nas sessões apontadas pelo manifesto; não foram apagadas nem substituídas.

Para verificar o pacote textual: `python -B verify_contact_fixtures.py` nesta pasta. Para uma sessão nova: `python -B verify_contact_fixtures.py --session C:\\...\\NOVA_SESSAO`. A cópia `runs/matrix_final/experimento.lua` é a matriz de 101 casos; `runs/edges_first/experimento.lua` acrescenta 11 casos. Reexecutar pelo coletor existente, com `--debug --video gdi --state` apontando para o save state de laboratório, usando uma sessão nova. Scripts, inputs e resultados esperados permanecem congelados; não ajustar as expectativas ao Godot.

A matriz inicial foi comparada às primeiras 120 amostras medidas de cada caso da matriz estendida: **12.221 registros iguais**. Os 11 casos adicionais tiveram repetição exata de **1.531 registros**. Os dois casos estendidos de perda de apoio tiveram ainda **562 registros** repetidos, incluindo a extensão. Zero diferenças. A seleção de capturas e os manifests não incluem ROMs ou executáveis; dumps completos ficam locais no laboratório.

## 7. Proposta técnica, sem implementar

1. Criar uma sequência temporal por jogador que represente queda controlável, contato, depósito, gravidade de células soltas e resolução. Manter as funções atuais como referência dos endpoints, não adicionar esperas dentro de `resolve()`.
2. Processar suporte e contador na ordem nativa; zerar contato quando o apoio some. Representar episódios de contato e os limites medidos. Tratar o caso especial do terceiro ajuste para cima com estado suficiente para reproduzir a trajetória medida, incluindo a possível perda de apoio.
3. Enfileirar entradas por quadro, distinguindo borda de botão e direção mantida; aplicar ordem e flag de supressão por kick. Não reiniciar o contato por giro/movimento válido que mantenha apoio. Respeitar o bloqueio de giro no contato inicial e o bloqueio geral no último quadro.
4. Depositar a dupla e animar a gravidade independente com eventos/identidade por gema. Somente depois aplicar fases de formação/resolução, preservando os resultados das 247 comparações. Separar a rotina de queda recebida de Counters.
5. Fazer a apresentação consumir estados/offsets medidos, incluindo a transição de giro; evitar reconstruir toda a física somente por diferenças entre tabuleiros finais. Não alterar sprites nem inventar uma curva de deformação.
6. Antes da mudança, adaptar um teste de timeline às fixtures, deixando as comparações antigas intactas. Implementar gradualmente em etapa posteriormente autorizada, com regressões de regras, naturais, RNG e rounds.

## 8. Riscos e limites

- **RNG:** novos quadros antes do spawn e novas fases alteram quantas chamadas globais ocorrem antes de gerar a dupla/selecionar permutação. Guardar relógio e consumidores por fase; não compensar ajustando sementes artificialmente.
- **Pontuação:** Down tem bônus; não concedê-lo a cada tick de contato. Preservar instante de contabilização, conversão de Counters, cadeia e First Attack.
- **Ataques:** filas podem chegar enquanto o oponente resolve. Esperas reais mudam cancelamento/entrega; não basta atrasar o sprite depois de já calcular tudo.
- **Power/gravidade:** não dividir Power já rígida em células independentes; não formar cedo uma Power antes de a queda terminar. O caso de formação foi ensaiado, mas não todas as disputas de retângulos.
- **Cobertura:** esta bateria é P1, nesta revisão e neste estado de dois jogadores. Não foram medidas todas as dificuldades/opções de menu, P2 em todos os cenários, teto, todas as geometrias irregulares ou uma sequência natural de oito contatos. A exceção do oitavo foi exercitada com contador pré-configurado e corroborada no 68000.
- **Animação:** há prova de posições intermediárias e de offsets de giro. Falta extração quantitativa da curva exata de compressão/expansão de contato; não é uma regra confirmada nesta entrega.

Uma tentativa inicial da matriz falhou por sintaxe Lua (`event.until`, palavra reservada). Foi preservada em `laboratorio/auto_20261101_001325_364226`, retornou código 3 e não entrou em nenhuma medição. A sondagem preliminar de sete casos está em `auto_20261101_001128_210411`. Todas as sessões usadas nas fixtures concluíram, sem erros Lua, e verificaram preservação das fontes.

**Conclusão:** há evidência reproduzível suficiente para projetar a janela de contato, suas fronteiras, perda de apoio e separação básica. Não há autorização implícita para iniciar a implementação: nesta entrega foram feitos somente ensaios, fixtures e documentação. Sem commit ou push.
