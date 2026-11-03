# V10.3.1 — recuperação e medições visuais do MAME

Data de referência: 01/11/2026. MAME 0.289, `spf2tu` USA 960620, P1.
Base: `feature/v10-gem-physics`, HEAD `136238edf12b68761d72713b2225de9363e6ba94`.
Somente instrumentação, observações e documentação. Nenhuma implementação de animação, alteração de motor lógico, RNG, controles, regras, main, commit ou push.

## 1. Recuperação do Gemini

Git inicial limpo, incluindo arquivos não rastreados não ignorados. O trabalho estava em `laboratorio/`, ignorado pelo Git:

- `laboratorio/v10_3_1_mame_probe.lua`: **453 linhas físicas**, compatível com a indicação aproximada de +455 da interface. Lido integralmente e preservado byte a byte; SHA-256 `669ec58f73e8f3b7b01af7a28e2473e68b33098da6e8e680e2ef2d3f9b6ebe4f`.
- `laboratorio/auto_20261101_220908_925177`: execução real, 8 cenários, 407 amostras CPU, CSV de 72 entradas das tabelas, 11 PNGs, manifesto e conclusão. A Lua da sessão tem o mesmo hash. Não era apenas planejamento.
- Sondagens anteriores `auto_20261101_215438_313455`, `auto_20261101_215706_634481`, `auto_20261101_220021_908616`: disassembly e dumps locais. Serviram à conferência dos endereços; nenhum dump ou trecho de ROM foi incluído na entrega.
- Não foi encontrado relatório V10.3 separado nos diretórios solicitados. O diagnóstico V10 e o relatório V10.2 foram examinados; as regressões já comprovadas não foram repetidas.

**Qualidade da coleta recuperada:** a extração numérica das tabelas foi confirmada pela nova execução. As alegações dos nomes dos cenários não foram aceitas como resultados. A Lua usa contato em `$16F(A6)` e offset em `$16C(A6)`; os campos confirmados são `$176` e `$242`. Apaga a linha 14, que contém a borda inferior. Usa o save state `auto_20261028_141709_059767`, diferente da referência de jogo validada. Nos 42 quadros de cada caso de rotação, a orientação não muda; nos casos de pouso e Power também não há a sequência anunciada. A explosão começa, mas termina a coleta ainda na fase 11. O marcador de conclusão só prova que o script terminou.

Uma tentativa nova com esse mesmo estado foi preservada em `auto_20261101_222601_263613`: também não serve como medição de giro. A sondagem corrigida preliminar `auto_20261101_222659_210571` confirmou as transições com o estado certo. As duas fontes finais abaixo são as usadas nas tabelas finais.

## 2. Método e reprodução

Sessão primária: `laboratorio/auto_20261101_222825_850720`.
Repetição: `laboratorio/auto_20261101_222903_899708`.
Lua final SHA-256: `cf8e97494fe41cecc1d7817f994c2ee3760890f65cc3be1bac27d5bab3b3e1f3`.
Save state: `laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta`, SHA-256 `4fce8afe569173625dc29d02b646f766b0c908c5341d84b6b764476044ee43ee`.

O executor existente copia e verifica MAME, ROMs, EEPROM e estado em sessão isolada. As fontes finais têm código de saída 0, Lua concluída sem erros e hashes das fontes preservados. Nenhuma ROM foi modificada. Não foram instaladas dependências.

São ensaios sintéticos: restauração do estado a cada caso, pré-turno nativo até estar em jogo, preparação de RAM, depois execução do arcade. As escritas estão em `injections.csv`, em ordem; as definições e os quadros de preparação estão na Lua. Nos casos de crescimento e união há intervenção adicional explícita no quadro 35, adicionando gemas e solicitando fase 3. São medições de resposta a esse estado, não uma partida natural. O caso de formação já começa com o quadrado completo; não mede a queda da quarta gema.

**Resultado:** 18 cenários, 1.100 amostras CPU, 1.099 amostras de vídeo e PNGs por sessão, 39.564 descritores de células no relógio de vídeo. CPU e vídeo são idênticos entre as duas execuções. Em 1.080 pares de amostras sem fronteira de cenário/injeção, todos os campos e descritores de vídeo F coincidem com CPU F+1. A última amostra CPU da cadeia encerra o processo antes de `frame_done`, por isso não existe seu PNG; não foi fabricado.

Relógios:

