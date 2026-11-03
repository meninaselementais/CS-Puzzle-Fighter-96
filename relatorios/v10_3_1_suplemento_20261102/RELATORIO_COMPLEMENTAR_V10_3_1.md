# V10.3.1 — suplemento de dupla ativa e contornos

**02/11/2026 — MAME 0.289, spf2tu USA 960620, P1.**
Branch `feature/v10-gem-physics`, HEAD `136238edf12b68761d72713b2225de9363e6ba94`.

**Decisão técnica: a V10.3.1 pode ser encerrada como etapa de medições para o escopo P1 documentado.** As duas lacunas imediatas — sprites ativos na aproximação/contato e contornos em pixels — foram medidas e repetidas. Isso não certifica equivalência visual integral do jogo. A V10.3.2 continua sendo um plano, sem implementação.

Nenhuma das 18 coletas anteriores foi repetida. Nenhum motor lógico, RNG, controle, main ou animação foi alterado. Não houve instalação, staging, commit ou push. Este documento complementa, sem substituir, `relatorios/v10_3_1/RELATORIO_V10_3_1.md`.

## 1. Fontes e preservação

| Fonte | Local |
|---|---|
| Coleta suplementar primária | `laboratorio/auto_20261102_172410_209057` |
| Repetição suplementar | `laboratorio/auto_20261102_172448_482209` |
| Lua suplementar, nova | `scripts/medir_dupla_ativa_v10_3_1.lua` |
| Analisador suplementar, novo | `scripts/analisar_dupla_ativa_v10_3_1.py` |
| Leitor PNG RGB8, novo | `scripts/png_rgb_v10_3_1.py` |
| Evidências deste suplemento | `relatorios/v10_3_1_suplemento_20261102/` |

Save state validado: `laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta`.
SHA-256: `4fce8afe569173625dc29d02b646f766b0c908c5341d84b6b764476044ee43ee`.

O coletor existente `scripts/automatizar_mame.py` foi reutilizado sem alteração. Os dois manifestos confirmam MAME 0.289, saída 0, Lua concluída sem erro e fontes preservadas. O analisador reconferiu hashes de todas as fontes originais e das cópias imutáveis (executável, ROMs, estado). A EEPROM isolada de cada sessão é atualizada normalmente pelo emulador; não se exige que sua cópia final coincida com a cópia inicial. A EEPROM original permanece intacta.

Lua original Gemini, Lua corrigida anterior, relatórios, fixtures e sessões anteriores permanecem preservados. Os 48 hashes do manifesto da entrega V10.3.1 anterior foram reconferidos ao concluir esta entrega. A continuidade anterior foi copiada antes da atualização. Não foram incluídos ROMs, save states, dumps binários ou disassembly nos arquivos deste suplemento.

## 2. Cenários necessários

| Caso | Preparação sintética | Finalidade |
|---|---|---|
| `isolated_approach` | Dupla vertical em X=2, Y nativo=14, offset inicial −8; pivô azul=1, satélite verde=3; chão sem gemas | Aproximação, primeiro contato, janela completa, depósito sem vizinha da mesma cor |
| `same_color_approach` | Mesma dupla, Y=13, offset −8; apoio azul em `(2,13)` | Observar contato e ligação visual com vizinha da mesma cor |
| `empty_background_reference` | Mesmo estado/pré-turno, tabuleiro vazio e dupla zero fora da região medida | Controle de pixels do fundo para subtração exata; não é um terceiro ensaio de física |

**96 quadros por caso e por execução.** São dois ensaios suplementares e um controle de fundo, não uma repetição da matriz anterior. Total por execução: 288 amostras CPU, 288 de vídeo, 23.040 linhas de descritores e 288 PNGs. As duas execuções somam 576 PNGs preservados nas sessões; a entrega contém a coleção primária completa e hashes comparativos da repetição.

