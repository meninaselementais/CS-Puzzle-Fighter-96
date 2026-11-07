# V11.0 — diagnóstico e plano do HUD

Data: 05/11/2026, America/Sao_Paulo. **Planejamento apenas; nenhuma implementação autorizada nesta etapa.**

Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`. Base estável publicada: `v0.10.0`, commit `1a943a4db4d1dba84a222735187afb6108b4c4c5`. Inspeção iniciou na `main`, com índice vazio, nenhum rastreado modificado e dois relatórios V10.3.4 não rastreados preservados. As referências Git não foram alteradas. README, arquitetura e continuidade conservam declarações de publicação pendente como snapshots anteriores; a tag publicada e o commit acima são a base efetiva desta proposta. Não se reescreve aqui a documentação histórica V10.

Branch sugerida para a futura implementação: **`feature/v11-hud`**, a partir de `v0.10.0`; não criada. Os dois documentos desta etapa ficam locais, sem staging/commit/push. A única alteração rastreada autorizada é a nota de início na continuidade; código e conteúdo publicado da tag permanecem intactos.

## 1. Diagnóstico dos componentes existentes

Os números abaixo são leituras do código V10, não medidas do arcade. Referências de linha são do commit-base.

| Componente | Responsável atual | Estado e implicação |
|---|---|---|
| Grade e posição das gemas | `godot/core/board_model.gd`; `presentation/main.gd:20–21`, `gem()` e `_draw()` | Grade lógica 6×14, duas linhas ocultas; 6×12 visíveis. Passo visual 32 px; poços em (64,108) e (744,108), 192×384. Viewport 1000×700, `canvas_items`. Não aumentar coordenadas lógicas. |
| Corpo, contorno, Power e efeitos | `presentation/cs_arena.gd`: `draw_gem_sprite()` (1439), `draw_power_gem_crystal()` (1571), `draw_combo_flashes()` (1524), `draw_foreground_vfx()` (1789), `sync_temporal_board()` (1056) | Há caminhos distintos para gema normal temporal e sprite genérico. O genérico desenha nominalmente 31 px; contornos temporais usam textura 32×32 com máscara interna medida. Alterar só um deles gera tamanhos inconsistentes. |
| Dupla ativa e giro orbital | `presentation/pair_rotation_visual.gd`: `points()`, `draw_pair()`; ponte antes/depois do tick em `main.gd` | O desenho usa passo 32 e deslocamentos nativos /16. Preservar pontos, clipping lógico, oito passos e relógios. |
| NEXT | `main.gd:get_next_colors()` e `_draw()`; `cs_arena.gd:draw_central_arena_and_hud()` (1685) | Caixa 64×114 em (284,56)/(652,56). Centros das gemas em y+32/y+76: distância 44 px. Satélite `[1]` acima do pivô `[0]`. A lista `next_pairs` já é parâmetro da arena, embora a dupla seja desenhada em main. |
| Efeito colateral do NEXT | `main.gd:get_next_colors()` | Pode ampliar `model.stream` consumindo `model.rng`. Não é uma consulta pura. O HUD novo não pode chamá-la outra vez, gerar peças, mudar frequência de chamadas ou produzir números com RNG. É uma dívida preexistente, não autorização para corrigir o gerador na V11. |
| Ataque pendente / aviso atual | `main.gd:_draw()` passa `model.pending[i]` para `draw_board_well_frame()` (1385), que chama `draw_warning_gems()` (1419) | Mostra ícones por seis/unidade e texto `xN`, sem teto visual de 99. O nome da função não significa que já exista um letreiro WARNING: não há esse texto no HUD de duelo inspecionado. |
| Perigo atual | `cs_arena.gd:is_board_in_danger()` (956) | Retorna verdadeiro se `pending >= 6` ou qualquer célula dos índices 12..35 estiver ocupada (quatro primeiras linhas visíveis). Hoje orienta animação `danger` do personagem. Reutilizar esse significado inicialmente; não confundir com a regra de top-out. |
| Ataque por combo / cadeia | `core/resolution.gd`, `core/gem_motion.gd:157–162`, `core/match_model.gd:cancel_attack()`; apresentação em `cs_arena.gd:step_from_model()` | Ondas têm `chain`, `combo`, `score`, `attack`; `last_results` agrega ondas e ataque bruto. Após cancelamento, o caminho temporal limita pendências do adversário a 250. Pendência recebida, ataque gerado, enviado e entregue são fatos diferentes. |
| Pontuação e rodapé | `cs_arena.gd:draw_central_arena_and_hud()` e `main.gd:_draw()` | `model.scores`, formato mínimo de sete dígitos; placas 176×56 em (280,520)/(544,520); VS central. Rodapé da série usa `Session`. Não mudar contabilização para caber no desenho. |
| Vitórias correntes | `core/match_session.gd:record_round()` e `main.gd:sync_round_result()`; `arena.wins`, ícones V | São vitórias de rounds na MD3, reiniciadas em nova partida. Não existe histórico de partidas por jogador nem estatística persistente. Não reutilizar esses V como se fossem carreira. |
| Personagem e identificação | `core/character_catalog.gd`, `core/selection_state.gd`, `presentation/player_select.gd:player_panel()`, `arena.configure_characters()` | Seleção define agente, equipe, padrão de ataque e arte. No duelo, o nome do agente fica abaixo de NEXT. Não há fonte de nickname/patente. O catálogo declara que contas, patentes e XP pertencem a outro sistema. |

`cs_arena.gd` concentra muitos desenhos, animações e observações do modelo; não refatorar o arquivo inteiro como pré-requisito. Trabalhar nas funções afetadas, com pontos de integração pequenos e verificáveis.

## 2. Referência CPS-2 e grau da evidência

Foram inspecionados os documentos de medição V10 e capturas locais já existentes, sem executar MAME, gerar capturas novas ou importar conteúdo de ROM:

1. `laboratorio/auto_20261101_001520_164035/snap/speed_0_down_0_f041.png` — composição de duelo, NEXT, nomes, placas SCORE/VS/V.
2. `laboratorio/auto_20261101_222825_850720/snap/rotation_r0_b1_f004.png` — composição em cenário de giro, preservada na comparação orbital.
3. `laboratorio/auto_20261028_232043_038647/snap/attack_red12_f0180.png` — **DANGER** à esquerda do topo de P2 e número **33** em caixa à direita.
4. `laboratorio/auto_20261028_232043_038647/snap/attack_p2_red12_f0180.png` — o mesmo arranjo local esquerdo/direito em P1. A origem dos cenários está em `godot/data/chain_counter_timeline_fixtures.json`.

Esses PNGs têm 384×224 pixels, conferidos pelo cabeçalho. O manifesto desta inspeção, com SHA-256, fica na entrega externa `fontes_mame.json`. Não copiar ROMs/dumps/sprites nativos para o planejamento ou para o jogo.

**Composição observada:** poços nas laterais, NEXT compacto nas bordas do miolo central, logo e personagens no centro, identificação abaixo do NEXT, SCORE/VS/V na faixa inferior central. O alerta e o contador ocupam lados opostos do topo de cada poço; ambos os lados foram observados nas capturas indicadas. O texto nativo visto é DANGER; WARNING é a adaptação solicitada para o tema CS.

**Geometria já utilizada nos comparadores:** `scripts/comparar_rotacao_v10_3_3.py` e `comparar_contornos_v10_3_2.py` usam coordenadas nativas P1 x=16..111/y=16..207, passo 16, e transformação `Godot x=64+2*(MAME x-16)`, `Godot y=108+2*(MAME y-16)`. Isso fundamenta a região comparada, não certifica todas as bordas do HUD ou dimensões de fonte. Grade 6×12 visível → 96×192 na referência, 192×384 no Godot atual. Não converter essa escala local em alegação de escala uniforme da tela inteira.

**Ainda não certificado:** bounding boxes exatas de NEXT, fontes e placas nativas; todas as cores/faixas do contador; regra nativa do DANGER; saturação em 99; durações de piscada; significado exato de cada contador por frame; indicador de pedras enviadas. Uma captura com 33 não prova teto 99 nem faixas cromáticas. As medições V10 certificaram sobretudo gemas/movimento/Power, não um inventário completo do HUD.

Antes de reivindicar fidelidade de HUD, criar uma ficha de medição por componente: imagem/hash, cenário/frame, caixa em pixels, escala de exibição, estado observado e confiança. Usar os dados já coletados; se faltarem casos para 98/99/100 ou perigo sem ataque, registrar lacuna. Coleta nova no MAME só em etapa separadamente autorizada. Inspeção visual não equivale a prova de regra nativa.

## 3. Proposta funcional A–J

Tudo que se segue é **proposta de produto V11**, sujeita a aprovação visual; dimensões, limiares e durações não são medidas certificadas do MAME.

| Item | Proposta e fonte do dado | Limite de escopo |
|---|---|---|
| A — gemas maiores | Aumentar a projeção visual do poço inteiro, preservando as células e contornos canônicos. Comparar mockups com passo aparente 34 e 36 px (6,25% / 12,5% maiores que 32). | Escolher uma opção na primeira etapa visual; não trocar constantes físicas, deformar máscaras, alterar giro ou esconder linhas. |
| B — NEXT menor e próximo | Protótipo de caixa 48×76 e centros separados por 32 px, em vez de 64×114 e 44 px; desenhar a dupla com escala própria, independente do poço ampliado. Manter satélite acima do pivô e não misturar P1/P2. | Confirmar margens/fonte no mockup. Usar a mesma dupla já disponibilizada pelo caminho V10; nada de geração adicional. |
| C — WARNING | Letreiro no topo esquerdo local de cada poço, em faixa externa à área das células e à entrada. Primeiro contrato: observar `is_board_in_danger()` existente; ocultar quando não houver perigo e em tela final. | Não mudar critério de perigo, derrota ou timers V10. Texto WARNING é decisão CS. Piscada, se aprovada, apenas em relógio visual, congelada na pausa. |
| D — contador oposto | Topo direito local de cada poço, duas casas 00..99; `display=min(max(pending,0),99)`. Pendência própria, portanto recebida pelo jogador daquele poço. 99 significa 99 ou mais, sem truncar o valor de jogo. | Testar 0/1/98/99/100/250. Nunca escrever 99 no modelo. Não confundir esse número com ataque que o jogador produziu. |
| E — cor por intensidade | Proposta inicial: 00 cinza; 01..05 ciano; 06..17 amarelo; 18+ vermelho. A cor usa a pendência real, antes da saturação. Número e contorno garantem leitura sem depender só de cor. | Faixas são escolhas de legibilidade, não regras CPS-2. Confirmar contraste nos três cenários e sem confundir cor de equipe com perigo. |
| F — pedras enviadas | Mostrar `ENVIADAS N`, próximo ao poço de origem, associado a uma resolução/onda identificada; agregar ondas novas da mesma cadeia sem repetir em redraw. Separar `GERADAS` de `ENVIADAS` se ambas forem expostas. | Exige fonte exata do ataque efetivamente acrescentado à fila adversária, depois de cancelamento e teto. Não deduzir por pontuação ou diferença líquida de pending. Ver seção 5. |
| G — nickname | No duelo, substituir apenas o rótulo sob NEXT por nickname. Fallback `JOGADOR 1`/`JOGADOR 2`; largura disponível determina reticências. Na seleção, nickname identifica o jogador e nome do agente continua no cartão. | Agente/ID/equipe/padrão de ataque permanecem intactos. UTF-8, espaços e nomes longos precisam de teste; desenhar como texto literal. Não criar login/rede. |
| H — patente | Abaixo do nickname, apresentar patente fornecida pelo perfil, sem derivá-la de personagem, placar ou vitórias da MD3. | MVP recebe ID/dados locais de apresentação; tabela/arte de patentes precisa de aprovação. Sem XP, matchmaking ou progressão inventada. |
| I — sem patente | Patente ausente, desconhecida ou inválida → emblema cinza com `?` e descrição `SEM PATENTE`. Mesma reserva de espaço do emblema normal. | Fallback deliberado, sem falsa patente padrão. Sem depender exclusivamente de cor. |
| J — histórico de vitórias | Distinguir rounds da MD3 de partidas vencidas. MVP: total de partidas vencidas e cinco últimos resultados da sessão local, atribuídos ao jogador/perfil; indicar `NESTA SESSÃO`. | Não é estatística vitalícia, conta verificada nem histórico importado. Persistência em disco é uma etapa opcional posterior, sem servidor. Empate não soma vitória; mudança de CT/TR/agente não transfere histórico. |

A dimensão candidata 36 implica poço de 216×432, não 192×384. Exige reequilibrar margens superiores, afastamentos e placas centrais. Não basta aumentar o sprite acima do tamanho da célula: isso causa sobreposição e altera a percepção de colisão. O conjunto de elementos em cada poço deve compartilhar a mesma transformação; NEXT e textos usam transformação própria.

Diagrama de composição proposta, sem escala certificada:

```text
[WARNING     00]    [NEXT]   LOGO   [NEXT]    [WARNING     00]
[ poço P1 maior ]   nickname       nickname  [ poço P2 maior ]
[              ]   patente/?      patente/? [              ]
[              ]       personagens         [              ]
[ ENVIADAS N   ]     SCORE  VS  SCORE       [ ENVIADAS N   ]
                     rounds da MD3
               histórico local separado / rodapé