- `visual_trace_v10_3_1.csv`: callback antes do próximo processamento CPU.
- `video_trace.csv` e `video_clock.csv`: RAM no callback de vídeo, junto ao PNG. O PNG F normalmente corresponde ao estado CPU F+1, conforme a referência anterior; usar o CSV de vídeo diretamente nas fronteiras com injeção, restauração ou encerramento.
- Entrada solicitada no quadro 2 aparece na RAM do jogo no quadro CPU 4. É relação entre callbacks, não latência do controle físico.
- Y nativo da dupla corresponde à linha lógica Y−1; grade `(col,row)` usa linhas 0..13. Unidades de deslocamento são pixels nativos; o Godot desenha células de 32 px, o arcade de 16 px.

Reprodução no PowerShell, a partir da raiz do projeto:

```powershell
python scripts/automatizar_mame.py --lua scripts/medir_visual_v10_3_1.lua --state laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta --video gdi --timeout 100
# Executar duas vezes; substituir SESSION e REPEAT pelos diretórios impressos:
python scripts/analisar_visual_v10_3_1.py . SESSION REPEAT relatorios/v10_3_1
```

O estado e as ROMs são pré-requisitos locais, não parte da entrega. As fixtures são os traços completos observados e os descritores normalizados. O analisador exige repetição idêntica, 72 entradas, cobertura dos oito passos em cada cenário de giro e igualdade com `animation_ram` antigo; falha por asserção em divergências.

## 3. Rotação — tabelas e oito passos

Confirmado por observação e pela rotina local em `$123BE..$12422`: timer `$24C` é decrementado antes da leitura. Grupo de 32 bytes: 8 palavras X seguidas por 8 Y; índice `2*timer + 32*grupo`. O grupo é a **orientação de destino**, não a orientação inicial. Direção `$247=0` seleciona `$12DA0`, `$247=1` seleciona `$12D00`; quick turn `$247=2` usa grupo 4 de `$12D00`.

`rotation_tables_12D00_12DA0.csv` contém as 72 entradas assinadas. Passos abaixo estão na ordem timer **7,6,5,4,3,2,1,0**:

| Tabela/grupo | dx por passo | dy por passo |
|---|---|---|
| 12D00/0 | 14,12,10,8,6,4,2,0 | 12,8,6,4,3,2,1,0 |
| 12D00/1 | -12,-8,-6,-4,-3,-2,-1,0 | 14,12,10,8,6,4,2,0 |
| 12D00/2 | -14,-12,-10,-8,-6,-4,-2,0 | -12,-8,-6,-4,-3,-2,-1,0 |
| 12D00/3 | 12,8,6,4,3,2,1,0 | -14,-12,-10,-8,-6,-4,-2,0 |
| 12D00/4 | 0,0,0,0,0,0,0,0 | 4,3,2,1,0,0,0,0 |
| 12DA0/0 | -14,-12,-10,-8,-6,-4,-2,0 | 12,8,6,4,3,2,1,0 |
| 12DA0/1 | -14,-12,-10,-8,-6,-4,-2,0 | -15,-14,-13,-12,-10,-8,-4,0 |
| 12DA0/2 | 15,14,13,12,10,8,4,0 | -14,-12,-10,-8,-6,-4,-2,0 |
| 12DA0/3 | 14,12,10,8,6,4,2,0 | 15,14,13,12,10,8,4,0 |

Não substituir por seno/cosseno ou supor simetria: a assimetria de `$12DA0` foi observada.

Novos casos: orientação inicial 0,1,2,3 × Button 1 (anti-horário, 256) / Button 2 (horário, 512); corredor vertical com ambos os botões em casos separados. Cada caso tem os oito passos nos quadros CPU 4..11: **80/80 valores dx/dy conferidos**. No corredor a orientação permanece 0, as cores trocam, X fica zero e Y segue 4,3,2,1,0,0,0,0. Não interpretar a troca de cores como mudança geométrica de 180°.

Comparação com a referência antiga: `animation_ram` cobre `$FF8500..$FF856F`; direção no byte 0x47, dx/dy nos offsets 0x48/0x4A e timer em 0x4C. **794 amostras em 55 cenários**, incluindo o quadro final de timer zero, coincidem com as tabelas. Demais amostras não têm rotação ativa e não contam como validação dos oito passos. Evidências: `rotacao_por_quadro.csv`, `comparacao_animation_ram.csv`.

Limites: corredor medido novo com orientação vertical 0; kicks irregulares, orientação vertical 2 no corredor e sobreposição de giros não foram ampliados nesta coleta. As fixtures antigas cobrem outros casos de física, sem provar toda trajetória gráfica possível.

## 4. Pouso, assentamento e sprites

