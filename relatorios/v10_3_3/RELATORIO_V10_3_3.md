# V10.3.3 — Counter-Strike Puzzle Fighter '96

Concluída em **03/11/2026**, no escopo de rotação gráfica medido e descrito abaixo. Entrega para análise do usuário, sem commit, merge ou push e sem iniciar V10.3.4.

Projeto local: `C:\Projetos\CS-Puzzle-Fighter-96`. Branch `feature/v10-gem-physics`, HEAD `136238edf12b68761d72713b2225de9363e6ba94`.

## Resultado

A dupla ativa usa um componente visual independente para os oito passos de rotação, com os deslocamentos discretos das tabelas MAME já aferidas. O modelo continua responsável por movimento, colisões, contato, depósito, regras e identidade da dupla. A apresentação observa valores antes/depois do tick e aplica deslocamento somente ao desenho do satélite.

A retomada encontrou a integração pronta, o teste numérico aprovado e 340 registros de captura da cena real. Foram inspecionados o código, os logs, os PNGs e as fixtures antes de continuar. Não foi necessário mudar a implementação: o trabalho restante foi concluir a validação visual, repetir as regressões e documentar a entrega. Os testes preexistentes foram preservados.

## Validação final

| Verificação | Resultado |
|---|---|
| Rotação V10.3.3, reexecutada | 119.052 verificações, zero falhas |
| Passos principais | 80/80: quatro orientações × dois sentidos × oito passos, mais dois corredores × oito passos |
| Amostras ativas verificadas | 11.957 |
| Comparação PNG Godot × MAME | 80 pares; zero pixels divergentes de máscara |
| Oclusão entre os corpos | 36 quadros com sobreposição, 268 pixels; ordem e identidade de cor verificadas em cada renderizador |
| Capturas reais da V10.3.3 | 340 pares imagem/fundo, todos com máscara esperada; 26 capturas de fase sem dupla ativa |
| Teste temporal V10.3.2, reexecutado | 123.863 verificações, zero falhas |
| Suíte existente com renderização/UI | 17/17 baterias aprovadas |
| Física MAME, fixtures existentes | 112/112 cenários, 14.072/14.072 amostras |
| Cadeias e Counter Gems | 22/22 cenários, 5.066/5.066 amostras, 54 verificações |
| Partidas integradas | 4/4 partidas, 10 rounds, 204 verificações |
| Cena real V10.3.2, recapturada com a integração atual | 172 PNGs |
| Contato, ligação e halo | 20/20 comparações de máscara, zero pixels divergentes |
| Queda independente | 4/4 comparações, zero pixels divergentes |
| Preservação por SHA-256 | 782 arquivos anteriores sem alteração, incluindo núcleo, testes e evidências anteriores |
| Lint | Zero erros; os mesmos 11 avisos preexistentes de caminhos de arte/relatórios |

O arquivo `comparacao_rotacao_summary.json` e os CSVs contêm os resultados exatos. Os logs de execução ficam em `regression/` e `final_tests/`. A galeria `COMPARACAO_VISUAL.html` mostra as imagens originais, com recorte apenas por CSS.

## Oito passos e oclusão

O componente `godot/presentation/pair_rotation_visual.gd` mantém contador, direção e deslocamento gráfico separados do modelo. Os oito estados observados são os contadores 7, 6, 5, 4, 3, 2, 1 e 0; o último termina no alinhamento lógico. Inclui a trajetória curta de inversão no corredor. Não há interpolação senoidal inventada.

Os PNGs MAME preservados foram comparados na relação **Godot F ↔ PNG MAME F+1**. O traço RAM em `frame_done` acompanha CPU F+1, enquanto o bitmap tem seu próprio atraso. Esse alinhamento foi conferido nos estados anteriores ao giro e nos deslocamentos sucessivos; a física não foi deslocada para compensar a captura.

A comparação subtrai o fundo de cada renderizador, normaliza Godot 2× para pixels nativos e confere que os blocos 2×2 são uniformes. O halo nativo de cor `(255,187,187)` é excluído da máscara do corpo; seu comportamento é coberto separadamente pela regressão V10.3.2. Nos corredores, as colunas fixas são excluídas pela região da dupla.

Além da união das máscaras, os pixels de interseção são comparados com corpos de referência sem sobreposição **dentro do mesmo renderizador**. Isso verifica qual gema aparece por cima sem exigir que a arte CS tenha os mesmos RGB do arcade. Na inversão de corredor, o comparador acompanha a troca real das cores entre pivô e satélite. A primeira hipótese de cor fixa do comparador foi corrigida; as capturas e o código do jogo não precisaram de alteração.

