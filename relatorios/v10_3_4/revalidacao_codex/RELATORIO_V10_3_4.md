# V10.3.4 — animações internas das Power Gems

Concluída em 03/11/2026 no escopo temporal e estrutural auditado abaixo. Checkpoint ainda não registrado: aguarda autorização. Não se declara fidelidade visual integral ao MAME.

## Preservação e ponto de partida

Projeto `C:\Projetos\CS-Puzzle-Fighter-96`, branch `feature/v10-gem-physics`, HEAD `70a52c58017d9560043d9a3f463edd01ff8816fd`. Branch, status, diff e arquivos não rastreados foram examinados antes de escrever. Foram lidos a continuidade, os relatórios V10.3.1/suplemento, V10.3.2, V10.3.3 e as ferramentas deixadas pelo DeepSeek.

O DeepSeek deixou 62 linhas adicionais na arena, 12 sprites, dados, teste, capturador e gerador/comparador. Sua implementação foi aproveitada; não foi reiniciada. O estado recebido, incluindo as 181 capturas e resultados anteriores, está preservado em `outputs/v10_3_4/deepseek_preserved` da entrega externa. O manifesto inicial contém 436 arquivos rastreados/não rastreados existentes. Os resultados informados pelo agente anterior não foram aceitos como validações independentes.

## Arquivos modificados e criados

Único arquivo de implementação modificado: `godot/presentation/cs_arena.gd`. Mantida a implementação de facetas por célula do DeepSeek, acrescentando identidade de região/cor para reiniciar os relógios corretos e recorte do overlay ao interior do cristal. A arena tem agora 68 linhas adicionais em relação ao HEAD.

Arquivos V10.3.4 do DeepSeek completados nesta retomada:

- `godot/data/power_facet_v10_3_4.json`: documentação das medições corrigida; não é uma fixture usada para acomodar testes.
- `godot/tests/test_power_facet_v10_3_4.gd`: expectativas corrigidas contra os descritores MAME; cobre regiões sem relação, remoção e reinício.
- `godot/tests/render_power_facet_v10_3_4.gd`: captura os 84 relógios, retângulos visuais e um controle sem overlay para cada quadro.
- `scripts/comparar_facetas_v10_3_4.py`: compara todas as células afetadas quadro a quadro, exige cobertura completa e repetição MAME idêntica; não realinha ciclos individualmente.

Preservados byte a byte: `godot/tools/build_power_facets.gd` e os 12 sprites `godot/assets/sprites/power_facet_{1,2,3,4}_{b,c,d}.png`. A fase A continua usando `power_crystal_<cor>.png`. Nenhum sprite novo foi gerado nesta retomada.

Novos arquivos desta retomada:

- `godot/tests/test_power_facet_capture_v10_3_4.gd`: comparação diferencial dos pixels com/sem facetas.
- `godot/tests/test_match_flow_visual_v10_3_4.gd`: adaptador curto do teste histórico de partidas, aguardando a janela real de confirmação da moeda.
- Este relatório, `summary.json`, galeria e evidências em `relatorios/v10_3_4/revalidacao_codex/`.
- `CONTINUIDADE_PROJETO.md` atualizado somente após confirmar os resultados; cópia anterior preservada na entrega.

Intactos: todos os arquivos de `godot/core/`, `godot/presentation/main.gd`, fixtures MAME, testes anteriores à V10.3.4, controles, RNG, pontuação e regras. Nenhum arquivo inicial foi removido. Os relatórios legados em caminhos fixos foram preservados/restaurados byte a byte pelo executor externo.

## Problemas encontrados e correções