Cada caso restaura o estado validado e usa o mesmo pré-turno nativo do coletor anterior. Há quatro quadros neutros antes da preparação para eliminar Down residual. Só a RAM emulada é preparada; todas as escritas têm cenário, estágio, quadro, endereço, largura e valor anterior/novo em `injections.csv`. Todas ocorreram em `setup`, quadro 0. **Não há escrita de instrumentação na RAM durante os 96 quadros medidos.**

Não há botão pressionado durante os dois ensaios: entrada lida=0 e orientação=0 até o depósito. Os parâmetros de queda não foram reescritos: o script verifica intervalo nativo=1 e incremento=1. O offset inicial −8 é uma condição sintética para capturar a aproximação final, não uma nova regra de queda.

## 3. Descritores capturados

- `$FFB300`, `$FFB320`: pivô e satélite ativos de P1.
- `$FFB340`, `$FFB360`: os dois descritores NEXT de P1, registrados separadamente no mesmo grupo `active_next` (índices 2 e 3). Não confundir NEXT com gemas ativas.
- `$FFB400 + ((row−1)*6+col)*$20`: 36 células, colunas 0..5 e linhas 8..13.

Cada descritor registra endereço, estado atual/anterior, ponteiro numérico do script, timer, layout, dx/dy, tile, atributo, dimensões atual/anterior e coordenadas locais. Os descritores de células também registram o word lógico e auxiliar Power. Nenhum conteúdo de script de ROM foi exportado.

`states.csv` registra em cada relógio: fase, X/Y, offset, orientação, contato, contagem de contatos, entrada atual/anterior, cores, idade, contador/intervalo/incremento de queda e deslocamento do tabuleiro. `sprites.csv` contém os descritores completos; `transicoes_sprites.csv` resume mudanças relevantes.

## 4. Relógios: RAM não é o bitmap do mesmo índice

Há três referências diferentes, explicitadas para evitar atribuir uma troca de tile ao PNG errado:

1. **CPU F:** callback de frame, antes do processamento seguinte.
2. **RAM de vídeo F:** callback `frame_done`, junto à solicitação de snapshot. Em 285 pares conferidos (95 por caso), todos os estados e descritores dessa linha coincidem com CPU F+1.
3. **Pixels do PNG F:** nesta rota de captura, correspondem ao estado de desenho anterior. Na aproximação, 58 comparações (F3..31 dos dois ensaios) reproduzem exatamente as posições calculadas a partir da RAM de vídeo **F−2**. As mudanças de tile em vídeo F34/F38 aparecem nos pixels F36/F40; o halo ativo cessa no PNG F32 após o depósito registrado em vídeo F30.

O primeiro PNG ainda mostra a imagem anterior à preparação, comum ao controle de fundo; foi preservado, mas não contado como imagem da dupla já preparada. Não se inventou um PNG inicial corrigido. O F2 tem as gemas preparadas; o teste quantitativo de alinhamento começa no F3 para ter uma linha RAM anterior registrada.

Isso é um **deslocamento observado entre os relógios desta captura**. Não determina sozinho quanto vem do buffering de objetos CPS-2, do emulador ou da ordem dos callbacks; não é uma alteração autorizada à física. O relatório anterior continua válido como registro dos campos de RAM, mas suas convenções de RAM-vídeo não bastam para atribuir a cada bitmap o estado gráfico do mesmo índice. Este suplemento fornece a aferição adicional de pixels para os novos casos.

## 5. Aproximação, contato e depósito

Os dois ensaios têm a mesma cronologia:

| Marco | CPU | RAM de vídeo | Evidência nos pixels |
|---|---:|---:|---|
| Aproximação final | Antes de F15, offset negativo | F1..13; offset −7..−1 nas amostras disponíveis | PNG F2..15: translação vertical, contorno constante |
| Primeiro contato | F15, contador 16 | F14, contador 16, offset 0 | PNG F16: atinge posição final sem diminuir altura |
| Contato completo | F15..30, contador 16..1 | F14..29, contador 16..1 | PNG F16..31: corpo estável, halo intermitente do pivô |
| Depósito | F31, fase 1 | F30, fase 1 | PNG F32: termina halo; no caso isolado o corpo não muda |
| Contato de mesma cor: segundo tile | F35 | F34, tile 0x5A4E | PNG F36..39: ligação intermediária |
| Contato de mesma cor: tile final | F39 | F38, tile 0x5A08 | PNG F40..96: forma conectada estável |

