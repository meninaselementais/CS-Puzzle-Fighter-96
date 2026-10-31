# Counter-Strike Puzzle Fighter '96 — Coin Flip e equipes obrigatórias

Implementado no projeto existente em `C:\Projetos\CS-Puzzle-Fighter-96`.
**Nenhum commit ou push foi feito.** As mudanças desta etapa estão apenas locais.

## Comportamento entregue

O jogo inicia com **Coin Flip → seleção restrita → partida melhor de três**.
A moeda tem arte própria CT/TR, rotação, salto, sombra, revelação das equipes e
dois sons sintetizados. O resultado é calculado antes do primeiro quadro;
a animação apenas o apresenta. Pular a animação não repete o sorteio.

P1 e P2 sempre recebem lados opostos. Cada um escolhe apenas os quatro agentes
da equipe sorteada. Os oito retratos permanecem visíveis, identificados com o
jogador autorizado. Navegação, escolha direta, confirmação, salvamento e entrada
na cena da partida validam os lados. Um cursor adulterado da equipe oposta é
rejeitado. A entrada direta na partida com dados inválidos volta à moeda.

| Padrão | CT | Terrorista |
| --- | --- | --- |
| A | SAS | Phoenix |
| B | FBI | Profissional |
| C | SEAL Team 6 | Palhaço |
| D | GIGN | Guerrilheiro |

As tabelas e as regras das gemas não foram alteradas. A escolha continua usando
os mesmos índices MAME: A=2, B=3, C=0, D=1.

Os lados, personagens e padrões permanecem durante todos os rounds da partida.
Vence quem conquistar dois rounds. Os encerramentos 2–0 e 2–1 foram testados.
Empates repetem o round sem ponto e sem mudança de lado. Sair do replay também
preserva o encerramento: esse atalho não permite um quarto round.

Uma nova partida faz um novo sorteio. Como cada sorteio é independente, repetir
a distribuição anterior é um resultado válido, sem alternância forçada.

## Como jogar

Execute `C:\Projetos\CS-Puzzle-Fighter-96\Jogar.cmd`.

| Etapa | Teclado | Controle |
| --- | --- | --- |
| Moeda | Z/Q, Enter ou Espaço pula a rotação e revela o resultado | A ou Start |
| Seleção P1 | Setas; Z confirma; X desconfirma | Controle ID 0: D-pad/analógico, A/B |
| Seleção P2 | W/A/S/D; Q confirma; E desconfirma | Controle ID 1: D-pad/analógico, A/B |
| Próximo round / nova partida após o fim | R | A |
| Menu durante o jogo | ESC | Start |

Após pular a rotação, o resultado permanece visível por pelo menos um breve
intervalo antes de outra confirmação continuar. Sem entrada, a transição é
automática. O analógico possui zona morta e não repete passos por jitter.

No menu, **Nova partida / sortear lados** abandona a partida e abre a moeda.
R durante um round ativo mantém o reinício daquele round, sem zerar a série
nem sortear os lados novamente. Os controles antigos de teclado foram mantidos.

## Validação executada

Comando executado na pasta original:

```powershell
python -B scripts\validar_apresentacao.py --render
```

**17 grupos aprovados**, com logs sem erros de script ou avisos de runtime nessa
bateria. Asserções e valores esperados dos testes de fidelidade foram preservados.

| Verificação | Resultado |
| --- | --- |
| Sorteios e regras de sessão | 40.195 verificações; nenhuma falha |
| Equilíbrio em 20.000 sorteios | P1 CT: 10.044 (50,22%); P1 TR: 9.956 (49,78%) |
| Personagens, padrões e animações | 3.351 verificações; nenhuma falha |
| Fidelidade controlada | 247/247 |
| Controles e RNG das gemas | 33/33; 866 amostras de RNG |
| Endpoints de partidas naturais | 119/119 |
| Regras | 34 verificações |
| Simulação de duelos | 1.500 turnos, 26 partidas |
| Regressões de apresentação | 3.285 verificações |
| Animações V8 / arte V9 | 145 / 102 verificações |
| Python | 17 testes |
| Interface real do Godot | Teclado, eventos de controle, skip/automático, confirmação, menu e transições |
| Ciclo MD3 na interface | Três rounds com lados fixos, resultado 2–1, nova partida e novo sorteio |
| Janela | Capturas em 1000×700 e janela 1280×900, com canvas escalonado |
| Áudio | Ambos os WAVs não silenciosos, sem clipping, duração e contorno verificados |

