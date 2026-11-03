# Continuidade — Counter-Strike Puzzle Fighter '96

Atualizado em **02/11/2026**, America/Sao_Paulo, após inspeção do repositório e revalidação dos artefatos existentes.

## Ponto atual

- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`.
- Branch: `feature/v10-gem-physics`.
- HEAD: `136238edf12b68761d72713b2225de9363e6ba94`.
- Mensagem: `feat(v10): implementa física temporal e cronologia das gemas`.
- Commit datado de 01/11/2026, 20:05:23 −03:00.
- Último checkpoint publicado informado pelo usuário: esse mesmo commit. A referência local `origin/feature/v10-gem-physics` aparece alinhada; **não houve consulta remota nesta retomada**.
- Última implementação concluída: **V10.2**. Etapa atual: **V10.3.1, medições visuais parcialmente concluídas**. Não declarar fidelidade visual integral nem V10.3.2 implementada.

## Etapas concluídas e evidência

| Etapa | Estado | Evidência / alcance |
|---|---|---|
| V9 | Concluída e publicada segundo histórico | Relatórios históricos preservados; não revalidada nesta retomada |
| V10.1 | Concluída segundo histórico | `relatorios/v10_gem_physics/`, medições de contato e fixtures |
| V10.2 | Concluída e publicada segundo histórico/checkpoint informado | `relatorios/v10_2/RELATORIO_CONTINUIDADE_V10_2.md`, resumos de validação e código no HEAD |
| Recuperação Gemini V10.3.1 | Concluída | Lua original de 453 linhas, hash preservado; sua coleta parcial foi auditada |
| Matriz visual V10.3.1 disponível | Coletada e repetida | 18 cenários, 1.100 amostras CPU e 1.099 capturas por sessão; traços CPU/vídeo idênticos entre as duas sessões |
| Diagnóstico Ghost Gem Flicker | Causa reproduzida, correção pendente | Godot: reaparição nos quadros 56..65; CSV e script de diagnóstico preservados |

Os resultados históricos da V10.2 incluem 112 cenários/14.072 amostras de física, 22 cenários/5.066 amostras de cadeias e Counter Gems, 17 baterias de regressão e 1.000 partidas automatizadas aprovadas. São evidências anteriores: **não foram reexecutadas em 02/11/2026**. O resumo de cadeias consultado nesta retomada contém 22/22 casos, 5.066/5.066 amostras, 54 verificações e nenhuma falha.

## Onde o trabalho realmente parou

Não há alterações locais da implementação visual. O trabalho parou depois da coleta corrigida, repetição e relatório V10.3.1, com lacunas visuais explicitadas. O plano de correção V10.3.2 está escrito, mas não implementado.

Concluído no escopo medido, P1/MAME 0.289 `spf2tu` USA 960620:

- 72 entradas de deslocamentos das tabelas `$12D00` e `$12DA0` extraídas e conferidas.
- 80 passos de giro: quatro orientações iniciais × dois sentidos × oito passos, mais dois casos de corredor × oito passos; total de dez casos de giro e 80 pares dx/dy.
- 794 amostras de `animation_ram`, em 55 cenários antigos, coincidentes com as tabelas.
- Janela de contato 16..1 e depósito seguinte; sprites das células após o depósito, contato de mesma cor e queda separada.
- Formação 2×2, crescimento 2×2 → 2×3 e união por ponte → 5×2, com estados, tiles e dimensões por quadro. A formação é resposta a um quadrado já preparado, não queda medida da quarta gema.
- Flood-fill/fase 8, timer 40, fases 9..11, desaparecimento visual anterior à remoção lógica, queda intermediária e segunda onda.
- 39.564 descritores de células no relógio de vídeo. Em 1.080 pares sem fronteira de cenário/injeção, vídeo F coincide com CPU F+1.

A última amostra CPU encerra a execução antes de `frame_done`; isso explica 1.100 amostras CPU contra 1.099 PNGs. Não é um quadro a completar artificialmente.

## Arquivos locais ainda não registrados

Antes desta documentação, `git diff` e `git diff --cached` estavam vazios. Não existem arquivos rastreados modificados ou staged. O Git lista estes **cinco arquivos novos não ignorados**:

1. `relatorios/v10_3_1/RELATORIO_V10_3_1.md`.
2. `relatorios/v10_3_1/summary.json`.
3. `scripts/analisar_visual_v10_3_1.py`.
4. `scripts/medir_visual_v10_3_1.lua`.
5. `scripts/reproduzir_ghost_v10_3_1.gd`.

Esta retomada acrescenta apenas `CONTINUIDADE_PROJETO.md` à raiz do projeto. O documento também permanece não rastreado; nada foi colocado no índice.

Há muitos arquivos locais **ignorados**, que não aparecem no `git status` normal: laboratório, ferramentas, originais, capturas, fixtures, caches e relatórios históricos. Não confundir ignorado com descartável. Em especial:

- `laboratorio/v10_3_1_mame_probe.lua`: original Gemini, nunca substituir.
- `laboratorio/auto_20261101_220908_925177`: coleta original Gemini.
- `laboratorio/auto_20261101_222825_850720`: coleta final primária.
- `laboratorio/auto_20261101_222903_899708`: repetição final.
- `relatorios/v10_3_1/`: CSVs completos, manifestos, diagnóstico e 30 PNGs selecionados; boa parte é ignorada pela política existente.
- `relatorios/v10_gem_physics/contact_measurements/mame_contact_fixtures.json`: fixture antiga necessária ao analisador, disponível localmente.

Inventário de caminhos ignorados e não rastreados, sem conteúdo de ROM/dumps: `C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\outputs\continuidade_20261102\INVENTARIO_LOCAIS.txt`. O inventário precede a criação deste documento. A configuração `core.longpaths=true` é aplicada só aos comandos de leitura, sem alterar a configuração do repositório, para enumerar caches de caminhos longos do Windows.

## Arquivos pedidos em outputs e suas cópias no projeto

Base externa: `C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\outputs\v10_3_1`.

| Arquivo externo, lido integralmente nesta retomada | Cópia correspondente no projeto |
|---|---|
| `RELATORIO_V10_3_1.md` | `relatorios/v10_3_1/RELATORIO_V10_3_1.md` |
| `analisar_medicoes.py` | `scripts/analisar_visual_v10_3_1.py` |
| `reproduzir_ghost.gd` | `scripts/reproduzir_ghost_v10_3_1.gd` |
| `probe_corrigido.lua` | `scripts/medir_visual_v10_3_1.lua` |
| `gemini_probe_preservado.lua` | `laboratorio/v10_3_1_mame_probe.lua` |

Os cinco pares são idênticos byte a byte por SHA-256. Não copiar uma versão por cima da outra sem conferir hashes e eventual trabalho posterior.

Hash Lua Gemini original: `669ec58f73e8f3b7b01af7a28e2473e68b33098da6e8e680e2ef2d3f9b6ebe4f`.
Hash Lua corrigida final: `cf8e97494fe41cecc1d7817f994c2ee3760890f65cc3be1bac27d5bab3b3e1f3`.

## Verificações desta retomada — 02/11/2026

- Branch, HEAD, diff e índice conferidos antes de escrever.
- 48 arquivos do manifesto da entrega no projeto: **zero divergências**.
- 49 arquivos do manifesto da entrega externa em outputs: **zero divergências**.
- Analisador existente executado sobre as duas sessões já salvas: **aprovado**, reproduzindo todas as contagens acima. Saída regenerada em diretório de trabalho separado, sem sobrescrever as evidências.
- Diagnóstico Godot 4.7.2 executado novamente: `GHOST_REPRODUCED frames=[56,57,58,59,60,61,62,63,64,65]`.
- CSV Ghost regenerado comparado byte a byte com `relatorios/v10_3_1/ghost_godot.csv`.
- Nenhuma execução nova do MAME, nova coleta, instalação, commit ou push.

O diagnóstico Ghost **passa ao reproduzir o defeito**. Não representa correção aprovada. A execução direta de `resolve_frame` + `step_from_model` é um cenário controlado, não certificação de uma partida gráfica inteira.

Relatório da auditoria: `outputs/continuidade_20261102/verificacao_retomada.json` na base externa do chat. Lint histórico da entrega: zero erros, 11 avisos preexistentes de caminhos de arte/relatórios; não foi necessário repeti-lo porque nenhum arquivo de implementação mudou.

## Pendências

Prioridade para concluir as lacunas da V10.3.1:

1. **Dupla ativa antes do depósito:** faltam descritores em `$FFB300` durante aproximação, primeiro contato, contador 16..1 e transição de depósito. A matriz atual exporta descritores de células em `$FFB400`, não esses sprites ativos.
2. **Compressão e recuperação:** faltam contorno/dimensões em pixels por quadro para distinguir deformação de troca de sprite/conexão com vizinhos. Não há porcentagem de squash nativa comprovada.

Cobertura adicional não comprovada: corredor em orientação vertical 2, giros sobrepostos, outras geometrias/kicks, P2, demais cores/velocidades, outras formas Power, decodificação completa dos scripts de sprites e equivalência visual de partida natural. Manter separadas essas ampliações da lacuna imediata; não reiniciar a matriz inteira por padrão.

O Ghost continua presente. Sua causa é o fim antecipado da sobreposição visual: a fila independente da arena acaba em F56, volta a desenhar o tabuleiro lógico, e a lógica só remove a onda em F66. O plano posterior é sincronizar máscara/identidade da onda com os marcos lógicos, sem adicionar uma espera fixa arbitrária. Não implementar nesta etapa.

## Próxima tarefa exata

**Instrumentar apenas os sprites da dupla ativa nos casos P1 de pouso isolado e contato de mesma cor, mantendo as coletas atuais como referência.**

1. Criar uma Lua suplementar com nome novo a partir do coletor corrigido; preservar original Gemini e Lua final existente.
2. Usar o mesmo save state validado, abaixo. Registrar os descritores ativos em `$FFB300` e as células de apoio em `$FFB400`, contador `$176(A6)`, offset `$242(A6)`, orientação, tiles, atributos e entradas.
3. Capturar desde antes do primeiro contato até depois do depósito e recuperação. Registrar CPU e vídeo separadamente, sincronizando PNG e RAM em `frame_done`; usar IDs e quadros nas injeções suplementares.
4. Medir contornos/dimensões por quadro sobre os PNGs correspondentes. Separar observação de hipótese; não traduzir automaticamente mudança de tile em escala afim.
5. Repetir somente os casos suplementares, produzir fixtures e confrontar as duas execuções. Anexar resultados em relatório complementar e atualizar este documento.
6. Decidir o encerramento da V10.3.1 à luz desses resultados e dos limites registrados. V10.3.2 permanece planejamento até nova autorização de implementação.

## Reprodução sem refazer medições

No PowerShell, definir os caminhos absolutos. O argumento final do analisador precisa ser um **diretório novo de trabalho**, nunca a pasta de evidências preservadas: o script escreve CSVs e resumos.

```powershell
$pfRoot = 'C:\Projetos\CS-Puzzle-Fighter-96'
$pfScratch = 'C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\work\retomada_nova'
python "$pfRoot\scripts\analisar_visual_v10_3_1.py" $pfRoot "$pfRoot\laboratorio\auto_20261101_222825_850720" "$pfRoot\laboratorio\auto_20261101_222903_899708" $pfScratch
& "$pfRoot\ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "$pfRoot\godot" --script "$pfRoot\scripts\reproduzir_ghost_v10_3_1.gd" -- "$pfScratch\ghost_godot.csv"
```

Resultado esperado do analisador: 18 casos, 1.100 CPU, 1.099 vídeo, 39.564 sprites, 80 passos, 794 comparações antigas, 1.080 alinhamentos de relógio, repetição CPU/vídeo verdadeira. Usar Python normal, **sem `-O`**, pois o analisador verifica resultados com `assert`.

Pré-requisitos para uma futura coleta suplementar: MAME 0.289 local e ROMs já disponíveis; save state `laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta`, SHA-256 `4fce8afe569173625dc29d02b646f766b0c908c5341d84b6b764476044ee43ee`. Não usar o estado `auto_20261028_141709_059767` da Lua original como referência de jogo.

## Histórico dos últimos agentes

| Agente/etapa | Trabalho observado ou documentado |
|---|---|
| Codex anterior, V10/V10.1 | Diagnóstico, coleta de contato, fixtures temporais e base da física, conforme relatórios históricos |
| Gemini Antigravity, V10.2 | Integração e validações documentadas, incluindo cadeias/Counter Gems; checkpoint atual informado como publicado |
| Gemini Antigravity, início V10.3.1 | Deixou Lua de 453 linhas, coleta de oito casos e sondagens locais. Tabelas aproveitadas; demais alegações não aceitas sem corrigir instrumentação |
| Codex anterior neste chat, V10.3.1 | Recuperou o trabalho; corrigiu referência de estado/campos/borda; coletou e repetiu 18 casos; gerou relatório/fixtures; reproduziu Ghost; não implementou correção |
| Codex, retomada de 02/11/2026 | Releu os três arquivos, localizou e leu Lua original, conferiu hashes/cópias/Git, reexecutou análise offline e diagnóstico Ghost; criou este documento sem nova coleta MAME |

O histórico descreve evidências dos arquivos e deste chat; não presume tarefas não registradas no Antigravity.

## Restrições e instruções para outra IA

- Começar por este documento, depois relatório V10.3.1 e `summary.json`. Conferir branch, HEAD, status, diffs e arquivos não rastreados antes de editar; se houver mudança desde este registro, inspecioná-la e preservá-la.
- Não executar `git reset`, `git clean` ou sobrescritas destrutivas. Não alterar a branch `main` nem `godot/presentation/main.gd`.
- Não fazer commit, push ou staging por inferência. A autorização atual cobre inspeção e documentação; implementação visual não foi autorizada nesta retomada.
- Não alterar motor lógico, RNG, controles ou regras. Não iniciar V11. Não instalar skills adicionais.
- Não repetir as 18 coletas, a física V10.1/V10.2 ou 1.000 partidas sem divergência ou mudança que justifique isso.
- Não usar a execução original Gemini como evidência de giros/pousos/Power concluídos: campos incorretos `$16F/$16C`, limpeza da sentinela e save state inadequado comprometem esses casos. Os campos corretos são `$176/$242`.
- Não generalizar os números de P1 para todo o arcade. Preservar relógios CPU/vídeo e distinguir teste sintético de partida natural.
- Não publicar ROMs comerciais, save states, dumps proprietários ou disassembly. Preservar esses recursos locais; Git ignora muitos deles. Não forçar inclusão de relatórios ignorados sem revisar os arquivos.
- Ao terminar qualquer etapa, atualizar versão/pendências/próxima tarefa neste documento, registrar evidências e Git, distinguindo testes antigos dos recém-executados.