## Contato, depósito e próxima dupla

Os testes mantêm a janela competitiva existente: contato 15..2 permite giro; 16/1 bloqueia nas condições medidas. Cobrem giros repetidos/simultâneos, paredes, geometrias irregulares, corredor e terceiro upkick, usando as fixtures existentes.

Ao deixar a fase ativa, o observador zera contador e deslocamento, e o desenho da dupla ativa é interrompido. Foram verificadas **304 amostras com contador nativo residual em fase inativa**. Nas capturas, o depósito deixa somente as células reais do tabuleiro; a imagem coincide com o fundo sem dupla ativa.

A identidade visual inclui índice da dupla, turno e instância do relógio. Mudança de identidade, descontinuidade de frame, reinício e transição de replay cancelam o estado anterior. Pausa e chamadas de desenho não avançam o contador; observação duplicada também não. O teste cobre **52 amostras nas quais a RAM do MAME retoma um contador antigo no nascimento da dupla seguinte**: por exigência desta versão, esse resíduo é descartado no Godot. Trata-se de uma diferença deliberada em relação à RAM residual, registrada explicitamente, sem copiar o defeito para a próxima dupla.

O teste gráfico anterior também exercitou a ponte real de `_physics_process`, pausa, reinício e dois jogadores com sentidos opostos; seu log e as capturas foram preservados e inspecionados. A validação final das 340 máscaras foi executada nesta retomada.

## Núcleo competitivo e arquivos

`match_model.gd` e todos os arquivos de `godot/core/` permanecem intactos. As verificações antes/depois de cada snapshot e passo visual comparam recursivamente o estado do modelo, incluindo tabuleiros, duplas, relógios e RNG. Não houve alteração de pontuação, ataques, turnos, entradas ou regras.

A implementação V10.3.3 existente acrescenta o componente de rotação e uma ponte mínima em `godot/presentation/main.gd`. A arena conserva exatamente os bytes da entrega V10.3.2. As alterações locais da arena relativas ao HEAD pertencem à V10.3.2 e foram preservadas.

Arquivos da V10.3.3:

- `godot/presentation/pair_rotation_visual.gd` e integração em `godot/presentation/main.gd`.
- `godot/data/pair_rotation_v10_3_3.json`.
- `godot/tests/rotation_fixture_v10_3_3.gd`, `test_pair_rotation_visual_v10_3_3.gd` e `render_pair_rotation_v10_3_3.gd`.
- `scripts/preparar_fixtures_rotacao_v10_3_3.py`.
- Validadores finais de PNG/máscaras e relatórios desta entrega.

Nada foi colocado no índice. Relatórios históricos escritos em caminhos fixos por testes antigos foram preservados/restaurados pelo executor existente, e a conferência final dos 782 hashes não encontrou divergências.

## Limites da conclusão

A conclusão vale para as trajetórias, cenários e contratos acima. Máscaras iguais não significam RGB, textura, fundo ou partida natural inteira iguais ao arcade. A arte CS permanece distinta. Power e explosões mantêm as limitações de arte interna/cronologia detalhada documentadas na V10.3.2. Não se certificam todos os casos de P2, demais cores e configurações de ligação ou todas as combinações possíveis de inputs.

Não foram repetidas coletas MAME comprovadas, nem as 1.000 partidas históricas. Não houve nova instalação, execução do MAME ou exportação de ROM, RAM ou save state. Os 11 avisos de lint são anteriores e foram mantidos visíveis, sem declarar zero avisos.

## Reprodução

Os scripts completos acompanham `scripts/`. Para o teste numérico, definir `PF_REPORT` como diretório novo e executar o Godot 4.7.2 local com `--headless --path <projeto>/godot --script res://tests/test_pair_rotation_visual_v10_3_3.gd`.

Para os PNGs: `python scripts/comparar_rotacao_v10_3_3.py <projeto> <diretorio_novo>`; requer as fontes locais preservadas indicadas no código. O validador de 340 máscaras usa `PF_CAPTURE_SOURCE=<projeto>/relatorios/v10_3_3/render` e `PF_REPORT=<diretorio_novo>`, executando `validar_capturas_rotacao_v10_3_3.gd` com o mesmo Godot.

O manifesto da entrega relaciona hashes dos arquivos entregues; o manifesto das capturas relaciona também todos os originais preservados no projeto. **Próxima ação: análise do usuário. V10.3.4 não iniciada.**
