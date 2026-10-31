# Coin Flip, equipes e melhor de três

Execute `Jogar.cmd`. O fluxo é **Coin Flip → seleção restrita → partida MD3**.

## Sorteio

O resultado é calculado uma vez antes do primeiro quadro da moeda, com um RNG
independente do gerador de gemas. As duas distribuições CT/TR têm probabilidade
de 50%. Uma nova partida pode repetir os mesmos lados; não há alternância forçada.

A apresentação usa arte própria desenhada no Godot: moeda dourada com face de
escudo CT e face de lâminas cruzadas TR, rotação, salto, sombra e placas de resultado.
Dois WAVs sintetizados acompanham o lançamento e a revelação. São recursos locais;
nenhuma imagem ou música de terceiros foi adicionada nesta etapa.

Z/Q, Enter, Espaço, A ou Start pulam a rotação e mostram o resultado já definido.
Após a breve revelação, outra confirmação continua; sem entrada, a transição é
automática. O sorteio não é refeito ao pular a apresentação.

## Seleção

| Equipe sorteada | Personagens disponíveis |
| --- | --- |
| CT | SAS, FBI, SEAL Team 6, GIGN |
| TR | Phoenix, Profissional, Palhaço, Guerrilheiro |

Os oito retratos continuam visíveis. Cada linha e cartão identifica o jogador
autorizado. A navegação vertical não muda de equipe. Escolha direta, confirmação,
salvamento e entrada na cena da partida validam os dados novamente.

P1: setas, Z confirma e X desconfirma. P2: W/A/S/D, Q confirma e E desconfirma.
Controles com IDs 0 e 1 correspondem a P1 e P2: D-pad/analógico navegam, A confirma,
B desconfirma. O analógico possui zona morta e exige retorno ao centro antes de
outro passo na mesma direção. ESC/Start desconfirma ambos na seleção.

Os quatro padrões permanecem inalterados: A SAS/Phoenix, B FBI/Profissional,
C SEAL Team 6/Palhaço e D GIGN/Guerrilheiro. A seleção muda somente os índices
das tabelas existentes; nenhuma regra das gemas foi alterada.

## Rounds e nova partida

Vence quem conquistar dois rounds. Equipes, personagens e padrões ficam fixos
durante toda a partida. Após o round, R ou A no controle inicia o próximo. No
2–0 ou 2–1, a partida termina; R/A inicia um novo sorteio. Empates repetem o round,
sem ponto para ninguém e sem mudar os lados.

R durante um round em andamento mantém a função de reiniciar aquele round, sem
zerar os rounds já conquistados e sem novo sorteio. ESC/Start abre o menu:
**Nova partida / sortear lados** abandona a partida atual e passa pela moeda.

Os comandos anteriores de teclado e o laboratório F4 permanecem disponíveis.
O laboratório é uma demonstração isolada e não registra rounds. Ao voltar dele,
os lados e o placar da série permanecem; o tabuleiro do round é reiniciado, como
na troca de cena anterior.

## Estrutura e limites

- `core/match_session.gd`: resultado do sorteio, grupos, identidades e série MD3.
- `core/selection_state.gd`: restrições de equipe e validação de entrada.
- `presentation/selection_input.gd`: comandos comuns de teclado e controle.
- `presentation/coin_flip.gd` e `coin_flip.tscn`: apresentação e áudio.

`accept_server_assignment(first_team_ct, groups)` recebe uma distribuição pronta
sem consumir RNG local. `groups=[0,1]` representa 1x1 e `[0,0,1,1]` representa
duas equipes de dois jogadores. Os membros de cada grupo recebem o mesmo lado.
Essa é uma estrutura local preparada para integração futura, sem transporte,
autenticação, backend ou 2x2 jogável. Uma seleção de quatro jogadores não pode
entrar na partida atual de dois tabuleiros.

FBI, SEAL Team 6, GIGN, Profissional, Palhaço e Guerrilheiro continuam com arte
e animações temporárias claramente identificadas.

## Testes

```powershell
python -B scripts\validar_apresentacao.py --render
```

Os relatórios e as capturas ficam em `relatorios/coin_flip/final/`.
O novo teste usa 20.000 sorteios e verifica equivalência dos padrões, bloqueio
de equipe por navegação e confirmação, prevenção de entrada inválida, rounds,
2–0/2–1/empates, nova partida e agrupamento futuro 2x2. A interface é exercitada
com eventos de teclado e de controle enviados ao viewport real do Godot, em duas
dimensões de janela. Os testes não substituem uma sessão com controle físico.

Nenhum commit ou push é executado pelos testes.