1. **Crescimento:** o DeepSeek fazia animar só a linha nova. No MAME, em CPU F37, os descritores antigos também mudam: `(0,12)` passa a `5A40`, `(1,12)` a `5A44`, e a linha inferior reinicia seus tiles. Agora as seis células da região expandida reiniciam. Uma Power independente mantém seu relógio.
2. **União:** o comparador anterior aceitava Godot iniciar o ciclo da ponte em F36 enquanto o MAME iniciava o ciclo final em CPU F47. Agora o estágio visual 3×2+2×2 dura dez quadros; esquerda/ponte reiniciam nesse estágio, direita continua. Em Godot F46, a região final 5×2 reinicia as dez células. A geometria lógica permanece final desde a resolução do núcleo.
3. **Máscara insuficiente:** o comparador anterior usava a mesma região para os três casos e considerava todo pixel não preto como corpo. Poderia aprovar um fundo preenchido. Foi substituído pelo controle diferencial do mesmo estado e pela comparação temporal externa de todas as células.
4. **Borda:** o overlay agora é recortado ao interior, preservando quatro pixels do perímetro da área de desenho do cristal. As 181 comparações não encontraram alterações nesse perímetro nem efeitos em células fora das fases B/C/D.
5. **Teste gráfico histórico:** falhou antes da arena, com 0/4 partidas, ao enviar Enter aproximadamente 0,1 s após revelar a moeda. O jogo exige pelo menos 0,2 s. O adaptador espera mais 0,25 s depois da captura do resultado e delega todo o resto ao teste original. Nenhuma alteração no jogo ou teste histórico.

As expectativas novas do DeepSeek que diziam que células antigas nunca reiniciam foram corrigidas com referência explícita aos traços, não para esconder divergências. Nenhuma fixture, CSV ou captura MAME foi modificada. Falhas intermediárias durante a correção e a falha do teste histórico ficam nos logs, separadas dos resultados finais.

## Testes executados e resultados reais

| Verificação | Resultado independente |
|---|---|
| Teste Power recebido, antes de corrigir | 379 verificações PASS; cobertura tinha expectativas incorretas |
| Power final | 394 verificações, zero falhas |
| Comparação temporal MAME × Godot | 1.192/1.192 amostras de células compatíveis |
| Formação 2×2 | 256/256 amostras de células |
| Crescimento 2×3 | 336/336 amostras, incluindo preâmbulo sem faceta |
| União 5×2 | 600/600 amostras, incluindo estágio intermediário e preâmbulo |
| Estrutura diferencial dos PNGs Power | 181 pares, 1.407 verificações, zero falhas |
| V10.3.2, reexecutada após correção | 123.863 verificações, zero falhas |
| V10.3.3, reexecutada após correção | 119.052 verificações, zero falhas |
| Física V10.2 | 112/112 casos, 14.072/14.072 amostras |
| Cadeias/Counter Gems V10.2 | 22/22 casos, 5.066/5.066 amostras, 54 checks |
| Suíte existente com renderização/UI | 17/17 baterias PASS; inclui 17 testes Python |
| Naturais, dentro da suíte | 119/119 fixtures PASS |
| Partidas completas integradas headless | 4/4, dez rounds, 204 verificações |
| Partidas em janela OpenGL, adaptador | 4/4, dez rounds, 276 verificações e 30 PNGs |
| Contato/ligação/halo, PNGs recapturados | 20/20 pares, zero diferenças de máscara |
| Queda independente, PNGs recapturados | 4/4 pares, zero diferenças de máscara |
| Rotação, capturas históricas reanalisadas | 80/80 pares, zero diferenças de máscara; 36 quadros/268 pixels de oclusão corretos |
| Smoke com inputs nas quatro cenas | 4/4 PASS; sem erros |
| Validação nativa de recursos | 59 recursos/scripts/cenas verificados, zero erros, zero avisos de configuração |
| Lint estático | Zero erros; 11 avisos de caminhos já existentes |

A validação nativa completa em modo debug mostra **73 avisos**, também presentes no checkpoint `70a52c5` validado em cópia isolada. São os mesmos pares arquivo/mensagem, sem categorias novas. Essa contagem inclui os 11 avisos do lint e avisos GDScript que um teste normal sem debugger não imprime. O smoke informa 106 ocorrências de avisos pela recarga das cenas; a transição Coin Flip→seleção é um achado informativo esperado. Não se declara projeto sem avisos.

## Comparação com o MAME e critérios A–J

