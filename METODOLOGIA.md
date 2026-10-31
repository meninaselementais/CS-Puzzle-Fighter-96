# Testes controlados no MAME 0.289

Objetivo: distinguir coluna/linha da peça ativa, cursor de busca, posição de peça assentada, animação e contadores. Nenhum candidato exige alterar ROMs ou escrever valores na RAM emulada. Esta metodologia foi preparada; os testes interativos ainda não foram executados.

## 1. Abrir uma sessão isolada

O MAME grava CFG e NVRAM ao encerrar. Para preservar os originais, execute a sessão com diretórios próprios e sem ler os INIs originais. O comando abaixo cria uma sessão nova e redireciona os resultados. Ele abre o MAME em primeiro plano. Não o execute duas vezes sobre o mesmo diretório.

```powershell
$projeto = 'C:\Projetos\CS-Puzzle-Fighter-96'
$lab = Join-Path $projeto 'laboratorio\sessao_001'
if (Test-Path -LiteralPath $lab) { throw 'Escolha um novo nome de sessão.' }
New-Item -ItemType Directory -Path $lab -ErrorAction Stop | Out-Null
foreach ($subpasta in @('cfg','nvram','sta','snap','inp','comments','diff','capturas')) {
    New-Item -ItemType Directory -Path (Join-Path $lab $subpasta) -ErrorAction Stop | Out-Null
}
Push-Location $lab
try {
    & 'C:\MAME\mame.exe' spf2tu -noreadconfig -debug -console -window -noautosave -noplugins `
        -rompath 'C:\MAME\roms' -pluginspath 'C:\MAME\plugins' `
        -cfg_directory "$lab\cfg" -nvram_directory "$lab\nvram" `
        -state_directory "$lab\sta" -snapshot_directory "$lab\snap" `
        -input_directory "$lab\inp" -comment_directory "$lab\comments" `
        -diff_directory "$lab\diff" -homepath "$lab"
} finally { Pop-Location }
```

Essa sessão usa CFG e EEPROM novos, portanto dificuldade, controles e progresso podem diferir do ambiente habitual. Para reproduzir a EEPROM original, copie apenas `C:\MAME\nvram\spf2tu` para a pasta `nvram` da sessão antes de iniciar. Isso é opcional; não foi feito aqui. O arquivo CFG original não deve ser copiado, pois seu histórico contém comandos que salvam sobre os dumps antigos.

Os nomes das opções e os diretórios resultantes foram verificados com `mame.exe ... -showconfig`, que não inicia o jogo. A janela, o console Lua e as capturas em jogo ainda precisam de validação prática.

## 2. Fixar estado, fase e tempo

1. Inicie uma partida, preferencialmente com dois jogadores humanos para separar A/B. Deixe a peça longe das paredes e do piso. Confirme que não há entradas físicas pressionadas.
2. No depurador, use `focus maincpu` e `gvblank` para sincronizar com o início do intervalo vertical. Salve o estado com `statesave base_001`. Aguarde a confirmação do MAME; salvar/carregar estado pode ser agendado pelo emulador.
3. Salve a RAM inicial:

   ```text
   save "C:/Projetos/CS-Puzzle-Fighter-96/laboratorio/sessao_001/capturas/base.bin",ff0000,10000
   ```

4. Execute `time` e registre tempo emulado, PC, jogador, personagem, coluna/linha visíveis aproximadas, cores da dupla e entradas aplicadas. Registre também MAME 0.289, sistema `spf2tu`, dificuldade e SHA-256 dos dumps. A hora do arquivo no Windows não mede quadros emulados.
5. Para cada ramo, solte as entradas programáticas, use `stateload base_001` e aguarde a confirmação. Capture novamente a RAM antes de avançar; ela deve ser idêntica a `base.bin`. Se não for, interrompa a comparação causal e investigue o carregamento.
6. Avance exatamente N ocorrências de `gvblank`, uma por comando, a partir do estado sincronizado. Cada comando deve parar por VBlank, não por um watchpoint/breakpoint. `step` avança instruções; `next` troca de CPU; nenhum deles mede um quadro.

Os comandos `save` podem sobrescrever o destino. Use uma sessão e nomes inéditos, nunca os caminhos em `C:\MAME`. Não carregue um `.bin` com `load`: dump de RAM não substitui um save state completo.

## 3. Aplicar entradas reproduzíveis

O console Lua (`-console`) é separado da linha de comandos do depurador. Para evitar depender do foco do teclado, enumere os campos reais:

```lua
for tag, port in pairs(manager.machine.ioport.ports) do for name, field in pairs(port.fields) do print(tag, name, field.mask) end end
```

Confirme os nomes/máscaras no sistema carregado. No driver CPS2 0.289, `IN0` define P1 direita/esquerda/baixo nas máscaras `0x0001/0x0002/0x0004` e os botões 1/2 em `0x0010/0x0020`. P2 usa `0x0100/0x0200/0x0400` e `0x1000/0x2000`. Após conferir a enumeração, um exemplo para P1 direita é:

```lua
right = manager.machine.ioport.ports[":IN0"]:field(0x0001)
assert(right ~= nil)
right:set_value(1)
```

No depurador, execute um `gvblank`. No console Lua, libere com `right:set_value(0)` antes de qualquer quadro adicional. Os valores digitais são lógicos; não inverta por causa do hardware active-low. Mantenha as demais entradas de teste em zero. Ao terminar, `right:clear_value()` remove o override sem alterar os mapeamentos de teclado. Verifique na primeira execução que o console Lua aceita os comandos na fase de pausa escolhida.

Para obter o controle, parta do mesmo estado, mantenha a entrada em zero e avance o mesmo N. Para rotação, pressione apenas um botão durante um quadro e solte. Uma entrada mantida pode causar repetição automática, portanto N quadros com direita pressionada não equivalem necessariamente a N movimentos.

## 4. Matriz mínima de testes

| Ramo | Entrada | Quadros/observação | Critério |
| --- | --- | --- | --- |
| controle_A / controle_B | nenhuma | N=1,2,4 | Endpoints repetidos devem coincidir |
| direita_A / direita_B | P1 direita por um quadro | Capturar após N=1; repetir do mesmo estado | Candidato X muda de forma reproduzível frente ao controle |
| esquerda | P1 esquerda por um quadro | Mesmo estado e N | X deve responder no sentido oposto, salvo bloqueio |
| baixo | P1 baixo | N=1,2,4 | Y/posição deve responder à queda, distinguindo tempo |
| rotação_1 / rotação_2 | um botão por um quadro | No centro, sem colisões | Separar orientação de coordenada e efeitos de wall kick |
| P2_esquerda / P2_direita | somente P2 | Repetir em dois jogadores | Identificar os grupos A/B e a relação +0x400 |
| parede | manter esquerda/direita em teste separado | Até bloquear | X deve saturar enquanto o tempo continua |
| assentamento | nenhuma/baixo | Capturar antes/depois de travar | Separar peça ativa de grade persistente e ponteiro de busca |

Use uma RAM por endpoint (`controle_f01.bin`, `direita_f01.bin` etc.). Repita o mesmo ramo pelo menos duas vezes antes de aceitar uma hipótese. Não trate diferenças do oponente ou animação como evidência da entrada sem verificar o controle.

## 5. Observar quem escreve nos candidatos

Com a sessão isolada pausada, o arquivo `depurador/observar_candidatos.cmd` pode ser carregado pelo depurador:

```text
source "C:/Projetos/CS-Puzzle-Fighter-96/depurador/observar_candidatos.cmd"
```

Ele instala watchpoints de escrita sem modificar a RAM. Anote os IDs retornados por `wplist`. Quando houver uma parada, registre `pc`, `wpaddr`, `wpdata` e a instrução na janela de disassembly. O PC e o dado devem ser interpretados conforme a operação mostrada; o valor observado na RAM depende do ponto da parada. Use o histórico para examinar as instruções próximas.

Desabilite apenas os IDs adicionados por este arquivo com `wpdisable <id>` antes de contar VBlanks; reative com `wpenable <id>` na etapa de rastreamento. Não use `wpclear` sem argumentos se houver watchpoints de outro trabalho. Para consultar o último escritor, habilite `trackmem 1,maincpu,1` antes da ação e depois use `pcatmem ff84f4:maincpu`. O rastreamento precisa ser reativado após carregar estado.

Prioridade: `FF84F4`, `FF8488`, `FF851A` e correspondentes do segundo grupo. Depois observar `FF8542`/`FF84A6` em queda. Para distinguir ponteiro de peça de cursor de busca, testar se `FF851A` muda continuamente durante o deslocamento ou somente quando a dupla assenta/ocorre uma varredura.

## 6. Critério de conclusão

Validar X/Y apenas após: resposta reproduzível à ação isolada; distinção do controle; comportamento correto nas direções e paredes; independência de cor, pontuação e animação; identificação do jogador; confirmação das rotinas escritoras. Registrar se o formato é célula, pixel, ponto fixo ou ponteiro. Ainda não foi demonstrado nenhum par X/Y que atenda a todos esses critérios.

## Referências primárias

- [Comandos de memória](https://docs.mamedev.org/debugger/memory.html)
- [Execução e VBlank](https://docs.mamedev.org/debugger/execution.html)
- [Estados e rastreamento](https://docs.mamedev.org/debugger/general.html)
- [Watchpoints](https://docs.mamedev.org/debugger/watchpoint.html)
- [Entradas pela API Lua](https://docs.mamedev.org/luascript/ref-input.html)
- [Diretórios e opções de execução](https://docs.mamedev.org/commandline/commandline-all.html)
- [Driver CPS2 na versão mame0289](https://github.com/mamedev/mame/blob/mame0289/src/mame/capcom/cps2.cpp)
