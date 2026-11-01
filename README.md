# Counter-Strike Puzzle Fighter '96 — duelo local e laboratório

Versão atual: **Coin Flip + seleção CT contra TR + melhor de três rounds**.
Execute `Jogar.cmd`: a moeda sorteia os lados antes da seleção. Cada jogador
escolhe apenas agentes da equipe sorteada. Os lados ficam fixos até alguém
vencer dois rounds. Veja `README_COIN_FLIP.md` para controles, testes e limites.

A última base de fidelidade preservada tem **247/247** comparações controladas, **33/33** de controles e **119/119** endpoints de partidas naturais. A seleção não altera o núcleo, a C4, as Crash Orbs nem a quantidade de ataques. SAS e Phoenix mantêm a arte e as animações existentes; seis agentes usam silhuetas temporárias identificadas. A cronologia completa do arcade e o gerador de peças continuam com os limites documentados em `README_FIDELIDADE_V5.md`. Os relatórios V4 abaixo são históricos.

Ferramentas de análise para os dumps de RAM do Super Puzzle Fighter II Turbo no MAME 0.289. Python 3.11 ou superior; somente biblioteca padrão. Os arquivos do MAME são abertos para leitura. Cada execução exige uma pasta de saída nova e recusa sobrescrever resultados existentes.

A automação está em `README_AUTOMACAO.md`; o Godot está descrito em `ARQUITETURA_GODOT.md`. O relatório `relatorios/automacao_20261028_consolidada/RELATORIO.md` preserva a validação anterior de 25 casos de movimento, mapa X/Y, deslocamento vertical, orientações e cores. As investigações iniciais continuam preservadas.

## V9 — validação concluída; fechamento v0.9.0 preparado

A base validada é o commit `2daf6aea9dc0992f2aa9bd81a26ffa8cae845490`.
O fechamento acrescenta documentação e evidências em texto; não altera motor
lógico, animações ou mecânicas. A criação do commit e da tag anotada `v0.9.0`
depende da autorização do responsável. A V10 não foi iniciada.

| Validação preservada | Resultado |
|---|---|
| Integração lógica | 1.000/1.000 partidas, 2.500 rounds, 51.000 verificações, zero falhas |
| Fidelidade / controles / partidas naturais | 247/247, 33/33 e 119/119 |
| Regras / Python | 34/34 e 17/17 |
| Windows gráfico, Godot 4.7.2 | 4/4 partidas, 10 rounds, 276 verificações, zero falhas na repetição |
| Replay MAME original / arte V9 | Aprovado / 102 verificações aprovadas |
| Cenários e fluxo visual | Dust2, Mirage, Inferno, Coin Flip, seleção, 1×1, terceiro round, 2×0 e 2×1 aprovados |

Os resultados lógicos anteriores estão preservados em
[`bulk/summary.json`](relatorios/rounds_integration/bulk/summary.json) e
[`regression/summary.json`](relatorios/rounds_integration/regression/summary.json).
Não foram repetidas as 1.000 partidas no fechamento.
O [relatório visual Windows](relatorios/rounds_integration/visual_final_v9/RELATORIO_FINAL_V9.md)
registra a execução gráfica e suas limitações. As quatro séries usam fixtures
de top-out pelo resolvedor original, não quatro partidas naturais completas;
os eventos de gamepad são simulados, sem teste de controle físico.

**Falha inicial preservada:** o teste original pressionou Enter antes de terminar
a guarda de 0,2 segundo após a revelação da moeda, falhando na transição para
a seleção. Uma cópia de validação,
[`test_match_flow_windows.gd`](relatorios/rounds_integration/visual_final_v9/test_match_flow_windows.gd),
acrescentou uma espera de 0,22 segundo após capturar o resultado. Essa cópia
concluiu as quatro partidas sem retirar asserções. O teste original permanece
intacto e sujeito à falha de temporização. Os registros da tentativa falha e
da repetição aprovada estão em `four_matches/` e `four_matches_retry/`.