Fonte: `laboratorio/auto_20261101_222825_850720/visual_trace_v10_3_1.csv`, SHA-256 `ba57c3c65b5ff758043a8049fde87fad0151236233318b44ab7c0060e3f54d97`. A repetição em `auto_20261101_222903_899708` foi novamente conferida e é idêntica. Nenhuma coleta MAME nova foi necessária.

O confronto usa **Godot F = CPU MAME F+1**, fixo para os três casos. Não confundir CSV CPU com o índice dos PNGs ou com RAM do callback de vídeo. O último PNG Godot F65 de formação não tem CPU F66 na fonte: permanece registrado como um quadro sem par, sem inventar amostra ou tratá-lo como falha.

A formação, o crescimento e a união foram auditados por célula, inclusive cantos, bordas e células que mudam de função (A–C). A→B→C→D→C→B→A e blocos de oito quadros são preservados; A final persiste após 48 ticks de transição (D–E). Os relógios se associam à célula e à região/cor: mudanças reiniciam somente regiões afetadas, sem sincronizar cristais independentes (F). A arte base permanece contínua, com controle diferencial do perímetro e captura em janela inspecionada (G). P1/P2 têm arrays independentes e inícios defasados testados no Godot (H). Invariantes recursivas do modelo durante a apresentação e a preservação dos arquivos do núcleo confirmam geometria, RNG, controles e pontuação preservados (I–J).

O comparador interpreta as famílias de tiles nativos para inferir A/B/C/D. As 1.192 amostras validam **estado temporal por célula**, não os pixels dos overlays CS. Os 12 overlays do DeepSeek são arte procedural própria. Não reproduzem os desenhos de cada tile nativo.

## Evidências gráficas

Coleção integral desta retomada em:

`C:\Users\MauTrIX\Documents\Codex\2026-11-03\continuar-counter-strike-puzzle-fighter-96\outputs\v10_3_4`

- `power_render_final/render/`: 181 PNGs com facetas + 181 controles sem facetas; `captures.json` contém relógios e retângulos.
- `structure_verified/capture_structure.json`: células e pixels alterados por quadro.
- `comparison_verified/`: resultado temporal e todas as amostras por célula.
- `v10_3_2_render/render/`: 172 capturas novas para regressão; CSVs de máscara junto ao diretório de renderização.
- `matches_visual_final/`: 30 capturas e relatório de partidas em janela.
- `rotation_masks/`: reanálise das capturas preservadas, sem alegar nova coleta de rotação.
- `GALERIA.html`: seleção dos originais Godot/MAME, sem alterar os pixels; rótulos distinguem bitmap e traço CPU.
- `deepseek_preserved/`: código, documentos e resultados recebidos antes da retomada.
- `preservation_final.json`, `git_final.txt`, `MANIFESTO_SHA256.json`: integridade e estado final.

Uma seleção dos PNGs e os principais resumos também foram copiados para `relatorios/v10_3_4/revalidacao_codex/`, mantendo intacta a pasta original de capturas do DeepSeek.

## Limitações e pendências

Não certificadas: igualdade RGB ou forma interna das facetas com MAME; silhueta Power nativa pixel a pixel; todas as geometrias/cores/velocidades; comparação MAME de P2; fidelidade visual integral de partidas naturais. As limitações anteriores de explosões e artes CS continuam vigentes. A ausência de vazamento do overlay é uma propriedade diferencial do Godot, não prova de igualdade entre renderizadores.

As quatro partidas integradas usam os cenários existentes de top-out pelo resolvedor real. Não equivalem a uma nova execução de mil partidas naturais. As 119 fixtures naturais foram reexecutadas, sem nova coleta do arcade.

Não há falha funcional pendente no escopo auditado. O teste gráfico histórico sem adaptador continua sensível à janela de confirmação e sua falha está registrada. Os avisos herdados foram mantidos fora do escopo. Pendências para registro: análise desta entrega e autorização explícita do usuário para checkpoint. Nenhum commit, push, staging, tag, instalação, merge, rebase, reset ou clean foi executado. `main` não foi modificada; V11 não foi iniciada.
