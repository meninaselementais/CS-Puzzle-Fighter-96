# CS Puzzle Fighter ’96 — Animações V8

Data: 30/10/2026. Projeto atualizado diretamente em `C:\Projetos\CS-Puzzle-Fighter-96`.

A V8 continua a apresentação e o Animation Showcase existentes. Não houve restauração de versão anterior, recriação do projeto, commit ou substituição dos personagens por figuras genéricas. As regras, fixtures, PNGs originais, configuração Godot e launchers foram mantidos.

## O que mudou

### Disparos

- Sequências divididas em antecipação, disparo, intervalo e recuperação, usando os sprites existentes.
- Recuo curto do conjunto corpo/arma: impulso de 3 a 5 pixels com retorno amortecido. O SAS mantém suas diferentes poses de tiro; o Phoenix utiliza a pose de tiro disponível entre poses de preparação/recuperação.
- Os clarões incorporados aos sprites eram uma causa de persistência: alternar apenas o efeito externo não removia o clarão desenhado na imagem. A apresentação agora omite exclusivamente a região do clarão no momento de desenhar o sprite e compõe o muzzle flash separado. Nenhum PNG foi sobrescrito.
- Muzzle flash de dois ticks, no máximo um por personagem, preso ao ponto do cano no sprite corrente. Os pontos de saída foram revisados visualmente em cada textura.
- Cápsulas saem pelo ponto de ejeção do personagem, giram, quicam e expiram. Tiros, cápsulas e clarões são gerados pelos keyframes, sem disparos adicionais fora da pose.

### Granadas

- Preparação com pose de granada, liberação e recuperação. A antecipação passou a 10 ticks antes do arremesso.
- Corrigido o deslocamento de 34 pixels acima da mão. O primeiro quadro do projétil tem a posição exata do ponto de mão da pose renderizada, com `t = 0`; ele só avança no tick seguinte.
- Arco parabólico de 26 ticks, elevação de 72 pixels e rotação durante o voo. A mesma função de trajetória serve ao desenho e aos testes.
- Explosão de seis imagens já existentes, onda de choque e fragmentos com gravidade e dissipação; o ataque 5× recebe o acento de relâmpago e impacto maior.
- Removidas explosões de combate que apareciam no centro da arena antes de a granada chegar. A explosão do tabuleiro/C4 continua ligada à limpeza; a explosão da granada acompanha seu próprio impacto.

### Combos, expressividade e leitura

- 1× dispara uma vez; 2× usa dois disparos; 3× usa três. 4×/5× mantêm a granada, com intensidade crescente. O Showcase de disparo isolado apresenta a rajada completa.
- Tremores pequenos com amplitude máxima de 2,5 pixels no 5× e 3 pixels na C4, com envelope de dissipação. O impacto da granada forte usa um acento adicional curto.
- Banners de cadeia deslocados para baixo dos poços e ajustados à largura disponível. Títulos e subtítulos centrais também ajustam o tamanho para evitar invasão entre jogadores.
- Preservada a relação de aspecto de cada sprite. As poses deixam de sofrer a compressão desigual anterior.
- Dano utiliza impulso, flash curto e recuperação; vitória/derrota sustentam a pose final. Uma vitória limpa a reação de dano que ainda estivesse pendente.
- Corrigido o tópico de vitória/derrota com “Ambos”: antes, o laço atribuía dois vencedores sucessivamente. Agora SAS vence nesse modo; selecionar Phoenix demonstra a vitória dele.

### Sincronização com a onda visual

A preparação do lutador começa durante a antecipação das gemas. O primeiro disparo/arremesso ocorre no mesmo tick em que a onda passa de `pre` para `burst`. O anúncio no impacto preserva o relógio da ação preparada, em vez de reiniciá-la. Isso é validado para cinco ondas e C4 nos dois jogadores simultaneamente.

Reações recebidas durante uma ação continuam pendentes para a recuperação, mantendo os dois ataques visíveis. Nenhuma mudança é aplicada à pontuação, envio/cancelamento de ataques, queda lógica ou condições de vitória dos tabuleiros.

## Animation Showcase

As 14 demonstrações anteriores continuam disponíveis, com seleção SAS/Phoenix/Ambos, F4, pausa e avanço de um quadro. Foram adicionados:

- velocidades ¼×, ½×, 1× e 2×;
- quadro atual do tópico, estado em execução e índice/quantidade de keyframes de cada personagem;
- Loop para repetir continuamente a sequência;
- Catálogo para avançar entre os tópicos, independente do Loop.

Pausa congela a animação. O botão “+1 quadro” e N avançam exatamente um tick, independentemente da velocidade. F4 troca de cena e inicia uma nova partida ao voltar ao jogo, como na V7.

## Validação executada

A bateria anterior foi executada antes das alterações. Depois da implementação, `scripts/validar_apresentacao.py --render` executou 13 grupos, todos aprovados. Logs e comandos estão em `final/summary.json`.

