# Testes de mecânicas e comparação com o arcade

**Protocolo histórico da v3.** A versão atual e as diferenças restantes estão em `README_FIDELIDADE_V4.md` e `relatorios/fidelidade_v4/RELATORIO.md`.

Use `Jogar.cmd` para o duelo local. P1: setas e Z/X. P2: A/D/S e Q/E. R reinicia, TAB alterna o replay anterior, Espaço pausa esse replay. O modo local usa a mesma sequência provisória de duplas para os dois jogadores. As pedras quadradas numeradas são Counter Gems; os círculos com cruz são Crash Gems; retângulos unidos são Power Gems.

## Reproduzir os ensaios

No PowerShell, na pasta do projeto:

```powershell
$estado = '.\laboratorio\auto_20261028_155033_010970\sta\spf2tu\baseline.sta.sta'
python -B .\scripts\automatizar_mame.py --lua .\lua\mecanicas.lua --state $estado --debug
```

O executor imprime uma pasta nova. O estado é copiado, a entrada fica neutra por três quadros antes de cada restauração e os 81 casos partem da mesma origem. A Lua injeta somente as células necessárias na RAM da cópia emulada, com cada escrita registrada em `injection.csv`. Esse procedimento testa o resolvedor do arcade com configurações controladas; não prova a frequência natural dessas configurações numa partida completa. Nenhuma ROM é modificada.

Após duas execuções, substitua os nomes abaixo pelas pastas impressas e escolha destinos novos:

```powershell
python -B .\scripts\verificar_repeticao_mecanicas.py '.\laboratorio\auto_PRIMEIRA' '.\laboratorio\auto_SEGUNDA' --out '.\relatorios\nova_repeticao.json'
python -B .\scripts\exportar_mecanicas.py '.\laboratorio\auto_PRIMEIRA' --out '.\relatorios\novas_fixtures.json'
```

O verificador exige Lua e estado inicial idênticos, compara todos os dumps e o CSV por hash e reconfere as fontes. O exportador recusa sessões inválidas e sobrescrita. Antes de trocar as fixtures do Godot, preserve a versão anterior; copie o JSON aprovado para `godot/data/mechanics_fixtures.json`.

## Verificação do protótipo

```powershell
python -B -m unittest discover -s .\tests -v
$godot = '.\ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path .\godot --script res://tests/test_models.gd
& $godot --headless --path .\godot --script res://tests/test_rules.gd
& $godot --headless --path .\godot --script res://tests/test_duel.gd
& $godot --headless --path .\godot --script res://tests/test_fidelity.gd
& $godot --path .\godot --script res://tests/render_mechanics.gd --quit-after 120
```

O teste de fidelidade escreve `relatorios/fidelidade_v3/comparacao.json` e retorna **1 enquanto houver diferenças**. Nesta entrega são seis diferenças conhecidas de distribuição nas linhas incompletas. Não interprete esse retorno como aprovação integral. Os demais testes devem passar. Verifique também os logs por `SCRIPT ERROR`/`ERROR`: o Godot pode terminar com código zero após um erro de script.

## Depuração controlada

Compare um fator por vez: tamanho/forma do retângulo, cor, contato ortogonal/diagonal, Counter adjacente, suporte de apenas uma borda, dois componentes simultâneos ou segunda onda após a gravidade. Use o ramo `control` e o mesmo número de quadros. Preserve `source`, `seed`, a entrada lógica, o CSV por quadro, o endpoint de RAM e a imagem após atualização de vídeo.

`board_writers.csv` registra endereço, dado, máscara, PC e A6 com taps de escrita; os taps são reinstalados após restaurar o estado. Para aprofundar, coloque no depurador breakpoints nos PCs observados e watchpoints de escrita nos endereços candidatos. Avance poucos quadros, anote registradores e pilha e repita a restauração. A alteração gráfica de um byte não prova, sozinha, uma regra lógica. O tap experimental de pontuação não produziu evidência de escritor nesta rodada e não fundamenta as fórmulas.

Próximo teste prioritário: manter a fila e o momento de entrega constantes, variar somente a quantidade residual de 1 a 5 e rastrear a seleção de colunas. Depois testar continuidade do padrão de Ken entre ataques, forças ímpares de contra-ataque, três componentes simultâneos, cadeia de três ondas e perda durante a resolução de dois ataques simultâneos.
