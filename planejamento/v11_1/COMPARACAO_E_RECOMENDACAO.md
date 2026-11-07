# V11.1 — referências visuais e três mockups

05/11/2026, America/Sao_Paulo. Base: `v0.10.0`, commit `1a943a4db4d1dba84a222735187afb6108b4c4c5`. Trabalho exclusivamente visual/documental na branch **feature/v11-hud**, criada nesta etapa. Main e tags preservadas; sem commit/push. V11.2 não iniciada.

Abra [GALERIA.html](GALERIA.html) para comparar as propostas e a interface atual. Cada mockup tem **1000×700**, também disponível em SVG editável e PNG. A comparação conjunta tem 3000×760, com cabeçalho de 60 px e três imagens integrais. Não se trata de screenshots de uma implementação V11.

## 1. Captura real e diagnóstico do HUD atual

[Captura da interface V10](referencia_atual/prototipo_godot.png), gerada nesta etapa em janela Godot real, OpenGL/NVIDIA, pelo script existente `godot/tests/render_preview.gd`. `PF_REPORT` foi redirecionado para esta pasta; código de saída 0 e marcador `GODOT_RENDER_OK`, sem erros no log. Comando e duração em `referencia_atual/execucao.json`. O capturador exibe a fixture de replay `rotacao_2`, quadro 16, com SAS/Phoenix. É uma execução da apresentação V10 em replay; não uma partida natural completa nem coleta MAME nova. O renderizador não foi alterado.

Inspecionados `presentation/main.gd`, `cs_arena.gd`, `pair_rotation_visual.gd`, `player_select.gd` e o plano V11 já existente. Valores abaixo vêm do código V10:

| Elemento | Atual em 1000×700 | Fonte/observação |
|---|---|---|
| Grade lógica | 6×14; duas linhas ocultas | `board_model.gd`; 6×12 visíveis |
| Poços visíveis | P1 (64,108), P2 (744,108); 192×384 | `main.gd:BOARD_ORIGINS`, `cs_arena:draw_board_well_frame()` |
| Passo visual | 32 px | Poços laterais e rotação orbital |
| Corpo das gemas | Destino genérico nominal 31 px; caminho temporal normal usa 32×32 com máscara interna própria | `draw_gem_sprite()`; não confundir retângulo da textura com pixels opacos |
| NEXT | P1 (284,56), P2 (652,56); 64×114 | `draw_central_arena_and_hud()` |
| Dupla NEXT | Centros (x+32,y+32) e (x+32,y+76), distância 44 | `main.gd:_draw()`; satélite acima do pivô |
| Topo do poço | Ícones pendentes começam aproximadamente y=58; barra/moldura y=82..104; primeira linha visível y=108 | `draw_warning_gems()` / moldura. A faixa 0..108 não está toda livre. |
| Distância entre áreas internas | 488 px entre x=256 e x=744 | Comporta logo, NEXT e personagens; não significa 488 px desocupados |
| Nomes | SAS/PHOENIX abaixo do NEXT, baseline y=192 | Agentes escolhidos, não nicknames |
| SCORE | Placas (280,520)/(544,520), 176×56; VS ao centro | Pontos do modelo; nenhum perfil/histórico de carreira |
| Vitórias | Ícones V sob SCORE e faixa MD3 em y=607..632 | São rounds da série atual |
| Rodapé | Comandos/modo/replay perto de y=658 e faixa inferior | Concorre com qualquer novo histórico |
| Ataque | Ícones por seis/unidade + xN, sem teto visual 99 | Valor de `model.pending` do próprio jogador |
| WARNING | Não existe letreiro literal no duelo atual | Função de nome `draw_warning_gems` não equivale a WARNING; perigo já orienta animação do agente |

**Sobreposições e pontos de atenção:** ícones/xN competem com a barra superior quando N cresce; nome maior que o agente pode invadir a arena; flashes, projéteis e banners de combo compartilham a camada de desenho; shake desloca a cena. NEXT ocupa área alta importante e seus centros têm 44 px de separação. A captura escolhida tem ataque pendente zero e não demonstra a pressão máxima desses elementos. Não se afirma que uma sobreposição específica foi reproduzida em jogo só por identificar esse risco no código.