| Verificação | Resultado |
|---|---:|
| Python unittest | 17/17 |
| Modelos/geometria | aprovado |
| Regras | 34/34 |
| Fixtures de fidelidade derivadas do MAME | 247/247 |
| Controles | 33/33; 866 amostras de RNG; 10 fontes inválidas continuam excluídas |
| Endpoints de partidas naturais | 119/119 |
| Simulação de duelos | 1.500 turnos, 26 partidas, 239 ondas, 908 ataques brutos |
| Regressões de apresentação anteriores | 3.283 verificações, nenhuma falha |
| Regressões específicas V8 | 145 verificações, nenhuma falha |
| Renderização/interface | preview, mecânicas, interface/F4 e demonstração anterior aprovados |
| Inicialização pela cena padrão | saída 0, sem erros de script; execução limitada a 120 quadros |
| Captura do Showcase | 14 tópicos, 950 imagens, sem erro de script |

As verificações V8 incluem:

- quantidade de tiros por nível, ator correto e keyframe de emissão;
- posição inicial de tiro/granada igual ao ponto renderizado;
- no máximo um muzzle flash por jogador e expiração dos efeitos;
- recuperação do recuo e manutenção da relação de aspecto;
- antecipação da granada, ápice e ponto final do arco;
- trajetória na arena central, sem atravessar poços, logo ou placares;
- fragmentos após o impacto e limpeza completa dos efeitos;
- disparos e granadas simultâneos, 2×/3×/5×;
- alinhamento do primeiro ataque à fronteira de destruição de cada onda;
- término de dano, sustentação de vitória/derrota e descarte de dano pendente;
- todas as 14 cenas com SAS, Phoenix e Ambos (42 combinações);
- quatro velocidades, pausa, passo único, Loop e Catálogo.

As 3.283 verificações anteriores incluem asserções repetidas de invariância do modelo por quadro; não representam 3.283 regras diferentes. A asserção antiga de saída da granada foi adaptada para ler a duração da nova antecipação dos keyframes. As comparações mecânicas e seus valores esperados não foram alterados.

Os testes visuais agora permitem direcionar a saída para a pasta V8 pelo runner, preservando as capturas antigas. A referência visual CPS-2 utilizada continua sendo a sessão isolada MAME `laboratorio/auto_20261030_180156_204005`, registrada no relatório V7. Não foi executada uma nova partida MAME completa nesta etapa de apresentação.

## Preservação e arquivos

Backup: `revisoes/antes_animacoes_v8_20261030_202814`.

`preservacao.json` confirma por SHA-256 os 114 arquivos de núcleo, dados, arte e pacote Original listados antes das alterações. Também confere as sete fontes do ensaio MAME anterior. Nenhuma instalação Steam/MAME ou ROM foi escrita por esta implementação.

Arquivos principais alterados:

- `godot/presentation/cs_arena.gd`: sequências, recuo, clarões, trajetória, impactos, composição e sincronização das ondas.
- `godot/presentation/animation_showcase.gd`: velocidade, Loop, identificação dos quadros e correção da demonstração de vitória.
- `godot/tests/test_animation_v8.gd`: novo teste específico.
- `godot/tests/test_presentation.gd`: antecipação derivada dos keyframes.
- `godot/tests/render_animation_showcase.gd`: saída separada e capturas adicionais.
- `godot/tests/test_showcase_ui.gd`, `render_mechanics.gd`, `render_preview.gd`: redirecionamento opcional dos artefatos de teste.
- `scripts/validar_apresentacao.py`: inclusão da bateria V8 e saída padrão separada.
- `README_ANIMACOES_V8.md`: acesso e reprodução dos testes.

A relação completa está em `arquivos.json`; os diffs estão ao lado deste relatório.

## Demonstração e limites

`animacoes_v8.mp4` contém a captura real do renderer: 1000×700, 950 quadros a 29,818702 fps, aproximadamente 31,86 segundos. Cada imagem representa dois ticks de 59,63740458 Hz. `demo_final/timeline.json` identifica os trechos e `contato_v8.png` permite examinar todas as sequências. O GIF de preview mostra o combo 5×.

A V8 melhora o uso da arte disponível; não acrescenta desenhos intermediários inéditos. Phoenix ainda possui uma pose principal de disparo e poucas poses de arremesso/dano/vitória. Recuo e recuperação complementam esses desenhos, mas não substituem uma futura expansão de sprites dedicada.

A sincronização comprovada aqui é da apresentação do protótipo. O motor mantém a resolução lógica imediata e os limites de cronologia/geração de peças já documentados. Os 119 endpoints não são prova de partidas completas autônomas Godot/MAME sincronizadas quadro a quadro. A tela e os efeitos continuam uma interpretação CS inspirada no CPS-2, sem equivalência pixel a pixel ou garantia de qualidade comercial.
