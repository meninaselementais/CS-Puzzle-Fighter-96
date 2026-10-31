# Counter-Strike Puzzle Fighter '96 — duelo local e laboratório

Versão jogável atual: execute `Jogar.cmd`. Dois jogadores locais, Power Gems, Crash Gems, Counter Gems, combos, cadeias, gravidade, pontos, ataques e vitória/derrota. P1: setas e Z/X; P2: A/D/S e Q/E; R reinicia. Segure a tecla de queda para acelerar.

O relatório atual está em `relatorios/fidelidade_v4/RELATORIO.md`: **247/247** comparações controladas, **33/33** de controles e **112/119** endpoints de partidas do arcade. As seis divergências anteriores de distribuição foram corrigidas com a regra das oito permutações e o estado observado do seletor. Restam sete diferenças nas partidas: cinco de chegada assíncrona de ataques, uma do bônus de primeiro ataque e uma envolvendo Diamond Gem. A sequência completa do gerador e a sincronização das animações continuam parciais. Consulte `README_FIDELIDADE_V4.md` para reproduzir a validação.

Ferramentas de análise para os dumps de RAM do Super Puzzle Fighter II Turbo no MAME 0.289. Python 3.11 ou superior; somente biblioteca padrão. Os arquivos do MAME são abertos para leitura. Cada execução exige uma pasta de saída nova e recusa sobrescrever resultados existentes.

A automação está em `README_AUTOMACAO.md`; o Godot está descrito em `ARQUITETURA_GODOT.md`. O relatório `relatorios/automacao_20261028_consolidada/RELATORIO.md` preserva a validação anterior de 25 casos de movimento, mapa X/Y, deslocamento vertical, orientações e cores. As investigações iniciais continuam preservadas.

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
