# V11.5 — HUD de ataques, combos e WARNING

Data: 07/11/2026. Base obrigatória: branch `feature/v11-hud`, commit `753722cf4137b1732f08edd06cee66b302057fd5` (V11.4.2). Nenhum commit, push ou tag foi criado nesta etapa.

**Status: implementação visual disponível para revisão, com contador de envio líquido pendente por ausência de fonte no modelo.** O usuário autorizou explicitamente a exposição desse evento em uma etapa posterior. O núcleo permanece intacto nesta execução. Não declarar a V11.5 integralmente concluída.

## Auditoria

Git inicial: somente `.ai/` e `planejamento/v11_1/referencia_atual/execucao.json` não rastreados. Preservados. HEAD confirmado em `753722c`; o histórico possui apenas dois commits anteriores no `git log -3`.

O Presenter já está integrado ao `main.gd`, após as duas chamadas originais a `get_next_colors()`. Fornece perigo, fila pendente, resultado e produção bruta. `sent_attack` é indisponível (`net_sent_attack_not_exposed`). A arena já possui `chain_banners`, duração, animação e relação com as ondas reais. Também possuía ícones para a fila pendente; foram substituídos pelo painel numérico para evitar duplicação. O perigo já era usado na pose dos personagens, mas não havia texto WARNING.

## Implementação

- Ambos os painéis leem a fila real do jogador em `pending_attack`. Zero apaga o indicador. De 1 a 10 aparece **CAUTION** amarelo, de 11 a 30 **WARNING** laranja e a partir de 31 **DANGER** vermelho. Os períodos da pulsação são 48, 32 e 20 ticks, respectivamente.
- **A RECEBER** exibe a mesma fila com limite visual 99. O pulso curto do número acompanha mudanças na fila. A pose de perigo do personagem continua usando o predicado existente, que considera a ocupação do tabuleiro.
- Foram removidas as duas placas cinzas decorativas sobre cada poço. O X vermelho foi mantido como referência fixa da coluna de entrada e da célula de derrota. O aviso de ataque fica dentro do painel, fora da grade.
- **ENVIADAS --** mantém explícita a indisponibilidade. Não se usa produção bruta ou diferença entre frames como envio líquido. Um evento confiável após cancelamento e teto requer a etapa posterior autorizada pelo usuário.
- Reutilização de `chain_banners`: número da cadeia, P1/P2 e pedras brutas produzidas pela onda. O valor vem do `motion.result.waves[-1].attack` real na detonação, nunca da prévia ou de uma estimativa por score. Duração existente de 44 ticks; efeito fora do poço. Não é o total líquido enviado nem acumulado da resolução.
- Relógios avançam somente por `step_from_model`; pausa não cria temporizadores independentes. Layout acompanha o canvas e mantém NEXT intacto.

## Arquivos

Modificados:
- `godot/presentation/cs_arena.gd`: campos de pulso, desenho dos painéis/aviso, fonte única de perigo e detalhe do banner existente.
- `godot/presentation/main.gd`: chamada final de desenho; aceita fixtures históricas sem o novo renderer.
- `godot/tests/test_hud_next.gd`: comparação de tela com exceção apenas dos dois retângulos V11.5, incluindo bordas. Mantidas as verificações independentes do NEXT desenhado versus a dupla real.

Criados:
- `godot/tests/test_hud_v11_5.gd`: ensaio gráfico de ondas reais e contratos do HUD.
- `relatorios/v11_5/run_validation.py`, `protected_hashes.json`, resumos, esta documentação e galeria. Evidências e logs dentro desta pasta.

## Testes realmente executados

Não são resultados históricos. Foram executados Godot 4.7.2 Compatibility, NVIDIA GeForce RTX 5070, nesta execução. 23 processos finais aprovados (1 HUD, 3 focados, 19 regressões).

- HUD V11.5: **5.718 checks**, sem falhas; limites, P1/P2, cadeias de três/cinco ondas, simultaneidade, perigo, imutabilidade do modelo e produção obtida da onda real.
- NEXT: **1.072**; Presenter: **3.931** em 7 suítes; cena HUD: **1.013**.
- Mecânicas: regras 34, fidelidade 247/247, controles 33/33 e RNG 866, natural 119/119, duelo 1.500 turnos/28 partidas/227 ondas/797 ataques brutos.
- Apresentação 3.285, cronologia V10.3.2 123.863, rotação 119.052, Power 394; V8 145 e V9 102.
- Física: 112/112 casos e 14.072 amostras; cadeias: 22/22 casos, 5.066 amostras e 54 checks.
- Partidas em janela: 4/4, 10 rounds e 276 checks. Seleção: 12 capturas em duas dimensões; showcase aprovado.
- Lint executado antes/depois: 0 erros, 11 avisos já existentes. `git diff --check` sem erros.