```

Sem decisão de coordenadas finais nesta etapa. O layout deve acomodar dois nicknames longos, patente/?, WARNING e 99 simultâneos, além de uma cadeia e Power grande, sem cobrir a entrada ou células.

## 4. Separação arquitetural proposta

Não introduzir framework, barramento global ou reescrever toda a arena. Um fluxo mínimo:

```text
V10: Model / Session / seleção ── leitura ──> HudPresenter ── snapshot ──> HudView
Perfis e histórico locais ─────── leitura ───────┘                         ↑
Ataque confirmado, se disponível ──────────────┘                   HudLayout
```

1. **Estado/regras:** `godot/core/` continua dono de tabuleiros, duplas, stream/RNG, ataque/cancelamento, score e MD3. O HUD não invoca `tick`, `spawn`, `resolve`, `cancel_attack` ou `record_round`, não escreve nessas estruturas e não calcula economia de ataque. Não usar animação ou callbacks de desenho para alterar o jogo.
2. **Dados exibidos:** novo `godot/presentation/hud_presenter.gd` (proposto) projeta cópias/valores escalares: slot/identidade, nickname/patente, score, round_wins, next_colors já obtidas, pending_raw/display, danger e eventos confirmados. Snapshot não carrega referências mutáveis às células/perfis. A entrada NEXT é fornecida pelo caminho existente, nunca consultada pelo presenter.
3. **Layout/desenho/animações:** `hud_layout.gd` concentra retângulos/margens/escala; `hud_view.gd` desenha o snapshot. Manter desenho CanvasItem/Node2D onde já funciona; usar Control/containers para textos variáveis se necessário, sem migração ampla do jogo. Um relógio visual isolado, sem efeitos no relógio CPS-2, observa pausa/round/replay e limpa animações quando a identidade da partida muda.
4. **Projeção do poço:** futuro `board_view.gd` ou transformação CanvasItem dedicada agrupa o desenho por jogador em coordenadas canônicas de 32 px. Incluir gema ativa, contornos, Power, flashes, fundo/moldura e recorte; converter apenas endpoints de efeitos que cruzam poço/arena. Não escalar objetos de lógica nem resultados de `PairRotation.points()`. VFX que usam coordenadas absolutas exigem inventário antes de mexer nas chamadas.
5. **Perfil/histórico:** `godot/ui/player_profile.gd` e `local_player_history.gd` (propostos, fora de `core`) guardam identidade de apresentação e resultados da sessão. Não usar equipe, nome exibido editável ou agente como chave. Fonte futura de perfil pode substituir a local sem mudar modelo/seleção de agentes. Caso haja persistência, arquivo próprio versionado em `user://`, gravação atômica e recuperação de arquivo inválido; não reutilizar dados de replay/fixtures.