As 51 capturas, incluindo duas da janela nativa do Windows, permanecem locais
em `relatorios/rounds_integration/visual_final_v9/`, com manifesto SHA-256.
As imagens, assets, ROMs, ferramentas e caches não integram este commit de
fechamento. Consulte o [registro de preparação](relatorios/rounds_integration/visual_final_v9/FECHAMENTO_V9.md)
para integridade, arquivos preparados e escopo da conferência de publicação.

## Repetir as comparações

No PowerShell, na pasta do projeto:

```powershell
Set-Location 'C:\Projetos\CS-Puzzle-Fighter-96'
python .\scripts\comparar_memoria.py 'C:\MAME\pedra_antes.bin' 'C:\MAME\pedra_depois.bin' --validar-csv 'C:\MAME\movimento_pedra.csv' --out '.\resultados\pedra_nova_execucao'
python .\scripts\comparar_memoria.py 'C:\MAME\memoria_inicial.bin' 'C:\MAME\memoria_depois.bin' --validar-csv 'C:\MAME\comparacao_memoria.csv' --out '.\resultados\geral_nova_execucao'
python .\scripts\analisar_puzzle.py 'C:\MAME\pedra_antes.bin' 'C:\MAME\pedra_depois.bin' --out '.\resultados\grades_nova_execucao'
```

Troque a pasta após cada execução. `--validar-csv` é opcional; exige as colunas `Endereco,Antes,Depois` e confere todas as diferenças, inclusive a ordem. Os dumps devem ter exatamente 65.536 bytes. `--base` aceita um endereço como `0xFF0000`; apenas a ferramenta de comparação permite outra base. O extrator de Puzzle Fighter assume `0xFF0000`.

`comparar_memoria.py` exporta:

- `bytes.csv`: bytes diferentes e, quando fornecido, comparação com o controle;
- `palavras_16be.csv`: palavras alinhadas em endereços pares, valores com e sem sinal;
- `ponteiros_candidatos.csv`: janelas de 32 bits em endereços pares cujos valores caem na RAM; podem existir falsos positivos;
- `resumo.json`: contagens, páginas alteradas, caminhos e SHA-256 dos dumps.

`analisar_puzzle.py` exporta `campos.csv`, `ponteiros.csv`, `celulas.csv`, `grades.md` e `fontes.json`. As coordenadas de grade são índices hipotéticos a partir de zero, não coordenadas de tela. O extrator verifica as bordas antes de apresentar a grade como estruturalmente válida.

## Separar a ação do avanço do tempo

Depois de capturar três endpoints do mesmo estado inicial, com o mesmo número de quadros:

```powershell
python .\scripts\comparar_memoria.py '.\laboratorio\sessao_001\capturas\base.bin' '.\laboratorio\sessao_001\capturas\direita_f01.bin' --controle-depois '.\laboratorio\sessao_001\capturas\controle_f01.bin' --out '.\resultados\direita_f01'
```

Com controle, o CSV inclui a união das alterações da ação e do controle. `mudou_acao` seleciona as diferenças brutas; `difere_do_controle=1` compara os valores finais, inclusive quando ação e controle alteraram o mesmo endereço para valores diferentes. Não se elimina um endereço apenas porque ele também mudou no controle. A ferramenta não consegue verificar sozinha se as capturas vieram do mesmo estado ou se o teste foi determinístico.

## Verificar as ferramentas

```powershell
python -m unittest discover -s .\tests -v
```

Os testes cobrem endianness, interpretação com sinal, ponteiro alinhado a dois bytes, comparação com controle, geometria da grade, entradas inválidas e recusa de sobrescrita. Os dois pares reais foram analisados separadamente e conferidos contra os CSVs originais.

O diretório `Original` preexistente não faz parte destas ferramentas e não foi alterado.
