# Fidelidade CPS-2 — revisão v4

Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`. Arcade: `spf2tu`, USA 960620, MAME 0.289. Godot 4.7.2 portátil. Trabalho realizado em 28/10/2026, preservando o projeto existente e a revisão anterior em `revisoes/antes_fidelidade_v4_20261028_225715` (consulte o nome exato da pasta em `revisoes`).

**As seis divergências anteriores foram corrigidas nos testes controlados.** A regra geral agora usa as oito permutações reais e o estado do seletor observado antes da entrega. A bateria ampliada também corrigiu fórmulas de pontuação que só pareciam corretas nos casos pequenos da v3.

**Restam sete endpoints divergentes em partidas do arcade:** cinco envolvem ataques recebidos durante a resolução, um envolve o bônus de primeiro ataque durante uma ação do outro jogador e um envolve a Diamond Gem, ainda sem regra no protótipo. Não há declaração de fidelidade integral da partida.

## Resultados executados

| Bateria | Resultado | O que foi comparado |
|---|---:|---|
| Mecânicas, distribuições e contra-ataques | **247/247** | 75 resoluções, 159 entregas e 13 contra-ataques |
| Controles e RNG | **33/33** | Geometria, cores em quick turn, repetição, aceleração, período de queda e um lote de 866 chamadas nativas de RNG |
| Partidas por entradas lógicas | **112/119** | Tabuleiro e delta de pontos por resolução concluída, com estado de entrada observado no arcade |
| Python | **17/17** | Exportação, validação, normalização e ferramentas anteriores |
| Regras unitárias Godot | **28/28** | Regressões de Power/Crash/Counter, gravidade, cadeias, ataque e perda |
| Simulação Godot | **1.500 turnos, 30 partidas** | 191 ondas e 537 ataques brutos, sem violar invariantes |
| Regressão de modelos e apresentação | **Aprovadas** | Movimento, colisão, eventos físicos P1/P2, rotação, reinício, replay, relógio e captura nativa OpenGL |

Os 33 registros de controles incluem um registro agregado de RNG com 866 amostras; não são 33 partidas. Foram guardados 40 ramos de temporização. Dez estados sintéticos iniciais sobrepunham bordas ou pedras e foram excluídos da comparação de rotações naturais; seus IDs e motivos estão em `controles.json`. Dois registros adicionais comparam a segunda troca de cores em corredor estreito.

Os testes de partidas cobrem três trechos de 2.400 quadros cada, sem injetar células, filas ou personagens. Um endpoint incompleto foi registrado e não contado como resolução concluída. O teste retorna **1** nas sete diferenças conhecidas, conservadas em `partidas.json`. Os demais testes retornaram sucesso e os logs finais não contêm erros de script.

## Regra geral das linhas incompletas

O programa emulado lê uma tabela em `00FF98`. O índice está no byte do receptor `ator+037B`; o cursor dentro da linha está em `ator+037A`. A leitura foi localizada em PC `00CE3A`. As oito ordens de coluna são:

```text
0: 0 1 2 5 4 3
1: 5 4 0 1 2 3
2: 0 5 2 4 1 3
3: 1 2 4 5 0 3
4: 4 1 5 0 2 3
5: 5 0 2 1 4 3
6: 0 1 2 4 5 3
7: 5 4 2 1 0 3
```

Linhas completas usam as seis colunas. Uma linha parcial usa o prefixo da permutação selecionada. O índice é atualizado pela rotina de queda livre usando o RNG global; permanece como estado necessário para reproduzir uma entrega. Não é determinado apenas pela quantidade do ataque.

`residuos.lua` verificou **8 índices × 17 quantidades = 136 entregas**, mais **11 perfis numéricos de personagem**, totalizando 147 casos novos. Somados às 12 entregas anteriores, os 159 resultados coincidem célula a célula. O código não contém exceções pelos nomes dos seis casos antigos.

Nas fixtures, o índice vem da RAM antes da entrega; não é escolhido depois de observar a coluna final. No duelo ao vivo, o RNG exato já escolhe as permutações durante a queda livre, mas seu consumo durante animações e outras fases ainda não está sincronizado com o arcade. Logo, reproduzir a função de distribuição não garante a mesma coluna numa partida inteira com relógios diferentes.

## Padrões dos personagens

Os perfis usados pela rotina `00FF3C` foram lidos como dados comportamentais: 11 IDs, 12 linhas e seis colunas, guardados em `godot/data/attack_profiles.json`. A rotina limita a linha ao índice 11. O contador inicial lido é cinco nos 11 perfis examinados.

Ryu foi confirmado como ID 2 e Ken como ID 3. Ryu usa colunas `[4,3,1,2,4,3]`; Ken alterna linhas uniformes de vermelho, verde, azul e amarelo no trecho observado. Os demais IDs tiveram seus resultados comparados numericamente, sem atribuir nomes não confirmados. As primeiras seis camadas foram exercitadas nos testes de 33 pedras de cada ID; as demais linhas vêm da tabela lida, não de todas as combinações jogadas.

A linha do padrão é local à entrega, acompanhando o contador reiniciado pelo fluxo do arcade. Foi removido o contador cumulativo por emissor que a v3 usava. Sequências de entregas sobrepostas ainda dependem da máquina temporal pendente.

## Contra-ataque

O cancelamento foi localizado em `00FC22–00FD62`. Se a força enviada supera a fila, cancela a fila e envia a diferença. Se não supera, o arcade reduz a força antes de aplicá-la contra a fila:

- Até 12 pedras: parte inteira de `ataque/2`.
- 13–18: `(floor(ataque/8)+1)×5`.
- 19–24: o mesmo termo ×6.
- 25–30: ×7.
- Acima de 30, no ramo examinado: ×8.

A fila não fica negativa. Os **13 casos** confirmam forças pequenas, igualdade, sobra, arredondamento ímpar e seis forças maiores. Exemplos: fila 10 contra força 7 deixa 7; fila 75 contra força 14 deixa 65; contra 28 deixa 47; contra 33 deixa 35; contra 42 deixa 27.

Esses resultados corrigem a generalização anterior de simplesmente dividir todo ataque fraco por dois. Acúmulo e chegada de novas filas enquanto a resolução já está em andamento continuam como trabalho temporal separado.

## Pontuação e cadeias

Os novos casos de três cores revelaram coincidências acidentais na fórmula multiplicativa da v3. O código agora acompanha os bônus aditivos observados e as tabelas lidas nas rotinas `00FEA8–00FF3A`:

- Normais e Crash destruídas: 100 pontos por célula nos casos ensaiados.
- Power Gems: soma das áreas de **todas as Power destruídas na onda**, mesmo de cores diferentes, antes de determinar a faixa de valor. As faixas calibradas continuam 200/250/300/350/400 pontos por célula para áreas até 9, 17, 24, 39 e 48.
- Bônus de tamanho: `10×max(total de células destruídas−2,0)`, contado na onda, incluindo os colaterais.
- Counter colateral: mais 10 pontos além de sua participação no bônus de tamanho; os exemplos medidos acrescentam 20 por Counter.
- Duas ou mais cores destruídas: +200 por cor distinta. Componentes separados da mesma cor não geram esse bônus de várias cores.
- Bônus de cadeia por onda: `[0,200,400,1000,1600,2200,2800,3400,4000,4000,4000]`, com o índice limitado pelo ramo examinado.

Exemplos confirmados: combo de três cores **1.680**, três cores com Counter **1.700**, dois componentes separados da mesma cor **420**, cadeia de três ondas **1.200**, cadeia com segunda onda maior **1.310**, e duas Power Gems de cores distintas com área somada dez **3.200**.

Foram ensaiadas cadeias até três ondas. Valores posteriores vêm da tabela lida, ainda sem todos os cenários correspondentes. Somas Power acima de 48, formas concorrentes complexas e situações de bônus sobrepostos não foram esgotadas. A Diamond Gem não deve ser interpretada como uma pedra normal pelo futuro resolvedor; sua regra permanece pendente.

## RNG, controles e tempo

O RNG global está em `FF80AE` e usa a rotina `02DB6A`. O RNG das duplas usa `ator+0144`, rotina `0122EC`, com tratamento de estado zero no código examinado. A transição foi portada com aritmética de 16 e oito bits e comparada contra **862 chamadas globais e quatro chamadas das duplas**, capturadas por breakpoints nativos. Todas coincidiram.

Isso confirma a transição, não a sequência inteira do jogo. A geração de duplas ainda usa a sequência provisória anterior no modo local. Foram identificadas rotinas e contadores adicionais de geração, mas as tabelas completas, o consumo por fase e a Diamond Gem não foram integrados. A frequência provisória de Crash a cada cinco duplas permanece marcada como aproximação no código e não é uma regra confirmada do arcade.

O perfil `-listxml spf2tu` informou pixel clock de 8.000.000, total horizontal 512 e vertical 262: **59,63740458 Hz**. O Godot agora acumula esse relógio sobre seus ticks físicos, evitando assumir exatamente 60 Hz para o jogo. O teste de apresentação verificou 59 ticks de jogo em 60 chamadas físicas de 1/60 s.

No estado inicial examinado, a queda livre avançou uma linha a cada **32 quadros**, aproximadamente 0,536576 s. A fase inicial, interpolação, alteração de velocidade por progressão e atraso de assentamento ainda não estão totalmente portados.

Foram ajustados e comparados:

- Movimento inicial e repetição horizontal após **12 quadros**, depois a cada quadro.
- Aceleração de Down por estágios de quatro, dois e um quadro, com contador cumulativo por dupla e elegibilidade após o início observado da peça.
- Deslocamento lateral para permitir rotação perto de paredes.
- Ajuste para cima ao girar para baixo próximo ao piso, nos casos ensaiados.
- Troca de cores, mantendo a orientação, quando uma dupla vertical gira presa entre ambos os lados; a segunda pressão também foi comparada.

Continuam não esgotados outros encaixes, ajustes para baixo/teto, animações de rotação, bloqueio durante assentamento, velocidades de outros níveis e simultaneidade de entradas. As comparações de repetição usam as entradas lógicas lidas do arcade; o estado de coleta em si não é tratado como latência de teclado do usuário.

## Sete divergências novas das partidas

| Endpoint | Diferença | Interpretação atual |
|---|---|---|
| `natural_e1_p1_t3_f48` | Uma célula Counter | Ataque chegou depois do estado inicial usado pelo resolvedor |
| `natural_e2_p1_t5_f475` | Quatro células Counter | Nova fila entregue durante a resolução |
| `natural_e3_p2_t1_f652` | Tabuleiro igual; +1.000 no arcade | Bônus de primeiro ataque disparado por evento do outro tabuleiro |
| `natural_e3_p1_t9_f1136` | Três células Counter adicionais | Fila mudou durante o intervalo; quatro pedras já constavam na entrada |
| `natural_e3_p1_t4_f1578` | Doze células Counter | Entrega assíncrona ausente do estado inicial |
| `natural_e3_p1_t6_f1905` | Nove células diferentes | Nova entrega e sobreposição com contadores existentes |
| `natural_e3_p2_t6_f1976` | Quinze células e 860 pontos | Entrada contém Diamond Gem, código 5, sem regra no protótipo |

As cinco classificações de chegada são inferências sustentadas pelas células Counter novas e pelo intervalo observado; ainda precisam de registro de eventos quadro a quadro para portar o fluxo completo. Não foram corrigidas preenchendo a entrada com informações futuras da saída. O último caso sugere destruição global por cor na Diamond Gem, mas um exemplo não basta para definir todas as suas regras.

Os 119 testes importam estados observados de cada turno; não reproduzem, desde a inicialização, toda a sequência de entradas, RNG e animações no Godot. A aprovação de 112 endpoints mede resolução nesses estados, não paridade temporal das três partidas inteiras.

## Repetibilidade e preservação

- Mecânicas: `auto_20261028_231155_374892` e `auto_20261028_232043_038647`: **95 cenários**, 28.320 quadros por execução, **5.007 dumps idênticos**, CSVs idênticos, nenhum dump divergente.
- Resíduos: `auto_20261028_230219_781771` e `auto_20261028_231816_311726`: CSV dos 147 casos e tabelas idênticos.
- Partidas: `auto_20261028_232035_902699` e `auto_20261028_232132_713128`: CSVs idênticos, mesmo registro de endpoint incompleto e **241 snapshots idênticos**.
- Controles: fonte final `auto_20261028_231304_380937`.
- RNG: fonte `auto_20261028_230328_525289`.

Os manifests das sessões registram comando, hashes, conclusão Lua e integridade das fontes. A tentativa `auto_20261028_231638_926789` teve erro no protocolo de coleta e foi invalidada; não alimenta nenhuma fixture final. Os estados inválidos de geometria e o endpoint incompleto das partidas também são apresentados, sem serem convertidos em aprovações.

`preservacao.json` reconfere os 14 arquivos de referência do MAME e o `.pak` original já existente no projeto. Nenhuma ROM, configuração original ou instalação da Steam foi alterada. Saídas, estados salvos e logs pertencem ao laboratório.

## Pronto para gráficos e personagens

O duelo local permanece executável por `Jogar.cmd`, com dois tabuleiros, Power/Crash/Counter Gems, combos, cadeias, gravidade, pontos, ataques, contra-ataques e vitória/derrota. O núcleo é separado da apresentação, que continua desenhando formas próprias.

Há interfaces para tipos/cores/contadores, retângulos Power, duplas/orientação, ondas de destruição, pontuação, filas e resultado da partida. Esses estados podem alimentar sprites, animações, som e HUD. Os 11 perfis de ataque são dados independentes dos gráficos; os nomes e assets dos nove IDs além de Ryu/Ken ainda precisam de associação e criação. Rede, seleção completa de personagens e arte final não foram acrescentadas nesta revisão.

Prioridade seguinte: uma máquina de fases/eventos compartilhada pelos dois jogadores, mantendo chegada de ataques e bônus durante as animações; depois uma bateria própria de Diamond Gem e a geração completa das duplas. O protocolo reproduzível está em `README_FIDELIDADE_V4.md`.

Referências de API usadas: [depuração Lua do MAME](https://docs.mamedev.org/luascript/ref-debugger.html), [watchpoints](https://docs.mamedev.org/debugger/watchpoint.html) e [disassembly e memória](https://docs.mamedev.org/debugger/memory.html). Os números e regras deste relatório vêm das observações locais identificadas acima.