`main.gd` poderá receber somente a ponte visual mínima em futura etapa aprovada; `_physics_process` conserva cadência/ordem dos ticks e atualização de controles. Capturar dados observacionais uma vez por tick lógico; `_draw()` só renderiza o snapshot e a dupla NEXT já obtida pela rotina atual. Não aumentar a quantidade de chamadas a `get_next_colors()` nem mover sua geração para outro ponto nesta V11. Se for necessário corrigir essa dívida para obter leitura pura integral, apresentar proposta separada com prova de preservação do stream/RNG, sem misturá-la à entrega visual.

A interface não deve receber eventos de input destinados ao tabuleiro: HUD sem foco e sem consumir teclas/gamepad. IDs de partida/resolução/onda evitam duplicação após redraw, resize, pause ou mudança de cena.

## 5. Fonte de verdade para ENVIADAS e histórico

**Lacuna encontrada:** `wave.attack`/`result.attack` representam ataque bruto. No caminho temporal, `gem_motion.gd` chama `model.cancel_attack()` e soma seu retorno ao pending adversário com teto 250. O retorno líquido não fica armazenado em um evento público de apresentação. `pending_after - pending_before` não basta: no mesmo tick pode haver cancelamento, geração do outro lado e entrega/consumo. `last_results` é acumulado por referência e pode ser substituído/repetir valores entre resoluções. Score não é conversor confiável de pedras.

