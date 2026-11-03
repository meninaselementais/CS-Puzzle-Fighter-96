# Continuidade — Counter-Strike Puzzle Fighter '96

Atualizado em **02/11/2026**, após implementação autorizada da V10.3.2.

## Estado real

- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`.
- Branch: `feature/v10-gem-physics`.
- HEAD/último checkpoint publicado informado: `136238edf12b68761d72713b2225de9363e6ba94`.
- **V10.3.1:** medições concluídas no escopo P1 documentado.
- **V10.3.2:** implementação e validação concluídas no escopo funcional aprovado, entregue para análise do usuário, **sem commit**. Não se declara fidelidade visual integral ao original.
- **V10.3.3 não iniciada e não autorizada.** A próxima ação é a revisão do usuário.
- Última implementação publicada continua sendo a V10.2 do checkpoint. Não houve consulta remota ou publicação nesta etapa.

## Ler primeiro

1. `relatorios/v10_3_2/RELATORIO_V10_3_2.md`.
2. `relatorios/v10_3_2/verificacao_final.json` e resumos de regressão.
3. `relatorios/v10_3_1_suplemento_20261102/RELATORIO_COMPLEMENTAR_V10_3_1.md`.
4. `relatorios/v10_3_1/RELATORIO_V10_3_1.md`.
5. `relatorios/v10_2/RELATORIO_CONTINUIDADE_V10_2.md` para histórico do núcleo.

A continuidade anterior foi preservada em `relatorios/v10_3_2/CONTINUIDADE_ANTES_V10_3_2.md`. Não confundir seu status anterior de V10.3.2 não iniciada com o estado atual.

## Implementação atual

Somente um arquivo existente de código foi modificado: **`godot/presentation/cs_arena.gd`**.

- Partida temporal acompanha células e quedas da simulação, sem o deslocamento/squash artificial do replay visual antigo.
- Dupla normal usa contorno medido de 14×14 pixels nativos; a ligação vertical azul isolada usa os estágios discretos 14×14 → 14×16 → 16×16, em 4+4 ticks após depósito.
- Halo de 60 pixels separado do corpo, limitado à configuração P1 vertical azul/verde medida.
- Formação/crescimento Power desenham os retângulos atuais. União 2×2 + ponte + 2×2 apresenta 3×2 + 2×2 por dez ticks antes de 5×2, sem alterar o retângulo lógico.
- Ondas da partida seguem a remoção real e a gravidade intermediária. Não preveem toda a cadeia em um relógio separado. Ghost Gem Flicker não reaparece.
- O showcase explícito mantém seu caminho independente, preservando testes e demonstrações anteriores.

**Intactos:** `match_model.gd`, `main.gd`, todo o núcleo em `godot/core/` e todos os testes antigos. RNG, turnos, inputs, pontuação, ataques e regras não foram alterados. A arena é verificada como somente leitura de todas as propriedades do modelo antes/depois de cada atualização nos testes novos.

## Arquivos novos desta implementação

- `godot/tests/test_visual_timeline_v10_3_2.gd`.
- `godot/tests/render_visual_timeline_v10_3_2.gd`.
- `scripts/comparar_contornos_v10_3_2.py`.
- `relatorios/v10_3_2/`: relatório, continuidade anterior, capturas, comparações, logs e manifestos.

Continuam presentes os arquivos não rastreados das medições: as pastas de relatórios V10.3.1, seu suplemento e os scripts de coleta/análise/diagnóstico anteriores. Eles não foram sobrescritos. Boa parte das evidências é ignorada pelo Git; **não executar clean nem apagar diretórios ignorados**.

## Validação da V10.3.2

| Verificação | Resultado |
|---|---|
| Suíte existente com renderização/UI | 17/17 baterias PASS na revisão final |
| Física MAME | 112/112 cenários, 14.072/14.072 amostras |
| Cadeias/Counter Gems MAME | 22/22 cenários, 5.066/5.066 amostras, 54 verificações |
| Novo teste temporal/imutabilidade | 123.863 verificações, zero falhas; inclui 12 separações e três ondas reais |
| Integração de partidas | 4/4 partidas, 10 rounds, 204 verificações |
| Cena real, sem editar main | 172 capturas |
| Contornos de contato/ligação/halo | 20 pares MAME/Godot, zero pixels de máscara divergentes |
| Queda independente | 4 pares MAME/Godot, zero pixels de máscara divergentes |
| Lint | Zero erros, os mesmos 11 avisos preexistentes de caminhos de arte/relatórios |

Não houve coleta MAME nova, instalação de dependência nem repetição das 1.000 partidas históricas. As regressões existentes foram reexecutadas porque a apresentação foi alterada. Testes antigos não foram editados para acomodar resultados.

As comparações de máscara normalizam coordenadas/escala; **não significam igualdade de RGB, arte interna ou fundo**. As imagens originais acompanham a galeria HTML.

## Diferenças e limites que permanecem

1. **Giro gráfico:** a janela lógica 15..2 foi preservada, com bloqueio em 16/1; a trajetória gráfica completa de oito passos continua sem integração. `main.gd` desenha a dupla diretamente e não foi autorizada sua alteração nesta entrega. Esse limite já constava do plano aprovado.
2. **Power:** retângulos e união intermediária medidos estão representados; as trocas internas de arte em blocos de oito quadros não foram reconstruídas. A textura continua sendo CS, sem brilho/escala inventados para simular o script nativo.
3. **Explosões:** a apresentação básica mantém gemas até a remoção lógica e emite impactos nesse marco. No MAME, alguns sprites começam durante flood-fill e ficam vazios antes da remoção lógica. A sequência individual desses sprites não foi generalizada. O Ghost foi corrigido, mas isso não prova igualdade de todos os frames de explosão.
4. **Cobertura:** ligação/halo limitados às configurações aferidas; outras cores, trios/Ls/horizontais, P2 em todas as situações e partidas naturais completas não estão certificados.
5. Os elementos de combate e a arte CS permanecem diferentes dos sprites do original.

Não iniciar novas medições ou alterar arquivos protegidos para resolver esses pontos sem definir escopo e obter autorização quando necessária.

## Fontes preservadas e relógios

- Gemini original: `laboratorio/v10_3_1_mame_probe.lua`, SHA-256 `669ec58f73e8f3b7b01af7a28e2473e68b33098da6e8e680e2ef2d3f9b6ebe4f`.
- Lua corrigida: `scripts/medir_visual_v10_3_1.lua`, SHA-256 `cf8e97494fe41cecc1d7817f994c2ee3760890f65cc3be1bac27d5bab3b3e1f3`.
- Coletas visuais anteriores: `laboratorio/auto_20261101_222825_850720` e repetição `auto_20261101_222903_899708`.
- Suplemento: `laboratorio/auto_20261102_172410_209057` e repetição `auto_20261102_172448_482209`.
- Save state validado: `laboratorio/auto_20261028_155033_010970/sta/spf2tu/baseline.sta.sta`, SHA-256 `4fce8afe569173625dc29d02b646f766b0c908c5341d84b6b764476044ee43ee`.

As 18 coletas visuais e o suplemento continuam determinísticos segundo suas validações anteriores. Não foram reexecutados na V10.3.2. O diagnóstico `scripts/reproduzir_ghost_v10_3_1.gd` foi mantido como prova histórica: sua asserção exige o defeito e não é o teste de aceitação da correção. Usar o novo teste temporal para verificar ausência de reaparição.

CPU, RAM em `frame_done` e bitmap têm índices diferentes. Nos pares de contato deste relatório, Godot tick F é comparado ao PNG MAME F+1 após aferição das fontes; na queda histórica, depósito Godot F2 corresponde ao PNG MAME F58. Não deslocar a física do Godot por causa do pipeline de captura.

## Histórico resumido

- V9 concluída/publicada segundo histórico.
- Codex V10/V10.1: diagnóstico, coleta de contato e base temporal.
- Gemini V10.2: integração e validações; checkpoint atual informado como publicado.
- Gemini início V10.3.1: Lua e coleta parcial, depois auditadas e preservadas.
- Codex matriz V10.3.1: corrigiu instrumentação, coletou/repetiu 18 casos, diagnosticou Ghost.
- Codex retomada 02/11: conferiu artefatos e criou continuidade.
- Codex suplemento 02/11: dois ensaios + controle de fundo, contornos e sprites ativos; encerrou medições no escopo.
- Codex V10.3.2: plano aprovado expressamente pelo usuário; implementação restrita à arena, testes e evidências acima. Aguardar análise do usuário.

## Retomar com outra IA

1. Ler este documento e o relatório V10.3.2; verificar Git e inspecionar qualquer alteração posterior antes de escrever.
2. O HEAD ainda aponta à V10.2 publicada, mas há código V10.3.2 local modificado. **Não reconstruir a implementação do zero nem descartar arquivos não rastreados.**
3. Não executar reset/clean, commit, merge ou push sem autorização. Não alterar `match_model.gd` ou `main.gd` sem justificativa prévia e autorização específica.
4. Preservar todo o núcleo competitivo e todos os testes existentes. Não inserir deformações ou movimentos sem evidência.
5. Não instalar dependências desnecessárias nem publicar ROMs, save states, dumps ou disassembly.
6. Não avançar à V10.3.3 automaticamente. A próxima ação é a revisão desta entrega pelo usuário.

Comandos de reprodução estão no relatório. As capturas completas e logs também têm cópia em `C:\Users\MauTrIX\Documents\Codex\2026-11-01\continuar-counter-strike-puzzle-fighter-96\outputs\v10_3_2`.
