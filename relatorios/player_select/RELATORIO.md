# Counter-Strike Puzzle Fighter '96 — Player Select

Implementado em `C:\Projetos\CS-Puzzle-Fighter-96`, preservando o projeto existente.
Nenhum commit ou push foi feito nesta etapa. As mudanças estão locais e ainda não
aparecem no GitHub.

## Entrega

- O jogo inicia em PLAYER SELECT, com oito personagens e indicadores P1/P2.
- Cada jogador pode escolher qualquer agente, inclusive o mesmo do adversário.
- Destaque luminoso, confirmação visual e transição após ambos confirmarem.
- Prévia das seis primeiras linhas de Counter Gems, usando os dados da partida.
- Menu de pausa com retorno à seleção; escolhas lembradas entre cenas.
- SAS/Phoenix funcionam em qualquer lado, com sprites, animações e pontos de
  emissão espelhados em conjunto quando necessário.
- Dados de personagem separados de dados de conta; quatro seleções independentes
  preparadas em memória. O modo jogável continua sendo 1x1 local.

## Uso

Abra `C:\Projetos\CS-Puzzle-Fighter-96\Jogar.cmd`.

| Jogador | Navegação na seleção | Confirmar | Desconfirmar |
| --- | --- | --- | --- |
| P1 | Setas | Z | X |
| P2 | W/A/S/D | Q | E |

Na partida, os controles anteriores foram mantidos. ESC abre o menu; use setas e
Enter ou o mouse para selecionar **Selecionar personagens**. R mantém a escolha
e reinicia o duelo. Na seleção, ESC desconfirma ambos.

## Padrões e procedência

| Padrão | CT | Terrorista | Índice da tabela original |
| --- | --- | --- | --- |
| A | SAS | Phoenix | 2 |
| B | FBI | Profissional | 3 |
| C | SEAL Team 6 | Palhaço | 0 |
| D | GIGN | Guerrilheiro | 1 |

Os quatro índices foram reutilizados de `godot/data/attack_profiles.json` e têm
casos de entrega nas fixtures MAME existentes. Os rótulos A–D e sua associação
a personagens de Counter-Strike são decisões deste projeto.

A reexportação da fonte original `attack_tables.bin` produziu os mesmos dados.
SHA-256: `0133d7f3390397410e62634b52937e9b8f072c1da4347fc253b7ac7737a53dd4`.
Não foram inventadas novas tabelas. Quantidade, cancelamento, pontuação, velocidade,
C4, Crash Orbs e permutações de posições permanecem no motor original. O padrão A
passou a ser compartilhado por SAS/Phoenix; antes, o duelo fixo usava índices 2/3.

## Verificação executada

Comando executado no projeto original:

```powershell
python -B scripts\validar_apresentacao.py --render
```

**16 grupos aprovados**, incluindo:

| Verificação | Resultado |
| --- | --- |
| Python | 17 testes aprovados |
| Personagens/padrões/animações | 3.343 verificações aprovadas |
| Fidelidade controlada | 247/247 |
| Controles e RNG | 33/33; 866 amostras de RNG |
| Endpoints naturais | 119/119 |
| Regras | 34 verificações aprovadas |
| Duelo | 1.500 turnos / 26 partidas |
| Apresentação | 3.285 verificações aprovadas |
| Animações V8 | 145 verificações aprovadas |
| Arte V9 | 102 verificações aprovadas |
| Interface de seleção | Teclado, confirmação, cancelamento, menu e transições aprovados |
| Showcase | Seletores, pausa, C4 e ida/volta F4 aprovados |
| Renderizações anteriores | Preview, mecânicas e demonstração de cadeias/C4 aprovados |
| Inicialização padrão | Godot executado por 120 quadros, saída 0, sem erros de script |

Os testes de interface usam `Input.parse_input_event` no viewport do Godot e
capturam o framebuffer OpenGL 1000×700. Foram percorridos seleção → partida →
menu → seleção, e uma nova partida com Phoenix à esquerda e SAS à direita.
O teste de personagens cobre os oito agentes nos dois lados, todas as oito
permutações, entregas parciais, doze linhas completas e quatro cursores independentes.

Foram conferidos **130 arquivos existentes de núcleo, dados e sprites** contra o
Git anterior: PNGs comparados byte a byte; textos comparados com normalização
CRLF/LF do Git. Nenhuma regra, fixture ou PNG existente foi alterado.

Backup anterior às alterações:
`revisoes\antes_player_select_20261031_013843`.

Logs, resumo da bateria, preservação e capturas também estão no projeto em
`relatorios\player_select\final`. A documentação técnica está em
`README_PLAYER_SELECT.md`.

## Capturas reais

- [Seleção inicial](final/01_player_select.png)
- [Personagens temporários e padrão B](final/02_placeholders_pattern_b.png)
- [Confirmação](final/03_confirmation.png)
- [Partida com personagens temporários](final/04_match_placeholders.png)
- [Menu de pausa](final/05_pause_menu.png)
- [Seleção com lados invertidos](final/06_swapped_selection.png)
- [Phoenix e SAS com lados invertidos](final/07_match_swapped_sprites.png)
- [Retorno à seleção](final/08_return_selection.png)

## Arte pendente e limites

**FBI, SEAL Team 6, GIGN, Profissional, Palhaço e Guerrilheiro** ainda precisam
de retratos, sprites e animações definitivos. Usam silhuetas sem rosto,
identificadas como TEMP / ARTE TEMPORARIA, na seleção e na partida. Compartilham
os relógios de ação e efeitos existentes da equipe, com uma pose temporária;
não são pacotes novos de animação quadro a quadro.

Sem backend, contas, matchmaking ou 2x2 jogável nesta etapa. A validação de
fidelidade usa fixtures existentes e não demonstra sincronização completa
de partidas autônomas MAME/Godot quadro a quadro.