Contrato proposto para F: **ENVIADAS = incremento efetivamente aceito na fila adversária por aquela onda**, depois de cancelamento e teto; não significa pedras que já aterrissaram. Registrar separadamente bruto, líquido após cancelamento e aceito na fila, caso seja necessário depurar. Exemplo conceitual de aceitação, sem recalcular economia no HUD: com ataque bruto 20 e cancelamento confirmado de 6, o fato de saída é 14; se a fila estava em 245 e o teto é 250, a fila aceita 5. Esses números exemplificam o contrato, não uma nova regra.

Para obter o fato exato, recomenda-se avaliar uma **notificação somente observacional no ponto da chamada existente**, contendo match/round/resolution/chain/wave/player e valores efetivos já calculados. Isso exigiria uma adição de telemetria em arquivo de `core` ou um ponto de observação equivalente comprovado. **Não está autorizado neste planejamento e não deve ser executado enquanto o núcleo estiver congelado.** Deve ser proposto como mudança separada, sem alterar qualquer expressão, ordem ou retorno da regra V10, e receber autorização específica. A primeira implementação V11 não depende disso.

Se for exigida preservação byte a byte de `core/` durante toda a V11 e não existir outra fonte exata validada, o item F fica pendente: mostrar `GERADAS N` a partir de `wave.attack` só seria alternativa com aprovação expressa do usuário, nunca rotulada ENVIADAS. Não substituir a exigência silenciosamente nem simular a regra no presenter. Este é um bloqueio de dados do item F, não da execução das outras etapas.