Os descritores ativos, durante toda a aproximação e janela de contato, mantêm:

| Gema | Estado | Tile | Atributo | dx/dy | Contorno do corpo |
|---|---|---|---|---|---|
| Pivô azul | 0x02 | 0x5A00 | 0x0001 | 0/0 | 14×14, 184 pixels |
| Satélite verde | 0x06 | 0x5A00 | 0x0003 | 0/0 | 14×14, 184 pixels |

A posição depende de X/Y/offset do jogador; dx/dy=0 nos descritores não significa ausência de movimento. A área da célula/tile é 16×16, mas a arte visível ocupa 14×14 nesse estado. Depois do depósito, os bytes dos descritores ativos podem continuar preenchidos: **são residuais e não provam que a dupla ainda está sendo desenhada**. A fase e os descritores das células distinguem a transferência.

## 6. Método de medição dos contornos

Não foi instalada biblioteca. O leitor PNG padrão do suplemento decodifica RGB8 nativo 384×224, verifica os CRCs e reconstrói os filtros 0..4. Seu autocheck gera amostras conhecidas para os cinco filtros e confirma pixels e componentes conexos.

Para cada quadro, subtrai-se **exatamente** a captura do controle de fundo com o mesmo índice, na região do poço P1 `x=16..111, y=128..207`. Não há redimensionamento, suavização ou limiar aproximado. Fora das colunas ocupadas pela dupla (`x=48..63`), todos os pixels dessa região são iguais ao controle, verificado automaticamente.

Todos os pixels diferentes do fundo foram classificados sem resíduo:

- Corpo azul/ciano: B>R e B≥G.
- Corpo verde: G>R e G>B.
- Halo rosa: RGB exato `(255,187,187)`.

A classificação foi validada neste conjunto de cores, não serve como segmentador universal do jogo. Inclui os pixels ciano de destaque no corpo azul. O halo fica numa máscara separada para não ser interpretado como crescimento da gema.

`medicoes_pixels.csv` contém caixa delimitadora inclusiva, largura, altura, área, número de pixels de borda, componentes conexos e SHA-256 da máscara normalizada por translação. `contornos_runs.csv` lista os segmentos horizontais de **todos** os pixels de cada máscara, inclusive buracos, por linha e quadro; permite reconstruir o contorno sem inferir uma elipse ou retângulo. O número de pixels de borda não deve ser confundido com perímetro geométrico subpixel.

## 7. Compressão, troca de sprite e recuperação

### 7.1 Pouso isolado: sem compressão detectada

Em PNG F2..96, pivô e satélite mantêm não só largura/altura 14×14 e área 184, mas a **mesma máscara normalizada, pixel a pixel**. Aproximação é translação; contato e depósito não achatam o corpo. Nas células depositadas, o tile permanece 0x5A00. Não há recuperação de uma deformação porque nenhuma deformação do corpo foi observada neste caso.

### 7.2 Halo: variação cosmética separada do corpo

Nos PNGs F3,5,7,...,31 aparece um contorno rosa de 16×16 com 60 pixels ao redor do pivô. Nos demais quadros ele não aparece. O corpo permanece 14×14/184 pixels inclusive quando o halo está aceso. Usar a caixa de todos os pixels visíveis produziria uma falsa alternância 14×14 ↔ 16×16. O halo não é evidência de compressão/recuperação do corpo. A rotina interna específica que o emite não foi identificada por write-tap; sua separação em pixels foi observada diretamente.

### 7.3 Mesma cor: conexão por troca de arte

