# Counter-Strike Puzzle Fighter '96 — análise dos dumps originais

Data: 28/10/2026. Computador: MAUTRIX. Análise estática dos arquivos locais, com Python 3.11.9. A execução informativa `C:\MAME\mame.exe -help` confirmou **MAME v0.289 (mame0289)**. Nenhuma partida foi iniciada nesta etapa.

## Resultado principal

Os melhores pontos para testar coluna são **0xFF84F4**, **0xFF8488** e o correspondente **0xFF88F4**. Os campos **0xFF851A/0xFF8522** são fortes candidatos a ponteiros de célula ou cursores de processamento. A função de coordenada da peça ativa ainda não foi confirmada.

Há evidência estrutural consistente para duas grades em **0xFFAB00** e **0xFFAD00**, com seis posições internas por linha, 14 linhas armazenadas e bordas sentinela. Os dados permitem reconstruir posições de células por uma fórmula experimental. Ainda é necessário confirmar sua relação com o tabuleiro visível e com o jogador.

O par chamado `pedra` contém oito novas células nas duas grades, sem remover as já ocupadas. Portanto, não representa apenas uma translação limpa de uma dupla: há assentamento, geração de células ou processamento adicional misturado no intervalo.

## Fontes e consistência

- `memoria_inicial.bin`, `memoria_depois.bin`, `pedra_antes.bin` e `pedra_depois.bin`: 65.536 bytes cada.
- `movimento_pedra.csv`: suas 242 linhas coincidem exatamente com a comparação binária, incluindo ordem, endereço e valores.
- `comparacao_memoria.csv`: suas 515 linhas também coincidem integralmente.
- `analise_puzzle.zip`: os três membros são idênticos, byte a byte, aos arquivos soltos correspondentes. Não constitui uma nova observação independente.
- `cfg\spf2tu.cfg`: o histórico registra os quatro comandos `save` com início `0xff0000` e tamanho `0x10000`. Isso confirma a base usada nas comparações.
- `roms\spf2t.zip` e `roms\spf2tu.zip` existem; o CFG identifica `spf2tu`. O driver MAME 0.289 associa esse sistema à edição USA 960620. Não houve auditoria das ROMs nem extração de código de programa.
- O relatório anterior desta conversa foi revisado. Os dois CSVs e o ZIP eram os relatórios de análise existentes na raiz de `C:\MAME`; `whatsnew.txt` é documentação da distribuição.

O mapa do driver CPS2 confirma RAM em `0xFF0000–0xFFFFFF`. Os valores de múltiplos bytes abaixo são interpretados como big-endian. A validação por bordas e ponteiros também sustenta essa interpretação nestas estruturas.

## Os 242 bytes

São **242 bytes (0,3693% da RAM)** em **190 palavras alinhadas de 16 bits** e **26 páginas de 256 bytes**. Desses bytes, 140 passam de zero para não zero, seis de não zero para zero e 96 mudam entre valores não zero.

| Faixa/conjunto | Bytes diferentes | Observação |
| --- | ---: | --- |
| 0xFF0000–0xFF7EFF | 6 | Estado ainda não identificado |
| 0xFF7F00–0xFF83FF | 23 | Estado ainda não identificado |
| 0xFF8400–0xFF87FF | 21 | Primeiro grupo de campos candidatos |
| 0xFF8800–0xFF8BFF | 27 | Segundo grupo, distância de 0x400 |
| 0xFF8C00–0xFFAAFF | 7 | Alterações dispersas |
| 0xFFAB00–0xFFAEFF | 8 | Quatro células novas em cada grade |
| 0xFFB300–0xFFB3FF | 24 | Campos repetidos em registros de passo 0x20 |
| 0xFFBC00–0xFFBDFF e 0xFFC500–0xFFC6FF | 90 | Inicializações e registros repetidos; função não confirmada |
| 0xFFCC00–0xFFCDFF | 32 | Inicializações com passo aparente de 0x10 |
| 0xFFD700–0xFFD7FF | 4 | Dois valores adjacentes mudam igualmente |
| **Total** | **242** | Todas as diferenças cobertas |

