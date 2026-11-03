# V10.3.2 — apresentação temporal das gemas

Implementação autorizada em 02/11/2026. Branch `feature/v10-gem-physics`, base `136238edf12b68761d72713b2225de9363e6ba94`.

**Entrega para análise do usuário:** queda e células desenhadas acompanham a simulação; contato e depósito não recebem offsets/squash artificiais; ligação vertical azul e halo reproduzem os contornos medidos; união Power tem o estágio intermediário observado; as ondas deixam de antecipar a gravidade e não reexibem gemas depois de removidas. As regressões passaram. As limitações gráficas remanescentes estão explicitadas abaixo; não se declara equivalência visual integral com o arcade.

## 1. Arquivos e isolamento competitivo

Arquivo de implementação existente modificado:

- `godot/presentation/cs_arena.gd`.

Novos arquivos:

- `godot/tests/test_visual_timeline_v10_3_2.gd`: teste temporal, contornos, janelas, invariantes e ondas reais.
- `godot/tests/render_visual_timeline_v10_3_2.gd`: capturas da `main.tscn` original, com condições sintéticas controladas.
- `scripts/comparar_contornos_v10_3_2.py`: comparação geométrica dos PNGs MAME/Godot, sem dependências externas.
- `relatorios/v10_3_2/`: este relatório e evidências. `CONTINUIDADE_PROJETO.md` atualizado, com backup da versão anterior.

**Intactos:** `match_model.gd`, `main.gd`, todos os arquivos de `godot/core/` e todos os testes preexistentes. Nenhuma alteração de RNG, inputs, turnos, pontuação, ataques, regras, seleção ou rounds. Não houve instalação, commit, merge, push ou avanço à V10.3.3.

Além da conferência Git dos arquivos protegidos, o teste novo captura recursivamente todas as propriedades de script do modelo, tabuleiros, duplas e relógios, incluindo estado do RNG dedicado, antes/depois de cada atualização da arena. As comparações confirmam que a apresentação não escreve no modelo. A previsão de uma onda usa um tabuleiro copiado; não calcula a gravidade futura nem resolve a cadeia inteira da partida.

## 2. Evidências reutilizadas — nenhuma coleta MAME nova

Foram relidos o histórico da branch, os relatórios V10/V10.2 e as duas entregas V10.3.1. Reutilizados:

- Física: 112 casos/14.072 amostras; inclui 12 separações de dupla horizontal com apoio sob pivô/satélite e profundidades 1/3/6.
- Cadeias/Counter Gems: 22 casos/5.066 amostras.
- Matriz visual: `auto_20261101_222825_850720` e repetição, com 2×2, 2×3, união 5×2 e explosões.
- Suplemento: `auto_20261102_172410_209057` e repetição, com corpos, halo e contornos de ligação.
- Queda de três linhas: PNGs `split_r1_pivot_depth3_f058..061` de `auto_20261101_001520_164035`.

As 18 coletas anteriores e o suplemento não foram reexecutados. O MAME não foi iniciado nesta implementação. Os testes Godot e as comparações de fontes existentes foram repetidos como regressão necessária.

## 3. Alterações implementadas

### Queda independente e depósito

Na partida temporal, `get_visual_cells()` acompanha o tabuleiro atual, sem adotar células de uma onda futura. `get_cell_visual_offset()` devolve zero e `get_cell_squash_scale()` devolve escala unitária. A gema livre segue cada linha real da simulação, enquanto a gema apoiada permanece onde foi depositada.

Isso retira desse caminho os antigos 22 pixels de deslocamento inicial, descida visual adicional de 14 pixels/tick e squash senoidal. A dupla ativa já usa Y/offset da simulação em `main.gd`; esse contrato foi preservado, sem alterar o arquivo. O corpo normal desenhado pela arena ignora escalas decorativas recebidas, inclusive o alongamento antigo durante Down, mantendo o contorno nativo medido.

O caminho independente do showcase continua disponível para demonstrações explícitas de cadeias pré-calculadas, sem ser usado para reconstruir a cronologia de uma partida em execução. Os testes antigos desse showcase foram mantidos e passaram.

### Contornos e contato de mesma cor

A arena gera e guarda em cache texturas de contorno com a arte CS existente, aplicando máscaras discretas. Nenhum sprite de ROM foi incluído.

- Corpo normal: 14×14 pixels nativos, 184 pixels opacos; em escala 2×, 28×28.
- Ligação vertical azul intermediária: 14×16/212 pixels por célula.
- Ligação final: 16×16/244 pixels por célula.
- Transição após depósito: quatro ticks no contorno inicial, quatro no intermediário, depois o contorno final, conforme as trocas 0x5A00 → 0x5A4E → 0x5A08 observadas.

A ligação foi deliberadamente limitada ao **par vertical azul isolado** e apoiado. Não se aplica essa máscara a trios, Ls, ligações horizontais ou cores não medidas. O teste inclui um trio para impedir essa extrapolação.