| PNG | RAM de vídeo associada | Tile das duas células azuis | Medida por célula azul* | Medida das duas juntas |
|---|---|---|---|---|
| F16..35 | Contato e primeiros quadros após depósito | 0x5A00 | 14×14, área 184 | 2 componentes, área 368; caixa conjunta 14×30 com intervalo entre elas |
| F36..39 | F34..37 | 0x5A4E | 14×16, área 212 | 1 componente, caixa 14×32, área 424 |
| F40..96 | F38 em diante | 0x5A08 | 16×16, área 244 | 1 componente, caixa 16×32, área 488 |

\* Após estabilização de posição, cada célula usa seu recorte fixo de 16 linhas: superior y176..191 e inferior y192..207. Antes da estabilização não se usa esse recorte como tamanho de uma gema em movimento.

No relógio de descritores, a sequência é: F30..33 tile 0x5A00 por 4 quadros; F34..37 tile 0x5A4E por 4; F38 retorna a um script longo com tile 0x5A08/layout 0x8001. Nos pixels, o estágio intermediário dura **4 quadros**, F36..39, e o final começa em F40. A máscara final não muda até o último quadro F96. Satélite verde continua 14×14/184 pixels durante toda a coleta.

Os estados, tiles e máscaras provam uma **mudança discreta de contorno por troca de sprite e conexão com a vizinha**. A forma final não retorna às duas gemas separadas; não é uma curva elástica de achatamento e retorno ao tamanho inicial. Dx/dy e atributos desses descritores permanecem constantes; não foi observado um parâmetro de escala contínua. Isso não afirma que o arcade nunca possa usar outra deformação em outro cenário.

Nenhuma porcentagem de compressão foi criada, nem derivada dos coeficientes atuais do Godot.

![Contornos extraídos dos pixels](contornos_comparados.svg)

## 8. Validação e determinismo

As duas sessões têm **igualdade byte a byte** de `states.csv`, `sprites.csv` e `injections.csv`. Todos os **288 pares de PNGs têm SHA-256 idêntico**, não apenas contorno semelhante. O arquivo `repeticao_png_sha256.csv` lista cada comparação.

O analisador exige, por asserção, contadores 16..1, depósito no quadro esperado, entradas neutras, orientação, tiles/atributos ativos, todas as transições de estado/descritor entre os relógios, preservação de fontes, classificação completa dos pixels, posição na aproximação e contornos estáveis. Falha se qualquer condição divergir. Executar com Python normal, **sem `-O`**.

Somente os três casos suplementares foram executados duas vezes no MAME. Reexecutar o analisador sobre os mesmos dados não é uma nova medição. Durante o desenvolvimento do analisador, uma primeira verificação rejeitou a EEPROM da sessão por compará-la à imagem inicial; a condição foi corrigida para verificar a fonte original e excluir somente a EEPROM emulada mutável. Os dados MAME não foram alterados para satisfazer o teste.

## 9. Limites ainda não comprovados

- Generalização para P2, outras cores, outras velocidades, orientações e geometrias de apoio. A configuração medida é vertical, P1, pivô azul/satélite verde.
- Não foi medida uma partida natural completa nem todas as deformações possíveis em Power Gems/Counter Gems. As medições Power já existentes não foram repetidas.
- O ensaio começa com offset sintético −8, mede o trecho final da aproximação e não toda a queda desde o spawn.
- O halo foi separado visualmente; sua origem interna exata não foi localizada.
- O deslocamento de dois quadros entre RAM de vídeo e bitmap foi aferido nesta coleta. Não se atribui sua causa completa nem se generaliza automaticamente para todas as coletas históricas.
- A ausência de compressão elástica nos dois casos não é prova de ausência em todos os estados do jogo.

Esses limites são ampliações de cobertura, não as duas lacunas imediatas que impediam encerrar as medições planejadas. O encerramento é da **V10.3.1 no escopo ensaiado**, não uma certificação de todos os sprites do CPS-2.