Os arquivos estão separados por 14 segundos de horário de gravação no Windows. Esse intervalo não permite determinar quantos quadros o jogo executou ou quais entradas recebeu.

## Endereços candidatos, por prioridade de teste

Os números decimais entre parênteses correspondem à interpretação indicada. Prioridade significa ordem de investigação, não probabilidade medida.

| Prioridade | Endereço e formato | Antes → depois no par pedra | Evidência e limite |
| --- | --- | --- | --- |
| 1 | **0xFF84F4**, u16 BE | 0003 → 0005 (3 → 5) | Valores pequenos, compatíveis com coluna/índice. Nos quatro dumps: 2,5,3,5. Pode ser índice ou estado; não há controle de entrada. |
| 1 | **0xFF8488**, u16 BE | 0003 → 0005 | Concorda com FF84F4 neste par. O campo em FF8888 permanece zero nos quatro dumps; a simetria de jogador não foi demonstrada para ele. |
| 1 | **0xFF88F4**, u16 BE | 0003 → 0005 | Distância de +0x400 de FF84F4; valores 2,4,3,5. Os dois grupos mudam, impedindo atribuir a alteração somente a P1. |
| 2 | **0xFF851A e 0xFF8522**, u32 BE | 00FFABC4 → 00FFABCC (+8 bytes) | São endereços pares dentro da grade A; ambos contêm o mesmo valor. Podem ser ponteiros de peça assentada ou cursores, não necessariamente da peça ativa. |
| 2 | **0xFF851E**, u32 BE | 00FFAFC4 → 00FFAFCC (+8) | Aponta +0x400 além da grade A, para um plano paralelo. O tipo desse plano não foi determinado. |
| 2 | **0xFF8526**, u32 BE | 00FFAFB4 → 00FFAFBC (+8) | Mesmo deslocamento, uma linha de 0x10 bytes acima do ponteiro anterior. Pode relacionar duas células, mas não confirma o pivô da dupla. |
| 3 | **0xFF8542 e 0xFF8942**, s16 BE | FFF5 → FFFB (-11 → -5) | Mudança de +6 nos dois grupos. Pode ser deslocamento assinado, posição de animação ou contador. Sem evidência suficiente para chamá-lo de Y. |
| 3 | **0xFF84A6 / 0xFF88A6**, u16 BE | 213 → 193 / 181 → 193 | Valores compatíveis com pixels; convergem para 193. Não se conhece o objeto ou eixo representado. |

**Nenhum endereço Y está validado.** `FF84F6` e `FF88F6`, adjacentes aos candidatos de coluna, permanecem em `0x0019` (25) nos quatro dumps. A vizinhança por si só não os torna coordenadas. `FF8640/FF8A40` mudam igualmente de 10 para 24; isso também pode ser um estado temporal comum.

Importante: o byte alterado de uma palavra pode ter endereço ímpar. Por exemplo, a mudança em `FF84F5` pertence à palavra de 16 bits iniciada em **FF84F4**. Os ponteiros de 32 bits começam em **FF851A**, não em FF851C; este último é apenas a metade baixa.

## Grades e coordenadas derivadas

Em todos os quatro dumps, cada grade principal tem 14 linhas com oito palavras: `00FF`, seis células internas e `00FF`. A linha seguinte contém oito palavras `00FF`, sugerindo o piso. As células internas usam somente valores 0 a 4 nestes dados. O significado exato de cada código e a correspondência de cor não foram inferidos.

| Grade hipotética | Início da primeira linha | Primeira célula interna | Piso | Ocupação no par pedra |
| --- | --- | --- | --- | --- |
| A | **0xFFAB00** | 0xFFAB02 | 0xFFABE0 | 2 → 6 células não zero |
| B | **0xFFAD00** | 0xFFAD02 | 0xFFADE0 | 2 → 6 células não zero |