O halo de 60 pixels é separado do corpo, com máscara 16×16 e cor observada `(255,187,187)`. Sua emissão está limitada à configuração P1 vertical azul/verde aferida, usando a paridade de idade registrada nas fixtures. O halo termina quando a dupla deixa a fase ativa. Os bytes residuais dos descritores ativos não geram uma segunda dupla após o depósito.

Não foi introduzida uma curva de compressão elástica: as mudanças de contorno são discretas e documentadas como troca de arte/conexão.

### Power Gems

A formação 2×2 e o crescimento 2×3 aparecem quando o retângulo existe na simulação, sem flash genérico de 14 ticks nem escalonamento sinusoidal do cristal.

Na união medida de duas 2×2 separadas por uma coluna, o tabuleiro lógico pode já apresentar o retângulo 5×2. Somente a representação visual mantém **3×2 + 2×2 por dez ticks**, passando depois a 5×2, como nos descritores observados. O tabuleiro, os códigos das gemas e os retângulos competitivos não são alterados. A transição é cancelada se o retângulo correspondente deixa de existir, evitando geometria visual obsoleta.

O efeito foi limitado à configuração estrutural medida. Não se inventou interpolação contínua de tamanho. A animação interna dos tiles de Power, com mudanças de arte em blocos de oito quadros, **não foi reproduzida**: a versão CS mantém sua textura de cristal. Implementar brilho arbitrário para substituí-la seria afirmar uma equivalência que as imagens não sustentam.

### Ondas e Ghost Gem Flicker

A partida temporal prepara somente a onda corrente e observa `clear_timer`, `chain_count` e o resultado real. As partículas/reações de impacto são emitidas uma vez, quando essa onda é removida logicamente; a queda intermediária usa as posições reais dos quadros seguintes.

A fila independente 10+14+8 do antigo replay visual não pode terminar cedo e devolver um tabuleiro lógico ainda cheio. Não há transição de “gema ausente → gema reaparece → gema some novamente” em F56..65. A arena não antecipa a gravidade nem a próxima onda.

**Diferença deliberadamente conservadora:** os sprites nativos de explosão começam durante o flood-fill e certas células deixam de exibir o corpo antes da remoção lógica. A apresentação CS atual mantém a célula básica até a remoção real, em vez de copiar um desaparecimento antecipado universal sem ter decodificado a sequência individual de cada sprite. O Ghost foi corrigido, mas a cronologia detalhada dos tiles nativos de explosão permanece diferente.

## 4. Janela final de rotação

A lógica não foi reescrita: giro continua permitido nos contadores 15..2 e bloqueado em 16/1 nas condições ensaiadas. O teste específico cobre as duas direções nessas fronteiras, e a regressão dos 112 casos confirma a trajetória física existente, inclusive perda de apoio e kicks.

**Limite do plano aprovado:** a trajetória gráfica completa de oito passos não foi integrada ao desenho da dupla. `main.gd` ainda escolhe as posições finais diretamente e permanece intacta. Nesta entrega, preserva-se a janela original e a apresentação não prolonga o contato nem afeta a próxima dupla. Não se declara que o giro gráfico intermediário já equivale ao MAME.

## 5. Comparações visuais verificáveis

Foram produzidas **172 capturas** pela cena real `main.tscn`, sem editar sua implementação, com stream de teste preparado antes das observações e física manual por quadro. Os casos são: fundo, pouso isolado, contato azul, separação, formação Power, crescimento, união e explosão simples.

### Contato e contornos: 20/20 pares

`comparacao_contornos_mame.csv` compara vinte pares de capturas: aproximação, primeiro contato, halo, contador 1, depósito e estágios intermediário/final da ligação.

- Subtração do controle de fundo nos dois renderizadores.
- Normalização exata da escala Godot 2×; todos os blocos 2×2 comparados são uniformes quanto à ocupação.
- Conversão de coordenadas do poço, preservando posições e contornos completos.
- **Zero pixels de diferença de máscara em todos os vinte pares.**

O alinhamento aferido é Godot tick F ↔ PNG MAME F+1 nesses casos, levando em conta CPU, RAM de vídeo e bitmap do coletor. Não é igualdade das cores, arte interna, iluminação ou imagem inteira.

### Queda independente: 4/4 pares

`comparacao_queda_mame.csv` compara o depósito e as três posições sucessivas da gema sem apoio:

| Godot | PNG MAME | Corpo da gema livre, em coordenadas nativas |
|---:|---:|---|
| F2 | F58 | `(65,145)..(78,158)` |
| F3 | F59 | `(65,161)..(78,174)` |
| F4 | F60 | `(65,177)..(78,190)` |
| F5 | F61 | `(65,193)..(78,206)` |

Cada descida é de 16 pixels nativos/uma linha. **Zero diferenças de máscara nos quatro pares.** Antes de reutilizar o controle de fundo nessa fonte histórica, confirmou-se igualdade de todos os pixels fora das colunas ocupadas. Os 12 cenários de separação também foram verificados no teste temporal novo, com diferentes orientações, apoios e profundidades.

