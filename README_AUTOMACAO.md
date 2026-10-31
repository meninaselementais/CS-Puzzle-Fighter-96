# Automação MAME + Lua + Python

O movimento e as cores estão validados em **`relatorios/automacao_20261028_consolidada`**. As mecânicas e diferenças atuais estão em **`relatorios/fidelidade_v4`** e no protocolo `README_FIDELIDADE_V4.md`. A v3 e seus ensaios permanecem como histórico.

## Executar novamente

Requer Python 3.11+ e os arquivos locais já existentes em C:\MAME. A primeira execução copia o executável 0.289 e as ROMs spf2t, spf2tu, qsound e qsound_hle para o laboratório. As execuções seguintes conferem seus SHA-256 e recusam cópias divergentes.

```powershell
Set-Location 'C:\Projetos\CS-Puzzle-Fighter-96'
python -B .\scripts\automatizar_mame.py --lua .\lua\experimentos.lua --debug
```

O programa informa uma pasta nova `laboratorio/auto_DATA_HORA`. A Lua faz o boot, insere créditos, inicia os jogadores em sequência, confirma as seleções, cria um estado salvo e executa 25 ramos de teste. As entradas físicas desses controles são removidas somente na configuração copiada da sessão. As entradas usadas nos testes são lógicas, sem escrever valores na RAM do jogo.

O modo padrão não abre janela. `--video gdi` permite observar uma janela nativa, mantendo a mesma automação. Cada execução possui limite de tempo real, limite de quadros, marcador de conclusão, logs e conferência das fontes. Erros Lua invalidam a execução mesmo se o processo do MAME terminar com código zero.

Depois, usando o caminho que o executor imprimiu e um destino novo:

```powershell
python -B .\scripts\avaliar_sessao.py '.\laboratorio\auto_DATA_HORA' --out '.\relatorios\minha_nova_validacao'
```

O avaliador recusa sessões incompletas, erros Lua, estados iniciais diferentes e cache de entradas não neutro. Ele compara repetições, verifica os dois jogadores, rotação, limites, assentamento e correspondências entre os IDs da RAM e as cores dos pixels. Exporta `validacao.json`, `evidencias_cores.csv` e `replay_mame.json`.

Para atualizar o visualizador, copie o novo `replay_mame.json` para `godot/data/replay_mame.json`. O esquema e a arquitetura estão em `ARQUITETURA_GODOT.md`.

## Arquivos de uma sessão

- `captures/*.bin`: RAM principal de 64 KiB por quadro, mais a base de cada ramo.
- `snap/*.png` e `*.argb`: imagens-chave e pixels sem compressão, após a atualização de vídeo.
- `eventos.csv`: quadros, tempo emulado, entradas e campos acompanhados.
- `escritas.csv`: observação de escritas, máscara, PC e A6; os taps não retornam valores modificados.
- `depurador.txt`: consultas ao último escritor feitas pelo depurador.
- `writer_*.asm`: trechos de disassembly do programa emulado, sem patch de ROM.
- `sta/.../baseline.sta`: estado completo usado para restaurar cada ramo.
- `execucao.json`, `experimento.lua`, `automatizar_mame.py`: comando, hashes e cópias dos scripts usados naquela execução.

## Cuidados que fazem parte do protocolo

A RAM sozinha não restaura o cache de entrada do MAME. Antes de carregar o estado, a Lua solta os controles e avança três quadros neutros. Todos os ramos devem começar com o port IN0 em FFFF. Isso elimina uma ação residual do teste anterior.

Os screenshots são coletados após a atualização de vídeo. A linha lógica, o deslocamento vertical assinado e a orientação são usados em conjunto para localizar a dupla nos pixels. A classificação de cor se aplica aos códigos normais 1–4; não é um decodificador completo de todas as pedras especiais.

O boot depende do sistema **spf2tu USA 960620**, da EEPROM copiada e dos tempos de introdução observados. Outra versão ou configuração exige recalibrar o perfil de entrada e repetir as validações. Um processo que termina não constitui, sozinho, prova de uma partida corretamente iniciada.

## Testes das ferramentas

```powershell
python -B -m unittest discover -s .\tests -v
```

Os oito testes cobrem comparação binária, endianness, controle, grades, limites de entrada, reconhecimento de cores e proteção contra sobrescrita/cópia sobre os originais. Os testes de partida e os testes Godot são verificações adicionais, com logs próprios.

MAME e Steam originais permanecem fora da área de escrita. O projeto usa EEPROM, CFG, save states, screenshots e logs próprios em cada sessão. Nenhum script instala serviços ou altera o sistema permanentemente.

Referências: [API Lua do MAME](https://docs.mamedev.org/luascript/ref-common.html), [memória](https://docs.mamedev.org/luascript/ref-mem.html), [depurador](https://docs.mamedev.org/luascript/ref-debugger.html).