| Bateria | Processo | Resultado |
|---|---|---|
| hud5 | `hud5` | APROVADO |
| focused | `hud_next` | APROVADO |
| focused | `hud_presenter` | APROVADO |
| focused | `hud_scene` | APROVADO |
| regression | `test_models` | APROVADO |
| regression | `test_rules` | APROVADO |
| regression | `test_fidelity` | APROVADO |
| regression | `test_controls_fidelity` | APROVADO |
| regression | `test_natural_fidelity` | APROVADO |
| regression | `test_duel` | APROVADO |
| regression | `test_presentation` | APROVADO |
| regression | `test_coin_flip` | APROVADO |
| regression | `test_character_select` | APROVADO |
| regression | `test_visual_timeline_v10_3_2` | APROVADO |
| regression | `test_pair_rotation_visual_v10_3_3` | APROVADO |
| regression | `test_power_facet_v10_3_4` | APROVADO |
| regression | `test_animation_v8` | APROVADO |
| regression | `test_art_v9` | APROVADO |
| regression | `physics` | APROVADO |
| regression | `chains` | APROVADO |
| regression | `showcase_ui` | APROVADO |
| regression | `character_select_ui` | APROVADO |
| regression | `match_flow_visual` | APROVADO |

## Desempenho e preservação

Na rodada anterior à correção das faixas, atualização CPU da apresentação: mediana **73 µs**, P95 **139 µs**, máximo **559 µs**. Referência histórica renderizada no mesmo ensaio: mediana 59 µs. A referência usa apresentação anterior, portanto a diferença não isola apenas o custo do HUD.

Na mesma rodada anterior, redraw com duas viewports e sincronização: mediana 4,616–5,713 ms nos cenários; P95 máximo 8,603 ms. Não é tempo isolado de GPU nem promessa de FPS; houve regressões concorrentes durante parte da coleta. Não foi executado novo benchmark isolado em outras plataformas.

Hashes de **20 arquivos protegidos idênticos**, incluindo todos os `.gd` do núcleo, HUD Presenter e arquivos de vidro/VFX. Método de desenho NEXT e constantes NEXT comparados ao commit-base e idênticos. Chamadas a `get_next_colors` preservadas. Sem mudanças em mecânicas, RNG, física, turnos, score, ataques ou explosões aprovadas.

## Evidências reais

Galeria: `C:\Projetos\CS-Puzzle-Fighter-96\relatorios\v11_5\GALERIA_V11_5.html`.

Capturas produzidas pelo Godot (paths relativos a esta pasta):
- `evidence/hud5/warning_counters/danger_99_after.png`: P1=125 limitado a99 e P2=6; estado de teste configurado, não partida natural.
- `evidence/hud5/warning_counters/danger_pulse_after.png`: outra fase da pulsação.
- `evidence/hud5/warning_counters/resolution_1280_after.png`: resolução alternativa.
- `evidence/hud5/combo_3/wave_03_flash_after.png`: terceira onda real.
- `evidence/hud5/combo_5/wave_05_flash_after.png`: quinta onda real e produção bruta.
- `evidence/hud5/simultaneous/02_flash_after.png`: P1/P2 simultâneos.

Foram inspecionadas visualmente capturas do aviso e do combo; nenhuma aprovação artística é inferida dos testes. As capturas usam a configuração padrão do jogo (vidro desligado). Os arquivos e configurações da V11.4.2 não foram alterados.

## Falhas encontradas e corrigidas

A primeira rodada falhou porque a fixture histórica da arena não implementa o renderer V11.5 e porque o próprio teste atribuiu array não tipado a `pending`. Corrigidos o guard de compatibilidade e a fixture. A comparação V10 do NEXT também precisou reconhecer os novos retângulos do HUD e sua borda externa. Logs iniciais foram preservados em pastas separadas; os resumos finais referem-se aos resultados corrigidos.

## Pendências

1. Expor envio líquido em etapa posterior autorizada; nesta execução ENVIADAS continua `--`. Histórico de recebidas efetivamente colocadas também não está exposto; o campo implementado é a fila **A RECEBER**.
2. Aprovação visual pelo usuário dos painéis, WARNING e detalhes dos combos.
3. Web/móvel e desempenho isolado de GPU não executados nesta etapa.

Não foi iniciada V11.6. Não criar commit sem nova autorização.

## Correção de fidelidade dos ataques recebidos

As duas filas foram testadas independentemente em 0, 1, 6, 10, 11, 30, 31, 99, 100 e 250. Uma pilha alta com fila zero mantém o aviso de ataques apagado. As capturas de estados controlados mostram os dois poços no mesmo quadro do Godot Compatibility.

| Captura | P1 | P2 |
|---|---|---|
| [Abrir PNG](evidence/hud5/warning_counters/danger_99_after.png) | 99 DANGER (fila 125) | 06 CAUTION |
| [Abrir PNG](evidence/hud5/warning_counters/pair_10_11_after.png) | 10 CAUTION | 11 WARNING |
| [Abrir PNG](evidence/hud5/warning_counters/pair_30_31_after.png) | 30 WARNING | 31 DANGER |
| [Abrir PNG](evidence/hud5/warning_counters/pair_0_99_after.png) | 00 apagado | 99 DANGER |

Na rodada corrigida, a atualização da apresentação teve mediana de 73 µs e P95 de 143 µs. Os 20 hashes protegidos conferem com a base registrada.

Aprovação visual da V11.5 confirmada pelo usuário para checkpoint local.
