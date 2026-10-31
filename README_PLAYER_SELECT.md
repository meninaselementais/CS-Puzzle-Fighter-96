> Atualização: o fluxo atual começa com Coin Flip e permite somente CT contra TR.
> As instruções abaixo registram a primeira versão da seleção. Consulte
> `README_COIN_FLIP.md` para a regra atual e a melhor de três.

# Player Select — primeira versão funcional

Execute `Jogar.cmd`: o jogo abre na seleção. Os dois jogadores podem escolher
qualquer agente, inclusive o mesmo. Não há restrição de equipe no duelo local.

| Jogador | Mover | Confirmar | Desconfirmar |
| --- | --- | --- | --- |
| P1 | Setas | Z | X |
| P2 | W/A/S/D | Q | E |

ESC desconfirma ambos na seleção. Quando ambos confirmam, um anúncio de um segundo
inicia a partida. Na partida, ESC abre o menu; selecione **Selecionar personagens**
com o mouse ou com setas e Enter. As escolhas anteriores ficam destacadas, mas
precisam ser confirmadas novamente. R reinicia o duelo com os mesmos personagens.
Os controles de queda, rotação, cenários, replay e F4 foram preservados.

## Personagens e padrões

| Padrão | CT | TR | Índice original |
| --- | --- | --- | --- |
| A | SAS | Phoenix | 2 |
| B | FBI | Profissional | 3 |
| C | SEAL Team 6 | Palhaço | 0 |
| D | GIGN | Guerrilheiro | 1 |

Os índices apontam para as tabelas existentes em `godot/data/attack_profiles.json`.
Não foram inventadas novas cores nem modificadas as oito permutações de entrega.
A quantidade, cancelamento, gravidade, C4, Crash Orbs, pontuação e vitória continuam
usando o motor original. A escolha altera apenas `model.character_ids`.

Os quatro padrões já têm casos de entrega nas fixtures derivadas do MAME. A tabela
foi exportada por `scripts/exportar_fidelidade.py`, de
`laboratorio/auto_20261028_230219_781771/attack_tables.bin`, SHA-256
`0133d7f3390397410e62634b52937e9b8f072c1da4347fc253b7ac7737a53dd4`.
Esse arquivo bruto local foi conferido com o hash registrado. O rótulo A–D e a
associação aos personagens de CS são escolhas deste projeto, não nomes do arcade.
A prévia mostra as seis primeiras linhas de uma tabela de doze, na ordem de envio;
linhas parciais usam as permutações existentes. Equivalentes CT/TR acessam o mesmo
objeto de dados. O padrão A agora é compartilhado por SAS e Phoenix; antes do menu,
o duelo fixo usava os índices 2 e 3 respectivamente.

## Arte e animação

SAS e Phoenix usam os PNGs e as sequências originais, incluindo Phoenix V9.
Eles podem aparecer em qualquer lado, espelhados com os pontos de emissão juntos.

FBI, SEAL Team 6, GIGN, Profissional, Palhaço e Guerrilheiro ainda precisam de
sprites, retratos e animações definitivos. Nesta versão são silhuetas vetoriais
sem rosto, com identificação TEMP / ARTE TEMPORARIA. Na partida usam uma pose
temporária e os relógios de ação e efeitos existentes da equipe. Não são novos
pacotes de animação quadro a quadro nem rostos reaproveitados de SAS/Phoenix.

## Organização e futuro 2x2

- `core/character_catalog.gd`: oito definições, referências de arte/animação e estilo.
- `data/character_patterns.json`: associação configurável A–D às tabelas verificadas.
- `core/selection_state.gd`: até quatro cursores e confirmações independentes;
  transporte de IDs entre cenas; aplicação dos índices na partida.
- `presentation/player_select.gd`: interface, teclado, confirmação e transição.

As definições não contêm nickname, patente, vitórias, XP ou inventário. Nenhum
backend, conta, matchmaking ou jogo 2x2 foi implementado. O transporte é local
em memória; reiniciar o aplicativo restaura SAS/Phoenix como seleção inicial.

## Verificação

```powershell
python -B scripts/validar_apresentacao.py --render
```

Esse comando inclui os testes antigos e os novos. Os testes de interface usam
eventos reais de teclado no viewport Godot, verificam os dois percursos
seleção → partida → menu → seleção e capturam o framebuffer OpenGL em 1000×700.
Os testes de personagens conferem os oito IDs nos dois lados, as animações,
as quatro equivalências, todas as oito permutações, entregas parciais e as doze
linhas completas. Eles também conferem quatro seleções independentes para o futuro.

Logs, `summary.json` e capturas ficam em `relatorios/player_select/final/`.
Os resultados de fidelidade são comparações com as fixtures existentes, não uma
nova prova de partidas completas MAME/Godot sincronizadas quadro a quadro.

Nenhum commit é feito por esses scripts.
