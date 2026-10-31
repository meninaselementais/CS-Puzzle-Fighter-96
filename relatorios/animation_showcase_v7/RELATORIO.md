# Animation Showcase e melhorias visuais — 30/10/2026

O projeto existente foi continuado a partir das atualizações v5/v6 encontradas. Não houve restauração de código antigo, recriação do projeto nem commit. O núcleo, as fixtures e os sprites originais desta versão foram preservados por SHA-256.

## Estado examinado antes das alterações

- `README_FIDELIDADE_V5.md`, `relatorios/fidelidade_v5/relatorio_tecnico.md`, código atual, scripts de teste, fixtures, fontes de arte e revisão `antes_animacoes_v6_20261030_0020`.
- Vídeo localizado em `relatorios/fidelidade_v6/demo_combos_1x_5x_c4_orbs.mp4`: H.264, 1000×700, 120 quadros, 20 fps, 6 segundos. O gerador avança uma vez por tick do arcade; exportá-lo a 20 fps dilata o tempo por aproximadamente 2,982 vezes.
- Não foram localizados os arquivos exatos `RELATORIO_COMBOS_C4_CRASH_ORBS.md` e `demonstracao_visual_cps2.md` nas pastas do projeto/áreas pesquisadas. Nenhum conteúdo foi atribuído a esses documentos.
- O projeto não possui repositório Git nesta pasta. O histórico disponível consiste nos relatórios, arquivos atuais e pastas em `revisoes`.
- Backup desta intervenção: `revisoes/antes_showcase_20261030_175749`, contendo apresentação, testes e configuração, além do manifesto inicial de preservação. Os relatórios anteriores continuam nas suas pastas; a demonstração antiga foi reexecutada com saída separada em `final/legacy_demo`.

## Avaliação do vídeo e comparação com o arcade

A referência principal foi capturada diretamente da cópia isolada do MAME 0.289, `spf2tu`, sessão `laboratorio/auto_20261030_180156_204005`. O script `lua/referencia_visual.lua` restaura o mesmo estado e monta três tabuleiros sintéticos na RAM de laboratório: limpeza com duas ondas, Power Gem e Diamond. Não grava na ROM. São 240 quadros por cenário, com imagens e CSV de fase/pontuação.

No arcade, a limpeza concentra a fragmentação nas gemas e mantém a leitura do tabuleiro e das poses centrais. Nos ensaios, a fase 11 dura 40 quadros por onda efetiva (duas no cenário de cadeia; uma em Power e Diamond). Uma passagem posterior de um quadro pelo estado 11 não equivale a outra onda. Isso foi registrado em `referencia_mame.json`; não se declarou equivalência de duração entre a nova apresentação e toda a máquina de estados CPS-2.

| Aspecto | Observação na versão recebida | Alteração e situação atual |
|---|---|---|
| Qualidade das animações | Sprites desenhados existentes têm boa leitura; algumas sequências trocam poses inadequadas ou são cortadas antes da recuperação. | Sprites preservados. Estados de ação completam a sequência e vitória/derrota sustentam a pose final. |
| Fluidez SAS/Phoenix | O tempo do vídeo mascara a cadência real. Phoenix possui apenas uma imagem de disparo, SAS possui mais variações. | Eventos seguem os quadros reais existentes, com recuo e recuperação; não se alegou criação de novos desenhos intermediários. |
| Crash Orbs | Quatro cores e transparência já implementadas; núcleo branco muito opaco pode encobrir o vidro. | Texturas e alfa originais preservados, luz branca central reduzida para manter leitura do vidro. |
| C4 | Dois sprites de LED e visor já existentes; demonstração antiga sobrescreve o NEXT compartilhado ao montar previews diferentes para jogadores no mesmo índice. | Showcase configura um NEXT compartilhado coerente com C4, mostra repouso e detonação separadamente. Não altera geração de duplas. |
| Explosões/fragmentação | Flashes da célula permanecem após a detonação e podem gerar efeitos duplicados. Power Gems produzem muitas explosões sobrepostas. | Flashes encerrados na fronteira do impacto; um impacto principal por Power Gem, estilhaços por célula, rotação dos fragmentos e dissipação. |
| Progressão 1X–5X | A sequência existe, mas o popup usa uma fórmula visual independente da pontuação real; 5X dispara granada e imediatamente troca a pose para tiro. | Pontuação de cada onda lida de uma resolução em cópia; 5X preserva a granada. Showcase contém casos reais de 1 a 5 ondas resolvidos pelo mesmo núcleo. |
| Sincronização | Disparos/granadas surgem antes da pose; ataques simultâneos podem interromper a animação do outro jogador. | Projéteis saem nos keyframes e em pontos de mão/cano da textura; dano durante ataque é sinalizado e sua recuperação fica pendente, preservando ambos os ataques. |

A nova sequência separa antecipação, impacto/fragmentação e queda. A queda visual usa a distância efetiva de cada sobrevivente, inclusive blocos unidos, em vez de deslocar toda gema apenas 30 pixels. Esses tempos são de apresentação e continuam aproximados: não representam um novo porte da cronologia CPS-2.

## Animation Showcase

Abra `Animation_Showcase.cmd` na raiz do projeto ou pressione **F4** no jogo. F4 volta à partida; a troca de cena inicia uma nova partida ao retornar. A entrada padrão `Jogar.cmd` continua apontando para a cena jogável habitual.