Para J, a fonte já existente é `Session.phase == finished`, `Session.winner` e `Session.match_id`. Observar o resultado confirmado e registrar uma única vez por match_id; replay/showcase não contam. Somar partidas vencidas separadamente dos rounds, ignorar empates e finais ainda não confirmados. Fonte de histórico importado/online não existe. MVP de sessão pode usar identidade estável local por slot, claramente indicada como local; perfis duráveis seriam necessários antes de prometer histórico de jogador entre execuções.

## 6. Etapas pequenas, dependências e aprovação

Todas são propostas futuras. Cada aprovação autoriza somente sua etapa; nenhum destes arquivos de código/testes foi criado ou alterado agora.

### V11.1 — contrato visual e referências (primeira etapa recomendada)

- **Objetivo:** ficha de evidências do HUD CPS-2, mockups estáticos A/B e decisão de dimensão das gemas/NEXT, WARNING, alinhamento de identidade e significado do histórico/ENVIADAS.
- **Arquivos:** `planejamento/V11_PLANO_HUD.md`, futuros `planejamento/v11_hud/REFERENCIAS.md` e `LAYOUT_APROVADO.md`; previews na entrega externa. Apenas documentos/protótipos isolados, sem integrar ao jogo.
- **Riscos:** extrapolar medidas de 384×224 para toda a tela CS; confundir DANGER nativo com WARNING solicitado; sobreposição de textos longos e efeitos.
- **Verificação necessária:** inspeção de regiões/hash das capturas, desenho de caixas e margens, mockups no viewport 1000×700 e na janela 1280×896 com escala/letterbox definida; verificar nomes longos e dois alertas/99 simultâneos. Sem teste de jogo, pois não há implementação.
- **Aprovação:** usuário escolhe A ou B, dimensões e semânticas explicitamente; toda medida tem origem ou rótulo de proposta; nenhum arquivo executável alterado. F pode permanecer bloqueado sem impedir a aprovação do layout.