Descritor de célula: `$FFB400 + ((row−1)*6+col)*$20`. O renderizador local confirma blocos de $20 e varredura por linha. Campos exportados: estados atual/anterior, endereço do script (somente endereço numérico), timer, layout, dx/dy, tile, atributo, dimensões atuais/anteriores e posição local dentro da Power. Não são dumps de instruções ou pixels de ROM.

Em `landing_contact` e `landing_same_color`, primeiro contato CPU F1 com contador 16; F16 contador 1; F17 depósito/phase 1. A janela é de 16 quadros. O estado de vídeo F16 já mostra o depósito. Não confundir contato da dupla ainda ativa com animação de célula depositada.

| Caso/célula | Evidência no relógio de vídeo |
|---|---|
| Pouso isolado `(2,13)` | F16: estado 0x02, tile 0x5A00, layout 0x8001, dx=dy=0; sem mudança de tile nessa célula até o fim do ensaio. |
| Contato de mesma cor `(2,12)` e apoio `(2,13)` | F16..19: estado 0xA0/tile 0x5A00; F20..23: tile 0x5A4E; a partir de F24: tile 0x5A08/layout 0x8001. dx=dy=0, atributo 0x0001. O apoio também muda de sprite. |
| Gema separada `(3,12)` | F3: chegada, estado 0xA2/tile 0x5A00; F7: 0x5A4E; F11: 0x5A08. Mesma sequência de 4+4 quadros antes do sprite assentado, com cor/estado distintos. |

O CSV normalizado contém cada quadro, timers e todos os tiles das 36 células observadas. A curva é uma **troca de arte/estado**, com offsets nulos nesses exemplos. Esses dados não justificam aplicar a todas as gemas uma escala contínua 0,85 ou os coeficientes 0,17/0,14 do Godot. A interpretação de cada contorno como compressão ou conexão com a vizinha exige medição pixel a pixel; nenhuma porcentagem de squash do arcade é alegada. Descritores da dupla ativa em `$FFB300` não foram exportados nesta matriz: a forma visual durante a janela de contato, antes do depósito, permanece lacuna específica.

## 5. Power Gems — formação, crescimento e união

Dimensões dos descritores são **largura−1/altura−1**. Endpoints e evolução abaixo foram lidos no MAME, sem derivação pelo Godot.

| Caso | Resultado observado no relógio de vídeo |
|---|---|
| Formação 2×2 | F1: quatro células já têm códigos Power e dimensões 1×1 no descritor. No canto superior esquerdo, tiles 0x5A20,22,24,26,24,22 em blocos de 8 quadros; F49 retorna a 0x5A20 com layout 0x8001. Transição inicial de 48 quadros nesse descritor. |
| Crescimento 2×2 → 2×3 | Adição da linha no F35. F35 ainda individual no novo topo; F36: códigos Power e dimensões 1×2. Topo novo segue a sequência de 8 quadros; F84 fica no tile 0x5A20/layout 0x8001. |
| União de duas 2×2 por ponte → 5×2 | Ponte adicionada F35. Na célula `(2,12)`, F36..45 há retângulo intermediário 3×2, estado 0x78. F46 chega a 5×2, estado 0x7C, dimensões 4×1. Tiles 0x5A1C,1D,1E,1F,1E,1D em blocos de 8; F94 estabiliza em 0x5A1C/layout 0x8001. |

A união não aparece como um único salto visual uniforme: a amostra de F45 ainda mostra cristais separados; F94 mostra o cristal contínuo de cinco colunas. Dimensões lógicas, tile de borda/miolo e conclusão do script visual são eventos diferentes. Os demais cantos e miolos têm seus próprios estados/tiles, todos exportados. Não foi extraído o conteúdo binário dos scripts em ROM nem feita reconstrução de sua linguagem completa.

## 6. Explosões — cronologia e remoção

`cronologia.csv` registra cada mudança de fase, contador ou contato. `sprites_por_quadro_video.csv` registra a aparência por célula durante propagação e espera.

Caso simples (quatro gemas na linha inferior; Crash + três normais):

| Marco | Quadro CPU | Quadro de vídeo correspondente |
|---|---:|---:|
| Primeira visita à fase 8 | 5 | 4 |
| Retornos 8 → 3 com clear_timer=40 | 6,12,18 | 5,11,17 |
| Fase 9 | 24 | 23 |
| Fase 10 | 25 | 24 |
| Fase 11, timer 40 | 26 | 25 |
| Sprite já usa tile vazio 0x5820, mas célula lógica ainda marcada | 61 | 60 |
| Fase 11, timer 1 | 65 | 64 |
| Remoção lógica, volta à fase 3 | 66 | 65 |