## 10. Plano de implementação V10.3.2 — ainda não autorizado

1. **Ghost Gem Flicker:** manter a máscara de desaparecimento enquanto a onda continuar logicamente pendente; liberar a sobreposição somente após reconciliar sua remoção. Não somar dez quadros fixos ao efeito. O diagnóstico atual deve virar uma verificação de ausência de reaparição quando a correção for autorizada.
2. **Rotação:** consumir os oito offsets assimétricos medidos anteriormente, preservando pivô, cores e geometria lógica; nenhuma coleta nova de giro é necessária para começar esse trabalho.
3. **Dupla ativa:** separar translação física, corpo do sprite e halo. Não aplicar squash senoidal genérico ao contato dos casos isolados medidos. Visibilidade depende da fase; descritor residual não deve gerar gema fantasma.
4. **Contato de mesma cor:** representar o estado de ligação por tile/arte correspondente e duração medida de 4+4 quadros do script; manter a forma conectada final. Não tratar o efeito como escala transitória de uma gema independente.
5. **Power Gems e cadeias:** consumir as fases e transições registradas na entrega anterior. Não substituir sequências por flash genérico de 14 quadros nem antecipar gravidade em relógio independente.
6. **Contrato de apresentação:** separar o relógio do modelo do relógio gráfico e das convenções dos coletores. O atraso aferido na captura não justifica atrasar artificialmente a física do Godot. Qualquer mudança futura em `main.gd` exige autorização específica; ela permanece intocada.
7. **Validação futura:** preservar as fixtures antigas e novas, verificar não reaparição, estados de contato, conexão e endpoints. Executar regressões de física/cadeias/RNG/rounds quando houver implementação; não repeti-las agora sem mudança de código.

## 11. Como reproduzir a análise

Os scripts abaixo são novos; os três scripts V10.3.1 anteriores não mudaram. A saída do analisador deve ser um diretório **novo**, pois ele recusa sobrescrever resultados:

```powershell
$pfRoot = 'C:\Projetos\CS-Puzzle-Fighter-96'
$pfNew = 'C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\work\suplemento_reanalise_nova'
python "$pfRoot\scripts\png_rgb_v10_3_1.py"
python "$pfRoot\scripts\analisar_dupla_ativa_v10_3_1.py" $pfRoot "$pfRoot\laboratorio\auto_20261102_172410_209057" "$pfRoot\laboratorio\auto_20261102_172448_482209" $pfNew
```

Para uma repetição MAME futura expressamente necessária, usar o executor existente com `--lua scripts/medir_dupla_ativa_v10_3_1.lua`, `--state` apontando ao estado validado e `--video gdi`. Não executar essa coleta novamente apenas para retomar o projeto.

## 12. Entrega e estado final

- `summary.json`, `execucao_primary.json`, `execucao_repeat.json` e `MANIFESTO_SHA256.json`: contagens e proveniência.
- `states.csv`, `sprites.csv`, `injections.csv`: fixtures numéricas completas.
- `eventos.csv`, `transicoes_sprites.csv`: marcos de contato/depósito/tile.
- `medicoes_pixels.csv`, `contornos_runs.csv`: medições e contornos exatos por quadro.
- `repeticao_png_sha256.csv`: 288 pares de imagens idênticas.
- `capturas/`: 288 capturas primárias completas, sem edição.
- `contornos_comparados.svg`: diagrama vetorial derivado das máscaras, sem modificar PNGs.
- `CONTINUIDADE_ANTES_SUPLEMENTO_20261102.md`: cópia da continuidade anterior; `CONTINUIDADE_PROJETO.md` atualizado na raiz.

Branch e HEAD preservados, nenhum arquivo rastreado alterado e nada staged. Somente a continuidade local foi atualizada, e foram acrescentados três scripts e o relatório complementar com suas evidências. O Git ignora a maior parte dos CSVs/PNGs de `relatorios/`; ignorado não significa entregue ao GitHub. Nenhum commit ou push foi realizado.