### V11.2 — dados do HUD sem mudança de aparência

- **Objetivo:** introduzir projeção de leitura e snapshot, com saída visual idêntica à V10. Dependência: contrato V11.1.
- **Arquivos previstos:** novos `presentation/hud_presenter.gd`, `tests/test_hud_presenter.gd`; ponte mínima em `presentation/main.gd`, pontos de entrada em `cs_arena.gd`.
- **Riscos:** mutação por referência, RNG extra via NEXT, eventos duplicados, consumo de inputs.
- **Testes necessários:** snapshot antes/depois com mesmos dados; verificar hashes/estado de células, scores, pending, RNG, stream e `pair_index` antes/depois de leituras/redraws; 0/1/98/99/100/250; zero calls adicionais à consulta NEXT; pausa/replay/restart, P1/P2 e slot CT/TR trocado. Comparação de frames com V10 antes da alteração estética.
- **Aprovação:** leitura não modifica o modelo nem a sequência RNG, resultado visual idêntico, controles e física existentes aprovados; nenhum arquivo de `core` alterado.

### V11.3 — NEXT compacto (B)

- **Objetivo:** reduzir caixa e espaçamento da dupla usando valores aprovados, sem mudar a próxima peça. Depende de V11.1–2; independente da ampliação do poço.
- **Arquivos:** `presentation/hud_layout.gd`, `hud_view.gd` (novos conforme necessidade); mudanças locais em `main.gd` e `cs_arena.gd`; novo `tests/test_hud_next.gd`.
- **Riscos:** inverter pivô/satélite, cortar C4/Crash, escalar contorno temporal como se fosse preview, alterar geração por redraw.
- **Testes:** ambos os slots, quatro cores e tipos disponíveis, sequência longa de NEXT, imagens em dois tamanhos de janela, contagem/ordem de geração do stream idêntica à V10.
- **Aprovação:** caixa e margem aprovadas, sem corte/sobreposição, distância visual aprovada, mesmos códigos e RNG da base.

### V11.4 — WARNING e ataque recebido (C–E)

- **Objetivo:** substituir a faixa de ícones/xN por WARNING e contador oposto 00..99 com paleta aprovada. Depende de V11.2; não depende de perfil ou ENVIADAS.
- **Arquivos:** `hud_presenter.gd`, `hud_view.gd`, `hud_layout.gd`; `cs_arena.gd:draw_warning_gems()/draw_board_well_frame()`; novo `tests/test_hud_warning_attack.gd`.
- **Riscos:** teto visual virar teto lógico, alertar lado errado, usar cor de equipe como intensidade, invadir coluna de entrada.
- **Testes:** limites de cada faixa cromática, 0/99/100/250, perigo por pending e por ocupação, ausência de perigo, perda/pausa, chegada/cancelamento, ambos os slots e equipos invertidos; comparar pending real antes/depois do draw.
- **Aprovação:** C/D nunca se sobrepõem; 100 e 250 desenham 99 sem mudar dado; critério de perigo V10 preservado; números legíveis sem cor; nenhum tick ou regra muda.

### V11.5 — quantidade enviada pela cadeia (F, condicionada à fonte exata)