Há 14 tópicos: idle, disparos, granadas, dano, vitória/derrota, Crash Orbs, C4, Power Gems, combos 1X/2X/3X/4X/5X e ataques simultâneos. Selecione SAS, Phoenix ou ambos. Há pausa, avanço de um quadro, repetição e alternância automática. Espaço pausa; N avança; setas trocam o tópico; R repete.

O laboratório visual congela o relógio da partida. Tabuleiros de demonstração são resolvidos pelo núcleo existente e exibidos pela mesma apresentação do jogo. Não é uma gravação de partida humana nem evidência de fidelidade mecânica adicional.

## Testes reexecutados

Os resultados foram confirmados antes das mudanças e repetidos depois delas. Os logs completos e códigos de saída estão em `baseline`, `final` e `final/summary.json`.

| Bateria | Resultado final |
|---|---:|
| Python unittest | 17/17 |
| Geometria/modelos | aprovado |
| Regras | 34/34 |
| Comparações MAME derivadas de fixtures | 247/247 |
| Controles | 33/33; 866 amostras de RNG; 10 fontes inválidas continuam explicitamente excluídas |
| Endpoints naturais | 119/119 |
| Duelo | 1.500 turnos, 26 partidas, 239 ondas, 908 ataques brutos |
| Regressões de apresentação | 3.273 verificações, nenhuma falha; inclui invariância do modelo durante a animação, esgotamento dos efeitos, pontuação por onda, 1X–5X, tiros simultâneos, granada e poses finais |
| Renderização anterior e interface nova | render_preview, render_mechanics, test_showcase_ui e demonstração anterior de combos/C4, com logs individuais |
| Referência visual MAME nova | três cenários concluídos; 720 amostras, preservação das fontes confirmada pelo runner |

As 3.273 verificações incluem asserções repetidas de invariância a cada quadro; não são 3.273 situações mecânicas distintas. Os 119 endpoints usam snapshots e filas/eventos amostrados nas partidas de referência: não equivalem a uma nova partida inteira autônoma Godot/MAME sincronizada quadro a quadro. O novo ensaio MAME é visual, sem atualização das fixtures para forçar aprovações.

Reprodução:

```powershell
cd C:\Projetos\CS-Puzzle-Fighter-96
python -B scripts\validar_apresentacao.py --render
```

O runner redireciona os dados temporários/logs do Godot para a pasta do relatório, sem exigir alterações nas configurações do usuário. Os testes iniciais tiveram avisos de escrita de log/cache fora da sandbox; a execução final utiliza o diretório autorizado.

## Arquivos alterados/criados

Alterados:

- `godot/presentation/cs_arena.gd`: ciclo das ondas, flashes, pontuação visual, queda, keyframes, anexos de projéteis e fragmentos.
- `godot/presentation/main.gd`: entrada F4 e posição visual de Power Gems em queda.
- `godot/tests/render_chains_and_c4_demo.gd`: reutiliza os mesmos tabuleiros e permite saída de relatório separada.

Criados:

- `godot/animation_showcase.tscn`, `godot/presentation/animation_showcase.gd`, `godot/presentation/showcase_fixtures.gd`.
- `godot/tests/test_presentation.gd`, `godot/tests/test_showcase_ui.gd`, `godot/tests/render_animation_showcase.gd`.
- `scripts/validar_apresentacao.py`, `lua/referencia_visual.lua`, `Animation_Showcase.cmd`.
- `relatorios/animation_showcase_v7/`: relatório, diffs, logs, manifesto, referências, demonstração e timeline.

Não houve alteração de `godot/core`, `godot/data`, texturas existentes, configuração de projeto, launcher de jogo, ROM, instalação Steam ou instalação MAME. `preservacao.json` verifica os 114 arquivos do núcleo/dados/arte/Original listados antes da intervenção e as fontes usadas pelo runner MAME. Isso não é uma auditoria de cada arquivo de toda a instalação Steam.

## Demonstração e limites

- `animation_showcase_v7.mp4`: 950 quadros, 1000×700, 29,818702 fps, aproximadamente 31,86 segundos. Cada quadro corresponde a dois ticks de 59,63740458 Hz; a reprodução respeita a duração da animação.
- `preview_5x.gif`: trecho do combo 5X, sem áudio.
- `showcase_*.png`: quadros representativos das 14 cenas; `showcase_ui_c4.png` valida a interface e o recorte da C4.
- A paleta, composição e fragmentação são inspiradas no CPS-2, com arte CS existente. A tela lógica continua 1000×700; não é uma reprodução pixel a pixel de 384×224.
- Phoenix ainda precisa de mais desenhos próprios para disparo, lançamento, vitória e derrota. Parte da fluidez usa reposicionamento/recuo sobre as poses já disponíveis. Nenhum sprite foi substituído por geometria simples.
- O motor continua com resolução lógica imediata e sequência de peças aproximada, conforme os comentários do código existente. A cronologia visual não modifica o momento lógico de ataque, travamento ou entrada da próxima dupla. Partidas completas sincronizadas continuam pendentes.
- A sincronização corrigida aqui é entre poses, projéteis e apresentação das ondas. A reação do adversário na apresentação não constitui uma nova validação dos tempos nativos de entrega/cancelamento de ataques.
- Duas tentativas preliminares de cenário Crash não provocaram limpeza; uma tentativa usou callback Lua indisponível. Estão excluídas da evidência final em `referencia_mame.json`. A sessão final exige pontuação de limpeza e concluiu os três casos.