Os testes de interface enviam `InputEventKey`, `InputEventJoypadButton` e
`InputEventJoypadMotion` ao viewport real do Godot e capturam o framebuffer
OpenGL. O resultado do round foi provocado por perda de um jogador no modelo
para testar o ciclo de três rounds sem depender de uma partida manual longa.
O teste não substitui uma sessão com controle físico conectado.

Verificações adicionais da skill Godot:

- As quatro cenas passaram no smoke test com entrada aleatória, sem erros.
  A transição da moeda à seleção foi registrada como informação esperada.
- Projeto compilado: zero erros de parse, zero erros e zero avisos de configuração
  de nós. O validador completo registra 64 avisos herdados; a base anterior tinha
  70. A comparação não encontrou novos avisos introduzidos por esta etapa.
- Inicialização pela cena padrão executada em janela, com diagnóstico estruturado.
- **130 arquivos existentes de núcleo, dados e sprites preservados**, incluindo
  PNGs comparados byte a byte e textos comparados com a normalização CRLF/LF do Git.
- As quatro tabelas foram novamente conferidas com a reexportação da fonte MAME.

Os relatórios completos estão em `relatorios/coin_flip/final/` no projeto.
Backup anterior à alteração: `revisoes/antes_coin_flip_20261031_015403/`.

## Capturas reais

- [Moeda em rotação](final/01_coin_spinning.png)
- [Resultado P1 CT / P2 TR](final/02_coin_result_ct_tr.png)
- [Seleção limitada às equipes](final/03_team_locked_selection.png)
- [Confirmação dos jogadores](final/04_selection_confirmed.png)
- [Primeiro round](final/05_round_one.png)
- [Partida encerrada em 2–1](final/06_best_of_three_finished.png)
- [Resultado P1 TR / P2 CT](final/07_coin_result_tr_ct.png)
- [Seleção por eventos de controle](final/08_controller_reversed_teams.png)
- [Partida com lados invertidos](final/09_reversed_match.png)
- [Menu de nova partida](final/10_new_match_menu.png)
- [Moeda em janela maior](final/11_coin_large_window.png)
- [Seleção em janela maior](final/12_selection_large_window.png)

## Arquivos alterados ou adicionados nesta etapa

21 arquivos, relativos à raiz do projeto:

```text
godot/assets/audio/coin_flip.wav
godot/assets/audio/coin_result.wav
godot/coin_flip.tscn
godot/core/match_session.gd
godot/core/selection_state.gd
godot/presentation/coin_flip.gd
godot/presentation/main.gd
godot/presentation/player_select.gd
godot/presentation/selection_input.gd
godot/project.godot
godot/tests/render_chains_and_c4_demo.gd
godot/tests/render_mechanics.gd
godot/tests/render_preview.gd
godot/tests/test_character_select.gd
godot/tests/test_character_select_ui.gd
godot/tests/test_coin_flip.gd
godot/tests/test_showcase_ui.gd
README.md
README_COIN_FLIP.md
README_PLAYER_SELECT.md
scripts/validar_apresentacao.py
```

Os testes antigos de apresentação só receberam a preparação explícita de uma
sessão CT/TR válida. As fixtures, regras, tabelas, animações e sprites anteriores
continuam preservados. Os novos sons foram sintetizados com os utilitários da
[skill Godot](https://github.com/haxqer/godot-skill).

## Estrutura futura e limites

`match_session.gd` oferece uma entrada para receber o resultado definido pelo
futuro servidor, sem consumir RNG local. O agrupamento `[0,0,1,1]` atribui CT a
uma equipe inteira e TR à outra; quatro seleções independentes foram testadas.
Uma sessão de quatro jogadores não pode entrar no jogo atual de dois tabuleiros.
Não há backend online, comunicação de rede nem 2x2 jogável nesta entrega.

FBI, SEAL Team 6, GIGN, Profissional, Palhaço e Guerrilheiro continuam precisando
de sprites e animações definitivos, com recursos temporários identificados.
Os testes de fidelidade continuam baseados nas fixtures existentes; não representam
sincronização integral de partidas MAME/Godot quadro a quadro.