Para índices locais `x=0..5`, `y=0..13`:

```text
endereco_celula = base_da_grade + 0x10*y + 2*(x+1)
```

Esses são índices na estrutura de memória. Ainda não está demonstrado se todas as 14 linhas são visíveis, onde começa a linha visual zero ou qual grade corresponde a P1.

O ponteiro em FF851A vai de **FFABC4 = (x=1,y=12)** para **FFABCC = (x=5,y=12)** segundo essa hipótese. É uma mudança horizontal de quatro células no endereço apontado. Já FF84F4 muda de 3 para 5; a diferença entre essas trajetórias impede assumir que ambos descrevem a mesma peça no mesmo instante.

Os correspondentes `FF891A` e `FF8922` permanecem em **FFADCC = (x=5,y=12)** durante o par pedra, embora FF88F4 também mude de 3 para 5. Essa é outra evidência para testar separadamente coluna ativa, ponteiro de última peça e cursor de busca.

| Grade | Linha, coluna hipotéticas | Endereço da palavra | Antes → depois |
| --- | --- | --- | --- |
| A | 12, 3 | FFABC8 | 0 → 1 |
| A | 12, 5 | FFABCC | 0 → 2 |
| A | 13, 3 | FFABD8 | 0 → 2 |
| A | 13, 5 | FFABDC | 0 → 2 |
| B | 11, 1 | FFADB4 | 0 → 2 |
| B | 12, 1 | FFADC4 | 0 → 2 |
| B | 13, 0 | FFADD2 | 0 → 1 |
| B | 13, 1 | FFADD4 | 0 → 2 |

As células já ocupadas permanecem iguais. O padrão é compatível com armazenamento de peças assentadas; confirmar exige capturar a queda e o momento de travamento. As grades completas estão em `estruturas/grades.md`, e as oito mudanças em `celulas_alteradas_pedra.csv`.

## O que já foi executado

- Leitura direta de C:\MAME e dos relatórios anteriores; identificação do executável 0.289.
- Comparação integral dos dois pares e validação de 757 linhas de CSV.
- Verificação byte a byte do ZIP contra suas fontes soltas.
- Extração de campos, ponteiros e grades dos quatro dumps, incluindo validação de bordas.
- Quatro testes automatizados das ferramentas, todos aprovados.
- Verificação dos parâmetros do laboratório com `-showconfig`, sem iniciar a emulação.
- Comparação de SHA-256 e metadados antes/depois das 11 fontes acompanhadas; resultados no manifesto de preservação.

O conteúdo de `Original` já existente no projeto não foi analisado nem alterado: esta etapa usa o jogo arcade local em C:\MAME.

## Testes ainda necessários

1. Repetir o mesmo controle sem entrada a partir de um save state e conferir determinismo.
2. Separar esquerda, direita, baixo e rotação por um quadro, com o mesmo estado e o mesmo número de VBlanks.
3. Confirmar A/B com entrada somente de P1 e depois somente de P2.
4. Testar FF84F4/FF8488 na peça ativa e nos limites laterais; distinguir coluna de índice/estado.
5. Observar se FF851A muda durante o movimento ou apenas em assentamento/varredura.
6. Investigar os campos de possível Y usando queda sem deslocamento lateral e contexto dos escritores.
7. Capturar PC e instruções de escrita por watchpoints; confirmar formato, unidade, pivô e rotina de colisão antes de implementar o comportamento no projeto.

O procedimento e os comandos estão em `METODOLOGIA.md`. Não foi feito patch de ROM, alteração de configuração original, escrita na memória emulada ou teste de hipótese por mutação.

## Referências primárias

- [Driver CPS2 do MAME 0.289](https://github.com/mamedev/mame/blob/mame0289/src/mame/capcom/cps2.cpp): mapa RAM, sistema e entradas.
- [Comandos de memória do depurador](https://docs.mamedev.org/debugger/memory.html): formato de `save` e endereçamento.
