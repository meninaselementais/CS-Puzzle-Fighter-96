# Reproduzir a validação v4

O jogo continua em `godot/`, iniciado por `Jogar.cmd`. Os controles permanecem iguais. A versão anterior e os relatórios v3 foram preservados.

## Ensaios do arcade

No PowerShell, na pasta do projeto:

```powershell
$estado = '.\laboratorio\auto_20261028_155033_010970\sta\spf2tu\baseline.sta.sta'
python -B .\scripts\automatizar_mame.py --lua .\lua\fidelidade.lua --state $estado --debug
python -B .\scripts\automatizar_mame.py --lua .\lua\residuos.lua --state $estado --debug
python -B .\scripts\automatizar_mame.py --lua .\lua\tempos.lua --state $estado --debug
python -B .\scripts\automatizar_mame.py --lua .\lua\rng.lua --state $estado --debug
python -B .\scripts\automatizar_mame.py --lua .\lua\partidas.lua --state $estado --debug
```

Cada comando imprime uma pasta nova, com cópias verificadas, entradas neutras antes da restauração e logs. `fidelidade.lua` amplia a bateria de mecânicas; `residuos.lua` ensaia oito permutações × 17 quantidades e 11 IDs de personagem; `tempos.lua` mede controles e rotação; `rng.lua` usa breakpoints de entrada/saída; `partidas.lua` conduz três trechos de 2.400 quadros com entradas lógicas, sem injetar células, filas ou personagens.

Nos testes sintéticos, as mudanças de RAM pertencem somente à cópia emulada. Na varredura de resíduos, a fila real de saída é ajustada no byte do emissor `+019E` e o seletor do receptor em `+037B`; mudar apenas a fila visual não cria um ataque. As configurações sintéticas são entradas explícitas dos testes, não resultados esperados.

Os estados completos, ROMs e binários permanecem no laboratório local; o pacote de código não os redistribui.

## Exportar observações

Substitua as pastas pelos caminhos impressos e escolha um destino novo:

```powershell
python -B .\scripts\exportar_fidelidade.py --mechanics '.\laboratorio\SESSAO_MECANICAS' --delivery '.\laboratorio\SESSAO_RESIDUOS' --timing '.\laboratorio\SESSAO_TEMPOS' --rng '.\laboratorio\SESSAO_RNG' --out '.\relatorios\nova_exportacao'
python -B .\scripts\exportar_partidas.py '.\laboratorio\SESSAO_PARTIDAS' --out '.\relatorios\novas_partidas.json'
```

Os exportadores recusam sessões inválidas e destinos existentes. Preserve a versão anterior antes de copiar os três JSONs exportados para `godot/data/` e as partidas para `godot/data/natural_fixtures.json`. Os JSONs contêm caminhos, hashes e estados de entrada usados nas comparações. Não preencha o seletor de uma fixture com o valor que faria seu resultado passar: importe o byte observado antes da entrega.

Para duas repetições de `fidelidade.lua` com a mesma Lua e o mesmo estado:

```powershell
python -B .\scripts\verificar_repeticao_mecanicas.py '.\laboratorio\PRIMEIRA' '.\laboratorio\SEGUNDA' --out '.\relatorios\nova_repeticao.json'
```

Para `residuos.lua`/`partidas.lua`, compare também os CSVs e os snapshots correspondentes por SHA-256. Os nomes dos snapshots naturais incluem o quadro porque o marcador de dupla pode voltar a valores anteriores.

## Testar o protótipo

```powershell
python -B -m unittest discover -s .\tests -v
$g = '.\ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $g --headless --path .\godot --script res://tests/test_models.gd --quit-after 120
& $g --headless --path .\godot --script res://tests/test_rules.gd --quit-after 120
& $g --headless --path .\godot --script res://tests/test_duel.gd --quit-after 120
& $g --headless --path .\godot --script res://tests/test_fidelity.gd --quit-after 120
& $g --headless --path .\godot --script res://tests/test_controls_fidelity.gd --quit-after 120
& $g --headless --path .\godot --script res://tests/test_natural_fidelity.gd --quit-after 120
& $g --path .\godot --script res://tests/render_mechanics.gd --quit-after 120
```

O teste natural retorna **1** nas sete divergências conhecidas desta entrega. As falhas permanecem em `relatorios/fidelidade_v4/partidas.json`. Os demais testes devem passar. Confira `SCRIPT ERROR` e `ERROR` nos logs, além dos códigos de saída; erros de script podem terminar com código zero no Godot.

O próximo passo de sincronização requer registrar e reproduzir eventos de chegada de ataques e de bônus durante cada intervalo de resolução. Usar somente a fila existente no começo do turno não representa ataques enviados pelo outro jogador enquanto esse turno ainda está sendo resolvido. A Diamond Gem também precisa de uma bateria própria antes de receber uma regra geral.
