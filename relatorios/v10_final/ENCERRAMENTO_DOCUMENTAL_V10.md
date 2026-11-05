# V10 — encerramento documental preparado

Preparado em 03/11/2026, America/Sao_Paulo, por autorização do usuário. **Auditoria final aprovada no escopo funcional medido, com ressalvas; aguardando registro autorizado deste encerramento e publicação de v0.10.0.** Nenhum merge, commit, push ou tag foi executado nesta preparação.

Branch: `feature/v10-gem-physics`. Checkpoint publicado e auditado: `4575f17a706d91df3ff009fb8b4d96d0cba06699`. A abreviação `4575f1a` fornecida nas solicitações anteriores não existe no repositório; o hash confirmado é o registrado aqui. `main` permanece em `03cfd1e7ac9433ea6b5b76cf052e2f7d6bb8f90e`.

## Documentos selecionados para versionamento

| Arquivo | Finalidade |
|---|---|
| `README.md` | Estado atual V10, resultados, ressalvas, adaptador gráfico e histórico V9 identificado |
| `ARQUITETURA_GODOT.md` | Fluxo temporal, módulos atuais, observadores visuais, dados e limites reais |
| `CONTINUIDADE_PROJETO.md` | Auditoria aprovada; encerramento documental preparado e publicação pendente |
| `relatorios/v10_final/RELATORIO_AUDITORIA_V10.md` | Auditoria original preservada, com nota posterior sobre a atualização documental |
| `relatorios/v10_final/summary.json` | Contagens e achados da execução auditada, sem alterar resultados |
| `relatorios/v10_final/ENCERRAMENTO_DOCUMENTAL_V10.md` | Este registro de escopo e pendências |

O relatório da auditoria e o JSON descrevem o estado executado em 03/11/2026. A revisão desta etapa conferiu seus resultados e atualizou somente documentação. **Não foram reexecutadas baterias nem feitas novas alegações de aprovação.** Uma cópia byte a byte dos documentos recebidos foi guardada na entrega externa antes da edição; o JSON mantém exatamente os mesmos dados, com finais de linha normalizados para LF.

Não foram selecionados capturas, galeria, mídias temporárias, logs, caches, ROMs, dumps ou fontes proprietárias. Os snapshots `git_final.json` e `preservation.json` da auditoria continuam locais como registros históricos, sem confundi-los com o estado do índice desta preparação. Fixtures, dados do jogo, código, testes e os dois arquivos não rastreados V10.3.4 foram preservados. Nenhuma regra de `.gitattributes` ou configuração Git foi alterada.

## Resultados da auditoria e alcance

- Física: 112/112 cenários, 14.072/14.072 amostras.
- Cadeias/Counter Gems: 22/22 cenários, 5.066/5.066 amostras e 54 verificações.
- Fidelidade 247/247; controles 33/33 e 866 amostras RNG; naturais 119/119; regras 34; Python 17; 17/17 baterias existentes.
- V10.3.2: 123.863 verificações; V10.3.3: 119.052; V10.3.4: 394. Power: 181 pares/1.407 verificações e 1.192 amostras de células. Rotação atual: 340 registros válidos e 80 pares MAME sem diferença de máscara.
- 1.000/1.000 séries MD3, 2.500 rounds e 51.000 verificações: **desfechos controlados por fixtures de top-out**, não 1.000 duelos naturais jogados exclusivamente por entradas e sincronizados ao MAME. Separadamente, o duelo percorreu 1.500 turnos gerados e 119 fixtures verificaram endpoints naturais.
- Janela com adaptador: 4/4 séries, dez rounds e 276 verificações. O teste histórico sem adaptador falhou na transição da moeda para a seleção.

Os contadores completos, a identificação do que foi executado e as evidências estão na [auditoria final](RELATORIO_AUDITORIA_V10.md) e no [resumo](summary.json).

## Ressalvas e pendências abertas

1. **Adaptador gráfico obrigatório para reproduzir o resultado aprovado:** `test_match_flow_visual_v10_3_4.gd` espera mais 0,25 s após capturar o resultado da moeda e preserva as asserções do teste histórico. O comando `validar_fluxo_partidas.py --visual` ainda escolhe o teste sem essa espera. Nenhum executor ou teste foi corrigido nesta preparação.
2. **Dois validadores aceitam entradas vazias:** falha reproduzida na auditoria, sem corrigir código ou fixtures. Os conjuntos reais auditados estavam completos e seus totais foram conferidos. O JSON continua registrando os três achados do instante auditado; o terceiro, sobre documentação desatualizada, foi tratado nesta etapa. Os achados dos validadores e do executor gráfico permanecem abertos.
3. **RNG não certificado integralmente:** a transição observada passa em 866 amostras, mas consumidores globais e gerador completo CPS-2 continuam fora da equivalência demonstrada. O stream atual usa RNG do Godot, seed 96, Crash periódico e Diamond a cada 25ª dupla.
4. **Fidelidade visual parcial:** arte CS própria; sem certificação integral de RGB, sprites de explosão, todas as geometrias/cores/P2 ou partidas naturais completas. Corrigir Ghost e igualar máscaras medidas não prova igualdade visual integral ao MAME.
5. **Ambiente/reprodução:** dependência do Godot portátil e de coletas MAME locais ignoradas; nomes de sessão e caminho absoluto do gerador documentados. Sem teste de periférico físico, outras plataformas ou novos binários exportados. Permanecem 73 avisos herdados na validação nativa.

## Estado para a próxima autorização

O escopo preparado é exclusivamente documental. A aprovação da auditoria recomenda uma versão funcional do duelo local com os limites acima; **não autoriza automaticamente commit, push, merge ou tag**. Aguardar autorização para registrar o encerramento documental. A publicação de v0.10.0 continua pendente e V11 não foi iniciada.