Consulta NEXT atual pode consumir RNG ao ampliar stream. Esta etapa não a corrige nem acrescenta chamadas ao jogo; os NEXT dos mockups são dados desenhados isoladamente.

## 2. Referência ao arcade e limites de medição

Capturas existentes inspecionadas:

- `laboratorio/auto_20261101_001520_164035/snap/speed_0_down_0_f041.png`: composição geral, NEXT, nomes, personagens, SCORE/VS/V.
- `laboratorio/auto_20261101_222825_850720/snap/rotation_r0_b1_f004.png`: composição durante giro.
- `laboratorio/auto_20261028_232043_038647/snap/attack_red12_f0180.png`: DANGER à esquerda do topo do poço de P2; contador 33 à direita.
- `laboratorio/auto_20261028_232043_038647/snap/attack_p2_red12_f0180.png`: mesmo posicionamento local de DANGER/33 em P1.

São imagens **384×224**, já conferidas por cabeçalho no diagnóstico V11.0. Referência de geometria: comparadores `comparar_rotacao_v10_3_3.py` / `comparar_contornos_v10_3_2.py` mapeiam a região P1 nativa x=16..111/y=16..207 com escala local 2× para o Godot. Não usar isso como escala uniforme do HUD inteiro. Não foram medidos nesta etapa bounding boxes exatos do NEXT, fontes, personagens e bordas nativas.

O arcade mostra poços laterais, NEXT compacto nas bordas do centro, logo e personagens centrais, nomes próximos ao NEXT e placares abaixo dos personagens. A região central contém jogo visual relevante, portanto não é um painel vazio a preencher. A referência sugere alerta/contador em lados opostos do topo, preservados nas três alternativas.

**O texto nativo observado é DANGER.** WARNING é a adaptação pedida. Teto visual 99, cor de intensidade, nome de jogador, patente, histórico e indicador ENVIADAS são propostas CS, não comportamentos nativos certificados. O nome “Arcade fiel” descreve a proximidade da composição; não certifica igualdade de pixels, proporções completas ou regras com CPS-2. Nenhum asset de ROM/MAME foi usado nas imagens novas: somente assets próprios já existentes no projeto e formas vetoriais.

## 3. Estado idêntico usado nos mockups

As três alternativas mostram os mesmos dois tabuleiros sintéticos, cores e dupla ativa, uma Power 2×2, Counter Gem, NEXT, placares, 1–0 na MD3 e perfis demonstrativos. Não são uma evolução da captura real e não resultam da simulação de uma partida. Todos os números são exemplos visuais:

- MAUTRIX / PLAYER_02; emblema genérico de patente DEMO / caixa cinza `?` e SEM PATENTE.
- Ataque recebido 33 / 99, sendo o segundo caso uma ilustração de pendência real 132 saturada visualmente em 99. O rodapé explica 99 = 99+.
- COMBO ×2 / ×3; ENVIADAS 14 / 32, **apenas ilustrativo**, sem fonte de telemetria implementada.
- Histórico da sessão: V V D V (3/4) / D V V D (2/4), separado dos rounds da MD3.
- Todas as imagens têm legenda permanente “DADOS FICTÍCIOS” e “PROPOSTA ESTÁTICA”. Os exemplos de nickname não certificam conta/identidade real.

Cores 33 âmbar / 99 vermelho são demonstração de hierarquia visual. As faixas de intensidade da V11.0 eram propostas ainda não aprovadas; estes mockups não aprovam limiares nem reproduzem uma tabela nativa. Definir os limiares após aprovação visual. 00 é o estado neutro cinza previsto; as telas de comparação enfatizam os dois casos ativos, não toda a matriz de estados.

## 4. Tamanhos e posições propostos

**Todas as coordenadas desta seção são propostas para o jogo CS, não medições MAME.** Origem no canto superior esquerdo; unidades são pixels de layout em 1000×700. Detalhes editáveis em `LAYOUTS_PROPOSTOS.json` e nos SVGs.

