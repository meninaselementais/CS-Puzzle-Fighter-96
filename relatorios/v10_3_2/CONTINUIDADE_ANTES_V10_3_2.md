# Continuidade — Counter-Strike Puzzle Fighter '96

Atualizado em **02/11/2026**, após o suplemento de dupla ativa e contornos da V10.3.1.

## Estado atual e decisão

- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`.
- Branch: `feature/v10-gem-physics`.
- HEAD/último checkpoint publicado informado: `136238edf12b68761d72713b2225de9363e6ba94`.
- Commit: `feat(v10): implementa física temporal e cronologia das gemas`.
- Última implementação concluída: **V10.2**.
- **V10.3.1 concluída como etapa de medições no escopo P1 documentado**, incluindo as duas lacunas de dupla ativa e contornos. Não equivale a fidelidade visual completa de todo o jogo.
- **V10.3.2 não iniciada**: existe plano, mas nenhuma animação/correção visual foi implementada. A tarefa atual autorizou somente medições e documentação.
- Não houve consulta remota, commit, push ou staging nesta etapa. Referência local da branch permanece alinhada ao checkpoint.

## Documentos que a próxima IA deve ler

1. Este arquivo.
2. `relatorios/v10_3_1_suplemento_20261102/RELATORIO_COMPLEMENTAR_V10_3_1.md` e `summary.json`.
3. `relatorios/v10_3_1/RELATORIO_V10_3_1.md` e `summary.json`.
4. `relatorios/v10_2/RELATORIO_CONTINUIDADE_V10_2.md` quando tratar de implementação/regressões.

A continuidade anterior desta mesma data foi preservada integralmente em `relatorios/v10_3_1_suplemento_20261102/CONTINUIDADE_ANTES_SUPLEMENTO_20261102.md`. Ela descreve as lacunas antes do suplemento; não usar seu estado "parcial" como status atual.

## Etapas concluídas

| Etapa | Estado e evidência |
|---|---|
| V9 | Concluída/publicada segundo histórico; relatórios preservados |
| V10.1 | Concluída segundo histórico; contato/física e fixtures em `relatorios/v10_gem_physics/` |
| V10.2 | Concluída/publicada segundo histórico e checkpoint informado; última implementação do jogo |
| Recuperação Gemini V10.3.1 | Lua de 453 linhas recuperada e preservada; coleta parcial auditada |
| Matriz anterior V10.3.1 | 18 cenários repetidos; 1.100 amostras CPU, 1.099 PNGs por sessão; 80 passos de giro e 794 confrontos com fixtures antigas |
| Ghost Gem Flicker | Defeito reproduzido no Godot em F56..65; causa e plano documentados, não corrigido |
| Suplemento V10.3.1 | Dois casos de aproximação/contato e um controle de fundo, 96 quadros cada; repetição determinística de RAM e pixels; sprites ativos/contornos medidos |

Resultados históricos V10.1/V10.2: 112 cenários/14.072 amostras de física, 22 cenários/5.066 amostras de cadeias e Counter Gems, 17 baterias de regressão e 1.000 partidas automatizadas aprovadas. **Não foram reexecutados no suplemento**, pois a implementação não mudou.

## O que o suplemento resolveu

Fontes finais novas:

- Primária: `laboratorio/auto_20261102_172410_209057`.
- Repetição: `laboratorio/auto_20261102_172448_482209`.
- Casos: `isolated_approach`, `same_color_approach` e controle `empty_background_reference`.

Por execução: **288 amostras CPU, 288 de vídeo, 23.040 linhas de descritores, 288 PNGs**. São dois ensaios físicos e um controle de fundo, não 288 cenários nem repetição das 18 coletas antigas.

Capturados `$FFB300/$FFB320` (pivô/satélite ativos), `$FFB340/$FFB360` (NEXT separado), 36 células de `$FFB400`, orientação, offset, estados, tiles, atributos, entradas e contadores. Todas as injeções ocorreram somente em preparação, antes da medição. Intervalo/incremento nativos de queda preservados; entrada neutra durante os ensaios.

Resultados:

- Primeiro contato CPU F15 / RAM de vídeo F14, contador 16. Contagem completa 16..1. Depósito CPU F31 / vídeo F30.
- Corpo isolado azul/verde: **14×14, 184 pixels e contorno normalizado idêntico** durante aproximação, contato e após depósito. Não foi observada compressão elástica nesse caso.
- Halo rosa ao redor do pivô: 16×16, 60 pixels, intermitente nos PNGs F3,5,...,31. É separado do corpo; sua inclusão causaria falsa impressão de mudança de tamanho da gema.
- Contato de mesma cor: tile 0x5A00 → 0x5A4E → 0x5A08; nos pixels, duas máscaras separadas → conexão intermediária por 4 quadros → conexão final estável. Por célula, 14×14/184 → 14×16/212 → 16×16/244 pixels. É troca discreta de arte/conexão, não porcentagem presumida de squash.
- O contorno final de duas gemas ligadas é 16×32/488 pixels; não retorna à forma separada no intervalo F40..96. O satélite verde não muda de contorno.

## Alerta de relógios da captura

No suplemento, RAM de vídeo F coincide com CPU F+1 em 285 pares completos. **O bitmap não é a RAM de vídeo do mesmo índice.** A aproximação dos dois casos confere, pixel a pixel em posição, com RAM de vídeo F−2 para PNG F3..31; as mudanças de tile em vídeo F34/F38 aparecem nos PNGs F36/F40.

Usar `states.csv`, `sprites.csv` e `medicoes_pixels.csv` com esse alinhamento. Não atrasar a física do Godot por causa do relógio da captura. A origem completa desse deslocamento (buffering CPS-2/emulador/callbacks) não foi determinada. Não generalizar automaticamente para todas as sessões antigas.

## Validações aprovadas nesta etapa

- MAME 0.289: duas execuções suplementares concluídas, sem erro Lua; hashes das fontes originais preservados.
- `states.csv`, `sprites.csv` e `injections.csv`: idênticos byte a byte entre execuções.
- **288/288 pares de PNGs com SHA-256 idêntico**.
- Classificação dos pixels por subtração exata do controle de fundo: nenhum pixel diferente sem classificação; fundo fora da coluna das gemas idêntico.
- Contornos completos por segmentos de linha, dimensões, áreas e hashes de forma exportados e verificados. Sem limiar aproximado, redimensionamento ou porcentagem inventada.
- Leitor PNG sem dependências: autocheck dos cinco filtros, CRC e componentes aprovado.
- Manifestos anteriores: 48 hashes no projeto e 49 na cópia externa preservados, além das Luas Gemini/corrigida.
- Nenhuma nova execução do diagnóstico Ghost ou de regressões antigas foi necessária neste suplemento. A revalidação de Ghost F56..65 pertence à retomada anterior de 02/11 e continua documentada.

## Arquivos locais e Git

Nenhum arquivo rastreado ou staged foi alterado. O arquivo de continuidade, já não rastreado, foi atualizado. Arquivos não ignorados que já existiam antes deste suplemento:

- `CONTINUIDADE_PROJETO.md`.
- `relatorios/v10_3_1/RELATORIO_V10_3_1.md`, `summary.json`.
- `scripts/analisar_visual_v10_3_1.py`, `medir_visual_v10_3_1.lua`, `reproduzir_ghost_v10_3_1.gd`.

Acrescentados nesta etapa:

- `scripts/medir_dupla_ativa_v10_3_1.lua`.
- `scripts/analisar_dupla_ativa_v10_3_1.py`.
- `scripts/png_rgb_v10_3_1.py`.
- `relatorios/v10_3_1_suplemento_20261102/`: relatório, backup da continuidade, resumo, fixtures, contornos, 288 capturas primárias e manifesto.

Boa parte das evidências é ignorada por `.gitignore`. **Não apagar arquivos ignorados**: incluem os laboratórios, ferramentas, originais e fixtures locais. Git não publicará automaticamente CSVs/PNGs ignorados. Não alterar a política nem forçar inclusão sem revisar arquivos e autorização.

## Fontes anteriores preservadas

- Original Gemini: `laboratorio/v10_3_1_mame_probe.lua`, SHA-256 `669ec58f73e8f3b7b01af7a28e2473e68b33098da6e8e680e2ef2d3f9b6ebe4f`.
- Lua corrigida anterior: `scripts/medir_visual_v10_3_1.lua`, SHA-256 `cf8e97494fe41cecc1d7817f994c2ee3760890f65cc3be1bac27d5bab3b3e1f3`.
- Coletas anteriores válidas: `laboratorio/auto_20261101_222825_850720` e `auto_20261101_222903_899708`.
- Coleta original parcial Gemini: `laboratorio/auto_20261101_220908_925177`; não usar como prova de giros/pousos/Power concluídos. Continha campos `$16F/$16C` incorretos, limpeza de sentinela e estado inadequado. Os campos corretos são `$176/$242`.
- Save state validado: `laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta`, SHA-256 `4fce8afe569173625dc29d02b646f766b0c908c5341d84b6b764476044ee43ee`.

Os três arquivos externos solicitados na retomada anterior continuam em `C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\outputs\v10_3_1` e coincidem com as cópias do projeto: relatório em `relatorios/v10_3_1`, analisador e diagnóstico Ghost em `scripts/`. O novo suplemento também tem cópia externa em `outputs/v10_3_1_suplemento` nesse mesmo chat.

## Limitações restantes — não confundir com as lacunas resolvidas

- Generalização para P2, outras cores, velocidades e orientações; giros sobrepostos, corredor na orientação 2 e apoios irregulares.
- Todas as possíveis deformações de Power/Counter Gems, toda a linguagem dos scripts de sprites e fidelidade visual integral em partida natural.
- Queda inteira desde o spawn: o novo ensaio começa no trecho final com offset sintético −8.
- Rotina interna que gera o halo e origem completa do deslocamento entre RAM de vídeo e bitmap.

Nenhum desses comportamentos é declarado equivalente sem nova evidência. A conclusão da V10.3.1 é limitada ao escopo definido e medido, com essas ampliações explicitamente fora da certificação.

## Próxima tarefa exata

**Não há nova coleta pendente nos dois itens imediatos da V10.3.1. A próxima etapa é implementar a V10.3.2 somente após autorização do usuário.**

Plano técnico, sem código implementado:

1. Corrigir Ghost Gem Flicker mantendo a máscara de desaparecimento da onda até a remoção lógica, sem espera fixa arbitrária; transformar o diagnóstico que reproduz o defeito em teste de ausência de reaparição.
2. Consumir os offsets discretos de rotação já medidos; manter pivô/cores/geometria e não substituir por curva trigonométrica presumida.
3. Separar corpo, translação e halo da dupla ativa. Não impor squash genérico ao contato isolado medido.
4. Representar conexão de mesma cor por estados/arte e duração do script medida, mantendo a forma final ligada; sincronizar Power/ondas/gravidade com marcos reais.
5. Preservar lógica/RNG/controles e combinar fixtures antigas e suplementares. Qualquer necessidade de alterar `main.gd` deve ser tratada explicitamente na autorização futura.
6. Rodar regressões de física, cadeias, RNG e rounds quando houver implementação; não repetir as coletas já validadas só para retomar.

## Reproduzir análise sem coletar novamente

Usar Python normal, sem `-O`; o analisador utiliza `assert`. A saída deve ser uma pasta **nova** e o analisador recusa sobrescrever:

```powershell
$pfRoot = 'C:\Projetos\CS-Puzzle-Fighter-96'
$pfNew = 'C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\work\suplemento_reanalise_nova'
python "$pfRoot\scripts\png_rgb_v10_3_1.py"
python "$pfRoot\scripts\analisar_dupla_ativa_v10_3_1.py" $pfRoot "$pfRoot\laboratorio\auto_20261102_172410_209057" "$pfRoot\laboratorio\auto_20261102_172448_482209" $pfNew
```

Não executar novamente o MAME por padrão. O executor e as Luas permanecem disponíveis para divergências ou ampliação expressamente necessária.

## Histórico dos últimos agentes

| Agente/etapa | Trabalho |
|---|---|
| Codex anterior, V10/V10.1 | Diagnóstico/coletas de contato, fixtures e base temporal, conforme histórico |
| Gemini Antigravity, V10.2 | Integração/validações de física, cadeias/Counter Gems; checkpoint atual informado como publicado |
| Gemini Antigravity, início V10.3.1 | Lua de 453 linhas e coleta parcial; tabelas aproveitadas após auditoria |
| Codex anterior neste chat, matriz V10.3.1 | Recuperou trabalho, corrigiu instrumentação/estado, coletou e repetiu 18 casos, documentou e reproduziu Ghost sem implementar correção |
| Codex, retomada de 02/11/2026 | Revalidou artefatos/análise/Ghost, criou continuidade; nenhuma nova coleta nessa retomada |
| Codex, suplemento de 02/11/2026 | Mediu apenas dois casos de aproximação/contato + controle de fundo, repetiu e comparou 288 PNGs, extraiu contornos, concluiu V10.3.1 no escopo e atualizou documentação; sem implementação visual |

## Regras para retomar com outra IA

- Conferir branch, HEAD, status/diffs e todos os novos arquivos antes de editar. Se aparecer trabalho posterior, inspecionar e preservar; não presumir que este documento é mais recente que o disco.
- Não executar `git reset`, `git clean`, sobrescritas destrutivas, commit ou push sem autorização. Não alterar a branch `main`.
- Nesta etapa não alterar `godot/presentation/main.gd`, motor lógico, RNG, controles ou regras, nem implementar animações.
- Não iniciar V11 nem instalar skills adicionais. Não repetir coletas/regressões sem necessidade demonstrada.
- Não incluir ROMs comerciais, save states, dumps proprietários ou disassembly nos arquivos destinados ao GitHub.
- Separar evidência de hipótese, relógio de RAM de relógio de pixels e teste sintético de partida natural. Atualizar esta continuidade ao terminar a próxima etapa.
