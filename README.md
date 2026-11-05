# Counter-Strike Puzzle Fighter '96 — duelo local e laboratório

**V10: auditoria final aprovada no escopo funcional medido, com ressalvas.** V10.1, V10.2 e V10.3.1–V10.3.4 estão concluídas na branch `feature/v10-gem-physics`. O checkpoint publicado e auditado é `4575f17a706d91df3ff009fb8b4d96d0cba06699`. As correções finais e o encerramento documental estão concluídos, com registro do checkpoint autorizado nesta etapa; **v0.10.0 aguarda publicação autorizada**, sem push, merge ou tag.

Execute `Jogar.cmd` com o Godot 4.7.2 portátil disponível em `ferramentas/godot_4.7.2`. A moeda sorteia CT/TR; cada jogador escolhe um agente do lado atribuído, e os lados ficam fixos até alguém vencer dois rounds. Veja [controles, seleção e Coin Flip](README_COIN_FLIP.md). SAS e Phoenix têm arte própria; seis agentes usam representações temporárias identificadas.

A V10 integra física temporal das gemas, contato e depósito, queda independente, cadeias e Counter Gems quadro a quadro. A apresentação acompanha a simulação, evita o Ghost Gem Flicker nos casos testados e usa oito passos orbitais de rotação e fases internas Power A→B→C→D→C→B→A por célula/região. Isso preserva o jogo CS e os comportamentos medidos; **não certifica equivalência visual ou de RNG integral ao MAME**.

## Auditoria final da V10

Resultados executados na auditoria de 03/11/2026 no checkpoint acima; não foram reexecutados nesta preparação documental:

| Validação | Resultado |
|---|---|
| Física temporal | 112/112 cenários; 14.072/14.072 amostras |
| Combos/Counter Gems | 22/22 cenários; 5.066/5.066 amostras; 54 verificações |
| Fidelidade / controles / naturais | 247/247; 33/33 e 866 amostras RNG; 119/119 endpoints |
| Regras / Python | 34 verificações / 17 testes |
| V10.3.2 / V10.3.3 / V10.3.4 | 123.863 / 119.052 / 394 verificações |
| Power Gems | 181 pares/1.407 verificações estruturais; 1.192 amostras de células compatíveis com MAME |
| Rotação recapturada | 340 registros válidos; 80 pares MAME sem diferenças de máscara |
| Séries MD3 integradas | 1.000/1.000; 2.500 rounds; 51.000 verificações |
| Janela real com adaptador | 4/4 séries; dez rounds; 276 verificações |
| Baterias existentes / cenas | 17/17 baterias; quatro cenas no smoke aprovadas |

As **1.000 séries usam desfechos controlados por fixtures de top-out**, passando pelo resolvedor e pelo fluxo de Coin Flip, seleção, rounds e placar. Não são 1.000 partidas naturais completas jogadas só por entradas nem sincronizadas integralmente ao MAME. As 119 fixtures naturais verificam endpoints preservados; o teste de duelo separado percorreu 1.500 turnos gerados.

**Executor gráfico corrigido:** `python scripts/validar_fluxo_partidas.py --visual --output <saida_nova>` agora seleciona `godot/tests/test_match_flow_visual_v10_3_4.gd`; `--movie` também usa esse adaptador. Ele acrescenta espera de 0,25 s após a captura do resultado da moeda, preservando as asserções. O executor corrigido passou em janela real: 4/4 séries, dez rounds, 276 verificações e 30 capturas. O lote headless mantém o teste histórico. **Executado isoladamente com `--visual`, o teste histórico `test_match_flow.gd` continua falhando** por confirmar antes da guarda de 0,2 s após a revelação; foi preservado para referência, sem alterar a temporização do jogo.

**Validadores corrigidos e testados em 04/11/2026:** o validador físico agora exige os 112 cenários esperados e suas 14.072 amostras; o estrutural Power exige os 181 pares cenário/frame. Entradas vazias ou incompletas, duplicatas e arquivos/metadados inválidos são rejeitados com saída 1 e mensagens claras. As fixtures originais foram preservadas. A suíte Python passou de 17 para 28 testes (11 métodos novos com subcasos); os conjuntos completos e as regressões principais da V10 passaram. A aprovação indevida de entradas vazias permanece registrada na auditoria de 03/11 como falha anterior, encerrada pelo complemento de correções. Permanecem 73 avisos herdados na validação nativa, incluindo 11 avisos do lint, sem erros. Não foram reexecutados testes neste encerramento exclusivamente documental.

O RNG tem a transição aritmética observada validada, mas não todos os consumidores globais CPS-2. O stream de cores/Crash ainda usa o gerador do Godot com seed fixa 96; Diamond aparece a cada 25ª dupla. Os casos medidos não certificam o gerador completo de peças do arcade. A arte CS difere da nativa e permanecem limites de explosões, cores/geometrias de ligação e P2; máscara igual não significa RGB igual nem fidelidade visual integral.

[Correções finais e resultados de 04/11](relatorios/v10_final/RELATORIO_CORRECOES_FINAIS_V10.md) · [Continuidade](CONTINUIDADE_PROJETO.md) · [Auditoria de 03/11](relatorios/v10_final/RELATORIO_AUDITORIA_V10.md) · [Resumo da auditoria](relatorios/v10_final/summary.json) · [Preparação documental anterior](relatorios/v10_final/ENCERRAMENTO_DOCUMENTAL_V10.md) · [Arquitetura atual](ARQUITETURA_GODOT.md)

A tabela acima e os relatórios anteriores preservam os resultados de suas datas. O complemento de 04/11 e a continuidade registram o fechamento técnico das pendências. As declarações de índice vazio, HEAD e autorizações nesses registros descrevem o instante de cada etapa; o registro do checkpoint final foi autorizado posteriormente, sem autorizar publicação.

## Ferramentas e dependências locais

As ferramentas Python usam a biblioteca padrão, Python 3.11 ou superior, para analisar observações/dumps de *Super Puzzle Fighter II Turbo* no MAME 0.289. O MAME não é necessário para executar o duelo Godot. O executável portátil local, ROMs, save states, dumps, caches e capturas do laboratório não integram esta preparação documental.

Comparações completas ainda dependem das coletas locais ignoradas em `laboratorio/` e de caminhos de sessões documentados. O gerador de overlays Power contém diretório absoluto; os 12 sprites próprios necessários ao jogo já estão versionados e não precisam ser regerados. Não se certificou um novo instalador ou binário exportado independente.

Para novas análises, use diretórios de saída inéditos e preserve as evidências existentes. Alguns testes legados gravam resultados em caminhos fixos mesmo quando um executor recebe outra pasta de saída; a auditoria guardou/restaurou esses bytes. A automação está em [README_AUTOMACAO.md](README_AUTOMACAO.md). Relatórios V4, V5 e V9 são históricos e não substituem o estado V10 registrado acima.

## Histórico V9 — fechamento em v0.9.0

Esta seção preserva o registro e os resultados do fechamento da V9, anteriores
à V10. A tag `v0.9.0` aponta para `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`,
sobre a base de jogo validada `2daf6aea9dc0992f2aa9bd81a26ffa8cae845490`.
Os dados e referências abaixo são históricos; o estado corrente e os resultados
da auditoria V10 estão na seção inicial e no relatório final vinculado acima.

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