### Power e Ghost

As capturas mostram 3×2+2×2 e depois 5×2 na união. São comparações de geometria/tempo, não de textura nativa. O arquivo `comparacao_ghost_antes_depois.csv` confronta o diagnóstico anterior com o novo traço; o teste também acompanha três ondas reais e a queda entre elas.

`COMPARACAO_VISUAL.html` reúne referências MAME e Godot com o poço recortado apenas por CSS, sem editar os PNGs originais.

## 6. Testes executados

| Verificação | Resultado |
|---|---|
| Suíte existente `validar_apresentacao.py --render` | **17/17 baterias PASS**, incluindo Python, modelos, regras, fidelidade, controles/RNG, naturais, duelo, apresentação, arte/animação, seleção/coin flip e renderização/UI |
| `test_gem_timeline.gd` | **112/112 casos, 14.072/14.072 amostras** |
| `test_chain_counter_timeline.gd` | **22/22 casos, 5.066/5.066 amostras, 54 verificações** |
| `test_visual_timeline_v10_3_2.gd` | **123.863 verificações, zero falhas**; inclui invariantes de todo o modelo, 12 separações, fronteiras de giro, contornos, Power, Ghost e três ondas |
| `validar_fluxo_partidas.py --matches 4 --workers 1` | **4/4 partidas, 10 rounds, 204 verificações** |
| Cena real, `render_visual_timeline_v10_3_2.gd` | **172 capturas** |
| Máscaras de contato/ligação/halo | **20/20 pares, zero pixels divergentes** |
| Máscaras da queda independente | **4/4 pares, zero pixels divergentes** |
| Lint antes/depois | **Zero erros; os mesmos 11 avisos preexistentes de caminhos de arte/relatórios** |

As 1.000 partidas históricas não foram repetidas: não houve mudança competitiva. As quatro partidas integradas e os testes de duelo/RNG foram a regressão pertinente desta alteração visual. Os testes antigos não foram ajustados para passar. As evidências são gravadas separadamente; resultados antigos de caminhos fixos foram preservados/restaurados pelo executor de regressão.

O diagnóstico antigo `scripts/reproduzir_ghost_v10_3_1.gd` foi preservado como evidência histórica: sua asserção exige reproduzir o defeito. Ele não certifica a correção nem foi adulterado; o novo teste verifica ausência de reaparição.

## 7. Critérios e limitações

| Critério aprovado | Situação |
|---|---|
| Queda independente consistente com simulação | Implementada, validada por estados e quatro comparações de PNG |
| Contato/depósito sem duplicação ou sumiço indevido | Validado no escopo medido, incluindo transição entre contador 1 e depósito |
| Rotação final preservando janela lógica | Preservada; trajetória gráfica intermediária continua sendo limitação explícita |
| Formação/crescimento/união Power corretos | Geometria e estágio 3×2+2×2→5×2 implementados; textura/tiles internos ainda diferem |
| Ghost sincronizado ao estado lógico | Corrigido; ondas e gravidade não usam mais o relógio independente da partida |
| Regressões | Aprovadas |
| Núcleo competitivo preservado | Conferido por Git e invariantes de execução |

Não comprovados/generalizados: P2 em todas as configurações visuais; outras geometrias/cores de ligação; giros sobrepostos; trajetórias gráficas completas de giro; todos os scripts de explosão e Power; fidelidade visual integral de uma partida natural. Elementos artísticos e efeitos de combate são da versão CS, não reprodução dos sprites originais.

## 8. Reprodução e entrega

Executar com os binários locais já existentes, sem instalar dependências. O diretório de saída deve ser absoluto e separado das evidências preservadas.

```powershell
$pfRoot = 'C:\Projetos\CS-Puzzle-Fighter-96'
$env:PF_REPORT = 'C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\work\v10_3_2_revalidacao'
& "$pfRoot\ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "$pfRoot\godot" --script res://tests/test_visual_timeline_v10_3_2.gd
& "$pfRoot\ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path "$pfRoot\godot" --script res://tests/render_visual_timeline_v10_3_2.gd
python "$pfRoot\scripts\comparar_contornos_v10_3_2.py" $pfRoot $env:PF_REPORT
```

O comparador requer também as fontes MAME locais citadas; elas não fazem parte de um clone Git limpo e não devem ser incluídas como ROM/dumps. As capturas selecionadas e as tabelas derivadas acompanham esta entrega.

Os relatórios V10.3.1 e seu suplemento permanecem intactos. A continuidade anterior foi copiada antes da atualização; os manifestos históricos que incluem a continuidade referem-se à sua versão anterior, disponível no backup. O Git continua no mesmo HEAD, sem staging, commit, merge ou push.

**Próxima ação: análise do usuário sobre esta entrega e suas limitações. Não há autorização para avançar automaticamente à V10.3.3.**