As gemas recebem flags da propagação já nos retornos de fase 8; portanto a animação não começa necessariamente na fase 9. Na célula `(1,13)`, os estados percorrem 0x44..0x58 e depois 0x5A/5E/42/46/4A/4E durante os passos observados. O tile 0x6410 dá lugar à sequência 0x6450..0x647C; F60 usa 0x5820. A captura F60 confirma que a gema original já não aparece, embora seu word lógico permaneça não zero até F65 de vídeo. Não equiparar não zero em RAM a sprite visível.

O timer permanece em 40 durante a propagação e só faz a contagem final em phase 11. CPU F26..65 são 40 amostras com 40..1; a remoção é a transição seguinte. Não somar indiscriminadamente "40 quadros desde a primeira marcação".

Cadeia de duas ondas:

- Primeira fase 8 em F36; retornos com timer 40 em F37,43,49,55,61.
- F9=67, F10=68, F11=69..108 (40..1); primeira remoção em F109.
- F3=109..113: queda intermediária; F1=114, F2=115, F3=116, F4=117.
- Próxima avaliação em F121; propagação retorna a F3 em F122.
- Segunda F9=128, F10=129, F11=130..169; segunda remoção em F170.
- Após nova avaliação sem onda, atravessa as fases restantes e gera a dupla seguinte. A timeline integral está no CSV; não se usa o ensaio antigo interrompido como prova da segunda onda.

## 7. Ghost Gem Flicker — causa reproduzida e recomendação V10.3.2

`reproduzir_ghost.gd` carrega as classes atuais, prepara o mesmo caso simples, avança `resolve_frame()` e `arena.step_from_model()` uma vez por quadro e grava as células lógica/visual. Não altera as classes. A asserção exige a reaparição: é um diagnóstico que **passa quando reproduz o bug**, não um teste que certifica ausência do bug.

Reprodução real com Godot 4.7.2, resultado `GHOST_REPRODUCED frames=[56..65]`:

| Quadro | Lógica | Apresentação |
|---|---|---|
| 24 | fase 9, timer 40 | `pre`, timer 10, override com gemas |
| 34 | fase 11, timer 32 | `burst`, timer 14, override sem gemas |
| 48 | fase 11, timer 18 | `drop`, timer 8 |
| 56..65 | fase 11, timer 10..1, gema lógica=2 | fila acaba, override é limpo; fallback devolve gema lógica=2; reaparece |
| 66 | fase 3, gema lógica=0 | desaparece novamente |

**Origem demonstrada:** `cs_arena.gd:599` reconstrói antecipadamente todas as ondas em um tabuleiro-sombra. `start_next_wave()` usa pre=10; `detonate_active_wave()` usa burst=14; `begin_wave_fall()` usa no mínimo 8. Quando a fila esvazia, `start_next_wave()` elimina `visual_cells_override`. `get_visual_cells()` passa a devolver o tabuleiro lógico, que `gem_motion.gd` corretamente mantém até clear_timer zerar. É o desacordo entre esses relógios que reexibe a gema; não uma falha do flood-fill lógico. Em cadeias, antecipar gravidade/ondas no tabuleiro-sombra também pode desencontrar a ordem observada.

Recomendação, **não implementada**:

1. Manter a máquina lógica V10.2 e seus endpoints. Vincular a apresentação à identidade da onda e aos marcos reais de propagação, fase 11, remoção e gravidade.
2. Enquanto uma onda continuar logicamente pendente, preservar sua máscara/estado visual de desaparecimento mesmo que o efeito de explosão já termine. Liberar a sobreposição somente depois de reconciliar a remoção lógica dessa onda; não acrescentar 10 quadros fixos como correção universal.
3. Consumir queda e próxima onda na ordem real. Evitar pré-calcular uma cadeia inteira como relógio independente de apresentação. Se for necessário um sinal do modelo, discutir isso como integração posterior, sem reescrever regras ou mudar quando consome RNG.
4. Para rotação, usar os oito offsets discretos medidos, em escala de pixels consistente, mantendo o pivô e as cores. Resolver depois o contrato de desenho, pois a main atual não consome esses offsets; ela permanece intocada nesta entrega.
5. Para pouso e Power, distinguir gema ativa, célula depositada, contato de mesma cor, formação e crescimento. Usar estados/tiles/durações observados; não aplicar o flash genérico de 14 quadros como substituto da sequência de cristalização.
6. Antes de integrar, inverter a expectativa do diagnóstico Ghost para exigir ausência de reaparição e acrescentar casos multi-onda, P2 e Power. Preservar as regressões antigas de física, cadeias, controles/RNG e rounds; rodá-las quando houver mudança de implementação.