| Elemento | A — Arcade fiel | B — Counter-Strike | C — Híbrido |
|---|---|---|---|
| Poço P1 / P2 | (40,112) / (744,112) | (40,138) / (744,138) | (40,130) / (744,130) |
| Poço / passo, nos três | 216×432 / 36 | 216×432 / 36 | 216×432 / 36 |
| Destino das gemas comuns | 34×34 dentro de célula 36 | Igual a A | Igual a A |
| Margens externas / centro interno | 40 px / 488 px | Igual a A | Igual a A |
| WARNING | (x−7,y−43), 136×28 | Mesma regra local | Mesma regra local |
| Contador | (x+153,y−43), 70×28 | Mesma regra local | Mesma regra local |
| Caixa NEXT P1 / P2 | (288,105) / (664,105) | (294,203) / (658,203) | (284,108) / (668,108) |
| NEXT / gemas / distância | 48×76 / 32×32 / 32 entre centros | Igual a A | Igual a A |
| Nicknames, centro/baseline | (340,224) / (660,224) | (148,66) / (852,66) | (342,228) / (658,228) |
| Patente | Abaixo do nickname, corpo até y=269 | Faixa compacta y=73..89 | Abaixo do nickname, corpo até y=273 |
| Personagens, caixas de referência | (286,284,205,215) / (509,284,205,215) | (286,284,205,235) / (509,284,205,235) | Igual a B |
| SCORE | (290,518)/(550,518), 160×57 | y=530, mesmas caixas | Igual a B |
| Combo/ENVIADAS | P1/P2 x do poço, y+444, 216×28 | Igual a A, relativo ao poço | Igual a A, relativo ao poço |
| Histórico | P1/P2 x do poço, y+481, 216×48 | Igual a A, relativo ao poço | Igual a A, relativo ao poço |
| Rodapé MD3 | Baselines y=614/641 | Igual a A | Igual a A |

O passo 36 é **12,5% maior** que o atual 32. O sprite comum 34 é cerca de 9,7% maior que o destino genérico 31; isso não certifica aumento igual da área opaca de todos os tipos. Power e contornos temporais exigirão uma transformação consistente em implementação futura. O centro permanece com 488 px porque a ampliação foi para as margens externas, sem reduzir arbitrariamente o espaço dos personagens.

NEXT reduz sua caixa de 64×114 para 48×76, e o intervalo entre centros de 44 para 32. As bordas das duas texturas 32×32 se encostam nominalmente; a transparência do próprio asset mantém o contorno. Decidir visualmente se será necessário 1–2 px adicionais de respiro, sem apresentar esse ajuste como dado nativo.

## 5. Comparação e recomendação

| Critério | A — Arcade fiel | B — Counter-Strike | C — Híbrido |
|---|---|---|---|
| Estrutura arcade | Mais próxima: logo maior, fundo, NEXT/nomes centrais, placas douradas | Menor: identidade no topo e painéis táticos centrais | Alta: mantém hierarquia central e poços laterais |
| Identidade CS | Assets próprios e paleta quente | Mais forte na linguagem tática e contraste | Forte sem substituir a composição arcade |
| Leitura dos dados | Boa, mas fundo/ornamentos competem mais | Melhor contraste; identidade afastada do personagem | Bom contraste e relação espacial de perfil/personagem |
| NEXT | Alto e próximo do nome | Mais baixo, perto da arena | Alto, como no arcade, com dimensões compactas |
| Espaço vertical | Maior folga inferior; personagens um pouco menores | Menor folga inferior; patente precisa de faixa compacta | Folga intermediária; perfil ocupa a região antes dos personagens |
| Principal risco | Poluição visual / contraste em outros mapas | Densidade no topo do poço e distância perfil↔agente | Saturação da faixa central com nicknames muito longos |

**Recomendo C — HÍBRIDO.** Conserva a leitura típica do Puzzle Fighter (poços laterais, NEXT e identificação na área central, personagens e SCORE abaixo), mantém a arte CS já disponível e melhora o contraste sem transformar a arena em um dashboard. Distribui os dados novos sem alterar o espaço lógico e sem vincular nickname à escolha de agente. A é a melhor alternativa se a prioridade máxima for nostalgia arcade; B se a prioridade for linguagem tática e leitura de dados sobre a composição original.