- **Objetivo:** documentar/validar fonte de saída efetiva e então exibir N por resolução/onda. Depende de V11.2 e de autorização específica da eventual telemetria observacional.
- **Arquivos:** `hud_presenter.gd`, `hud_view.gd`; novo teste `test_hud_sent_attack.gd`. Se necessário, proposta separada para o ponto em `core/gem_motion.gd`/`match_model.gd`; esses arquivos são dependências de dados, não autorização de edição.
- **Riscos:** mostrar bruto como enviado, contar duas vezes, somar ataque inimigo, perder evento no teto 250, criar nova dependência do núcleo no desenho.
- **Testes:** sem cancelamento, parcial/total, saturação da fila, entrega no mesmo tick, ataques simultâneos, duas/três ondas, Diamond sem ataque, redraw/pausa/restart. Comparar saída observada à execução real sem recalcular regras no HUD.
- **Aprovação:** uma exibição por ID e quantidade exata confirmada; zero diferença de trajetória/score/pending/stream em comparação determinística. Sem fonte/autorização, manter F explicitamente pendente e prosseguir só com etapas independentes.

### V11.6 — nickname e patente/ausência (G–I)

- **Objetivo:** dados locais mínimos de identidade e apresentação abaixo do NEXT; nome do agente permanece como informação de seleção. Depende de V11.1–2; independente de F.
- **Arquivos:** novos `ui/player_profile.gd`, `tests/test_hud_identity.gd`; `hud_view.gd`, `hud_layout.gd`, `presentation/player_select.gd` e ponte visual de `main.gd`. Sem alteração em `character_catalog.gd`/`selection_state.gd`.
- **Riscos:** nickname virar chave de personagem, patente inventada, textos cortados, insígnia ausente, mudança de equipe afetar perfil.
- **Testes:** nickname vazio/curto/longo/Unicode, colisão de nomes, rank conhecido/desconhecido/nulo, recurso visual faltante, sem foco de teclado; confirmação/cancelamento da seleção conserva IDs e padrões de ataque; troca de CT/TR não troca jogador.
- **Aprovação:** nickname no rótulo de duelo; patente abaixo; `?` cinza para ausência; IDs/agentes/inputs e regras de seleção idênticos à V10. Fonte de dados e conjunto de patentes claramente aprovados.

### V11.7 — histórico da sessão (J)

- **Objetivo:** total local e cinco últimos resultados, separados das vitórias de rounds. Depende de identidade V11.6 e observação de Session.
- **Arquivos:** novo `ui/local_player_history.gd` e `tests/test_player_history.gd`; ponte observacional em `main.gd`, `hud_view.gd`/layout. `core/match_session.gd` permanece intacto.
- **Riscos:** contar round como partida, duplicar por redraw/fim de cena, misturar perfis, inventar histórico entre execuções.
- **Testes:** MD3 2–0/0–2/2–1/1–2, round empatado, resultado final observado repetidamente, nova partida, cancelamento, replay/showcase, troca de equipe/agente e slot.
- **Aprovação:** uma vitória por partida confirmada; rounds da MD3 inalterados; reset da sessão documentado; identificação `NESTA SESSÃO`. Persistência, se pedida, vira etapa separada com identidade estável e testes de corrupção/escrita interrompida.

### V11.8 — ampliação visual do poço/gemas (A)

- **Objetivo:** aplicar a dimensão aprovada com transformação única e reposicionar os elementos afetados. Depende de V11.1 e do layout/HUD já separado; não depende de F/J.
- **Arquivos:** futuro `presentation/board_view.gd`, `hud_layout.gd`, pontos de desenho em `main.gd`/`cs_arena.gd`; novos `tests/test_board_view_projection.gd` e capturador de layout V11. Evitar alterar `pair_rotation_visual.gd`: transformar sua saída canônica no desenho.
- **Riscos:** mais alto da V11 — clipping de linhas ocultas, giro desalinhado, Power/flash/VFX em escalas distintas, distorção por escala fracionária, inferência de jogador por coordenada em `temporal_player_at()`. Não alterar constantes 32 dispersas às cegas.
- **Testes:** projeção e inversa dos centros, seis colunas/doze linhas visíveis, dupla nas quatro rotações/corredores/paredes, todas as espécies e Power formação/crescimento/união, duas/três ondas, Counter Gems, pausa/resize/replay, cena real e P1/P2. Comparar máscaras após normalizar a transformação, sem exigir mesmos pixels absolutos de V10.
- **Aprovação:** tamanho aparente escolhido, sem sobreposição/clipping/resíduos, correspondência exata dos pontos lógicos normalizados, todos os relógios/trajetórias/inputs preservados. Se a transformação não abranger VFX corretamente, não aprovar A como concluído.