Reprodução do diagnóstico:

```powershell
& ferramentas/godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path godot --script scripts/reproduzir_ghost_v10_3_1.gd -- C:/Projetos/CS-Puzzle-Fighter-96/relatorios/v10_3_1/ghost_godot.csv
```

## 8. Comparação com a implementação e limites de conclusão

| Área | Arcade medido | Godot atual | Situação |
|---|---|---|---|
| Giro | tabela discreta e assimétrica, 8 passos | `main.gd` usa `pair.positions()` final + offset vertical; não aplica `$248/$24A` | Diferença demonstrada por código e traços |
| Contato lógico | janela 16..1, depósito seguinte | `gem_motion.gd` já representa a janela | Preservar V10.2 |
| Contato visual | estados/tiles específicos, vizinho também reage | squash senoidal genérico e comparação de células; zera offsets na fase 1 | Não calibrado ao arcade |
| Power | resposta por célula, 8 quadros por tile nas sequências observadas; união intermediária | retângulo final e flash 14 | Diferença demonstrada |
| Explosão | propagação em fase 8, sprites já animando; sumiço visual anterior à remoção lógica | fila independente começa na fase 9 e pode encerrar cedo | Ghost reproduzido |
| Queda entre ondas | F3 quadro a quadro, retorno F1/F2/F3 após estabilizar | lógica já tem essa sequência; arena simula seu próprio tempo | Preservar lógica e sincronizar apresentação |

**Comprovado neste escopo:** tabelas 72/72; oito passos nos 10 casos novos; 794 comparações com `animation_ram`; janela e depósito nos dois casos; sprites de pouso/contato após depósito; formação 2×2, crescimento 2×3 e união 5×2; transições de tiles e dimensões; duas ondas com queda intermediária; sumiço visual antes da remoção lógica; reprodução do Ghost no Godot; repetição integral dos traços finais.

**Ainda não comprovado:** contorno/escala pixel a pixel de compressão e recuperação; descritores da dupla ativa durante contato; generalização para todas as cores, P2, velocidades e geometrias; rotação sobreposta e corredor na orientação 2; todas as formas de Power e linguagem completa dos scripts de sprites; equivalência visual integral de uma partida natural. As capturas existem para trabalhos posteriores, mas não foram transformadas em afirmações sem medição. Esses limites impedem anunciar fidelidade visual completa ou iniciar animações por estimativa.

## 9. Arquivos, preservação e Git

- `summary.json`, `execucao_primary.json`, `execucao_repeat.json`: contagens, hashes e origem.
- `rotation_tables_12D00_12DA0.csv`, `rotacao_por_quadro.csv`, `comparacao_animation_ram.csv`: tabelas e confrontos.
- `visual_trace_v10_3_1.csv`, `video_trace.csv`, `video_clock.csv`, `sprites_por_quadro_video.csv`, `cronologia.csv`, `injections.csv`: fixtures e cronologia reproduzíveis.
- `ghost_godot.csv`: demonstração do bug atual; script externo em `scripts/reproduzir_ghost_v10_3_1.gd`.
- 30 capturas selecionadas em `capturas/`; coleção completa de 1.099 PNGs em cada sessão local.
- Instrumentação e analisador em `scripts/medir_visual_v10_3_1.lua` e `scripts/analisar_visual_v10_3_1.py`.
- `MANIFESTO_SHA256.json`: integridade dos artefatos entregues.

O arquivo Gemini original e suas sessões permanecem intactos; cópia byte a byte adicional acompanha os entregáveis locais. ROMs, save states, RAM binária e disassembly não fazem parte dos novos arquivos destinados ao GitHub.

Lint do projeto: zero erros e 11 avisos preexistentes de caminhos de arte/relatórios. Não corrigidos por estarem fora do escopo. Diagnóstico Ghost executado sem erros do Godot. Não foram repetidas as 17 baterias ou as 1.000 partidas: código de implementação não mudou.

Estado final esperado e verificado na entrega: mesma branch e HEAD; nenhum arquivo rastreado modificado, nada staged; somente relatório novo e três scripts novos não rastreados. CSVs, PNGs e resumos adicionais permanecem ignorados pela política atual de `relatorios/` (não se fez `git add -f`). Sem commit, push, reset ou clean.