Recomendação é visual, não promessa de menor trabalho técnico: todos os layouts exigem mapear coordenadas de VFX e normalizar comparadores gráficos. C ainda precisa de validação com nomes longos, perda/pausa, alertas intermitentes, cores nos três cenários e fontes menores.

## 6. Limitações de espaço e implementação futura

- WARNING/contador ficam fora da área das células; a abertura/coluna de entrada permanece livre. Não ampliar sprites isolados acima do passo da grade.
- Os mockups reservam 12 px entre o fundo do poço e a faixa de combo. B tem histórico terminando em y=667, próximo ao rodapé em y=675: só 8 px. C termina em y=659; A em y=641. Isso torna B mais sensível a fontes maiores/escala.
- Nickname longo, acentos, fonte substituta ou patente com legenda extensa exigirão truncamento/medição real. Não considerar layout responsivo ou acessibilidade certificados por estas imagens.
- Na primeira renderização, B apresentou patente sobre WARNING; foi corrigido para faixa y=73..89, anterior ao WARNING y=95. A teve rótulo da patente próximo do personagem e recebeu personagem menor/mais baixo. Imagens finais foram inspecionadas visualmente.
- As caixas dos personagens são de imagem inteira; a área opaca depende do asset e não é uma medição de silhouette MAME. As posições no mockup não autorizam mudar animações/ancoragem no jogo.
- Sombreado de fundo é parte da proposta de legibilidade, não mudança aplicada ao cenário de jogo. B não usa imagem de cenário; A/C usam o mesmo asset Dust2 com opacidades diferentes.
- Paleta, dimensão 36 e NEXT 48×76 são candidatos sujeitos a aprovação. Não foram validados em 1280×896 nesta etapa: só o canvas comparável 1000×700 foi renderizado. Janela redimensionada e escala de HUD serão verificadas depois da seleção visual.
- ENVIADAS é apenas representação. Ataque bruto, líquido após cancelamento e incremento aceito na fila não são intercambiáveis; não inferir o valor por diferença de pending nem recalcular regras no HUD. V11.2 não deve implementar esse indicador sem fonte aprovada.
- Patente DEMO e histórico de sessão são exemplos, sem login, XP, ranking ou persistência. Os ícones V da MD3 continuam semanticamente separados do histórico.

## 7. Arquivos, ferramentas e preservação

- `referencia_atual/prototipo_godot.png` e `execucao.json`: captura real nova e comando.
- `A_arcade_fiel.{svg,png}`, `B_counter_strike.{svg,png}`, `C_hibrido.{svg,png}`: três propostas na mesma resolução.
- `comparacao_lado_a_lado.png` e `GALERIA.html`: comparação direta; galeria inclui a captura real.
- `LAYOUTS_PROPOSTOS.json`: coordenadas/dimensões das alternativas.
- `MANIFESTO_SHA256.json`: hashes dos artefatos, emitido depois da validação final.

Ferramentas já instaladas: Python padrão para compor SVG/HTML e conferir arquivos, Chrome headless para rasterizar os vetores, Godot 4.7.2 para a captura. Nenhuma biblioteca/ferramenta instalada. Não foi usada geração de imagem por IA: os mockups são composições vetoriais controladas com assets próprios existentes, não renders de funcionalidades prontas. Scripts de preparação ficam em `work/` externo ao projeto.

Todos os caminhos locais existentes no inventário inicial foram conferidos por SHA-256 ao final. Nenhum foi alterado, incluindo a continuidade já modificada pelo planejamento anterior, o plano V11.0 e os dois relatórios locais não rastreados. As únicas adições no projeto são esta pasta. Main, tag v0.10.0 e branch V10 preservadas. Sem alterações em `main.gd`, código, testes, física, RNG, controles, fixtures ou lógica de partidas. Não há staging, commit ou push. Nenhuma funcionalidade V11.2 foi iniciada.

**Próxima ação:** aprovação visual de A, B ou C, ou solicitação de ajustes aos mockups. A aprovação de uma imagem não autoriza alterar regras nem presumir a disponibilidade dos dados demonstrativos.