### V11.9 — regressão final e documentação

- **Objetivo:** verificar integração das etapas aprovadas e declarar honestamente itens concluídos/pendentes, sem publicar automaticamente.
- **Arquivos:** novos relatórios `relatorios/v11_hud/`, documentação e continuidade; scripts novos com destinos inéditos. Não sobrescrever relatórios/fixtures V10 nem afrouxar validadores para acomodar o HUD.
- **Riscos:** falso verde por conjunto vazio, comparador de imagem preso a coordenadas V10, alerta no slot errado, vazamento de dados entre partidas.
- **Testes:** suítes existentes de física (112/14.072), combos (22/5.066/54), controles (33 e 866 observações RNG), Power (394 e 181 pares/1.407), rotação (119.052), visual temporal (123.863), Coin Flip, seleção/rounds, Python, smoke das quatro cenas, 1.000 séries integradas e quatro séries em janela. Confrontos visuais V11 devem normalizar o layout ou ter adaptador novo, preservando o comparador e dados V10. Dados vazios devem falhar. Incluir screenshots de todos os estados HUD e janelas aprovadas.
- **Aprovação:** zero falha nova de jogo, contadores compatíveis com a base e diferenças de pixels explicadas somente por layout aprovado. Os 73 avisos nativos herdados têm baseline; não alegar zero avisos nem suprimir novos. F só consta concluído se a fonte exata foi validada. Relatório e autorização próprios antes de commit, push, integração ou tag.

Ordem recomendada: **V11.1 → V11.2 → V11.3 → V11.4 → V11.6 → V11.7 → V11.8 → V11.9**. V11.5 segue em trilha independente, condicionada à decisão da fonte ENVIADAS. Cada etapa permite inspeção isolada e não autoriza iniciar automaticamente a próxima.

## 7. Decisões e limites antes da primeira implementação

1. Aprovar contrato visual: opção de tamanho do poço, dimensões do NEXT e faixas cromáticas. Valores atuais versus candidatos estão discriminados acima.
2. Aprovar o significado de ENVIADAS e decidir se poderá ser proposta telemetria somente observacional em mudança separada. Enquanto isso F não tem solução certificada com as fontes expostas atuais.
3. Aprovar perfis locais sem conta e histórico da sessão como escopo inicial; catálogo de patentes, credenciais, rede/servidor, XP, matchmaking e histórico vitalício ficam fora.
4. Autorizar criação futura de `feature/v11-hud`; até lá, somente estes documentos locais. Tag estável e branch main não serão alteradas por implementação inferida.

Mantêm-se as limitações V10 de RNG integral, RGB/arte/explosões, geometrias/P2 e outras plataformas/periféricos. A V11 não certificará automaticamente fidelidade integral ao arcade apenas por aproximar a composição. Não mudar física, RNG, combos, pontuação, temporização, controles, seleção de personagens ou regras da MD3 para satisfazer um layout.

## 8. Resultado desta etapa de planejamento

Criado somente `planejamento/V11_PLANO_HUD.md`; acrescentada à continuidade apenas a nota de início do planejamento. Código, testes, fixtures, sprites, README, arquitetura, relatórios anteriores e dois arquivos locais não rastreados preservados. Nenhuma ferramenta instalada, teste de jogo executado, branch criada, tag alterada, merge, commit ou push efetuado.

**Próxima ação: aguardar autorização do usuário para V11.1 (referências e mockups isolados). Não implementar HUD no jogo nesta etapa.**
