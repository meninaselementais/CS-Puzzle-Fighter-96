# V11.4.2 — Plano de integração das explosões de vidro (handoff)

Status: **plano apenas. Nenhum código foi alterado nesta sessão** (sem shell: não era possível executar Godot/git). Checkpoint e hashes: `CHECKPOINT_PRE_INTEGRACAO.md`.
Decisões do usuário: (1) parar no checkpoint e entregar o plano a um agente com shell; (2) Power Gems de outros tamanhos reusam **recortes da máscara `plate_fracture.png` (5×2)**, sem assets novos.

## 1. O que já existe (verificado por leitura)
| Ponto | Arquivo | Situação |
|---|---|---|
| Gancho `prototype` + `handles()` | `godot/presentation/gem_destruction_vfx.gd` | pronto; chama `prototype.observe/emit/step/clear/draw_layers` |
| Pular explosão antiga se tratada | `godot/presentation/cs_arena.gd` ~l.892 | pronto: `if not destruction.handles(w,Vector2i(rx,ry)): spawn_board_explosion(...)` |
| Filtro em `emit_wave` e `observe_pre` | `gem_destruction_vfx.gd` | pronto: células tratadas saem do efeito antigo (sem duplicidade) |
| Ativação no jogo real | `cs_arena.gd` l.9 `var destruction = DestructionVfx.new()` | **`prototype` fica `null`**; só `test_glass_v11_4_1.gd` o atribui |
| Seleção do que vira vidro | `godot/presentation/vfx/glass_shatter.gd::selected()` | **limitada**: só gema azul comum (`code==1`, `y>=2`) e Power Gem vermelha 5×2 |

Ou seja: a integração real é (a) ativar o `prototype` na arena por uma opção e (b) generalizar `selected()` e a superfície rachada.

## 2. Mudanças propostas (somente camada de apresentação)
1. **Opção de apresentação**: em `cs_arena.gd`, criar o `glass_shatter.gd` com `load()` tardio só quando uma opção estiver ligada (ex.: `ProjectSettings`/variável de ambiente `PF_GLASS=1`, ou campo em `main.gd`). **Padrão desligado** → V11.4 segue como alternativa até validar.
2. **`selected()` generalizada** em `glass_shatter.gd`:
   - Gemas comuns das 4 cores: `code & 7` em 1..4, `y >= 2`, cor = `PALETTE[color]`.
   - Crash Gems: `code & 8` ligado com `code & 7` em 1..4 (hoje excluídas por `code==1`). Verificar a semântica em `core/gem_rules.gd` antes.
   - Power Gems: para cada `Rect2i` de `wave.powers_before`, agrupar os itens `is_power` dentro do retângulo e aceitar se `cells.size() == w*h` (hoje exige 5×2 vermelha com 10 células).
   - C4: `code & 7 == 5`, cor `PALETTE[5]` (laranja).
   - Incluir `kind` no grupo (`gem`/`power`/`crash`/`c4`) para escolher superfície e parâmetros.
3. **Superfície rachada por tamanho** (`draw_layers`): hoje usa `PLATE` se 5×2, senão `GEM` (32×32). Para 2×2, 2×3 etc.: `Sprite2D.region_enabled` com `region_rect` recortado de `plate_fracture.png` (160×64).
   - Atenção 1: o canal G da máscara é gradiente em x (`crack.g*0.65` define a varredura de revelação em `glass_surface.gdshader`); em recorte, o gradiente cobre só parte de 0..1 → remapear ou normalizar no shader.
   - Atenção 2: a máscara tem só 64 px de altura. Uma região de altura 3 células (96 px) não cabe; definir fallback (ex.: duas fatias empilhadas ou rotacionar o recorte). "2×3" é ambíguo (largura×altura?) — confirmar com o coordenador.
4. **C4 sem perder o choque**: hoje `emit_wave` filtra as células tratadas e, por isso, o anel `c4` (burst) e os 16 raios **sumiriam** se o C4 virar vidro. Proposta: para células tratadas, suprimir só `cell` burst + motes e **manter** o burst `kind=="c4"`. O teste existente `one exclusive C4 central blast` precisa continuar passando.
5. **Crash Gems**: o pulso/anel de antecipação (`code & 8`) é desenhado em `draw_glow` apenas para itens não tratados; se forem tratados pelo vidro, esse sinal some na fase `pre`. Decidir se mantém.
6. **Cotas P1/P2**: `MAX_MACRO 48 / MAX_MICRO 4096 / MAX_DUST 3072` por jogador já existem. O orçamento histórico (densidade 1.0) mostra o pior caso de 14 eventos batendo nos tetos (14432 instâncias vivas; eventos tardios recebem 0 micro). Avaliar uma cota mínima por evento. Perfis de qualidade: hoje só `density` em `glass_shatter.gd`; ligar a um perfil compartilhado se existir.

## 3. Proibido tocar (hashes no checkpoint)
`match_model.gd`, `board_model.gd`, `arcade_rng.gd` (RNG), `gem_motion.gd`, `gem_rules.gd`, `resolution.gd`, `attack_rules.gd`, `pair_model.gd`, `control_model.gd`, `match_session.gd`, `hud_presenter.gd`. No checkpoint todos os de `core/` estavam idênticos ao índice do git. Se algo exigir o núcleo, parar e relatar.

## 4. Testes a escrever/executar (`godot/tests/test_glass_v11_4_2.gd`, baseado em `test_glass_v11_4_1.gd`)
Cada item abaixo deve ser **executado** e registrado como tal; resultados antigos vão em seção "históricos".
1. Quatro cores (gema comum): contagens, uma região por célula, sem efeito antigo sobreposto.
2. Power Gems 2×2, 2×3 (nas duas orientações) e 5×2: região = formação real; células cobrem o retângulo.
3. Crash Gem e C4: C4 mantém burst `c4` único; sem fragmentação antiga duplicada.
4. Combos de 3 e 5 ondas (`Fixtures.chain_board`): um evento de VFX por onda; tetos respeitados.
5. P1 e P2 simultâneos: cotas independentes (`both=true`).
6. Integridade de contadores e ataques: fingerprint do modelo antes/depois (padrão `state()`/`fingerprint()` do teste atual).
7. RNG e sequência de peças (NEXT) idênticos com e sem vidro.
8. Regressões: `run_validation.py regression` (V10 e anteriores), `test_gem_destruction_v11_4`, `test_hud_next`, `test_hud_presenter`, `test_hud_presenter_scene`, V11.2/V11.3.
9. Desempenho: `bench_glass_v11_4_1.gd` + partida real; registrar CPU/GPU/draw calls e legibilidade.

## 5. Comandos (no Windows, na raiz do projeto)
```
python relatorios\v11_4_1\run_validation.py glass        # teste do vidro (V11.4.1)
python relatorios\v11_4_1\run_validation.py vfx          # explosões V11.4
python relatorios\v11_4_1\run_validation.py focused      # HUD/NEXT
python relatorios\v11_4_1\run_validation.py regression   # regressões históricas
```
O script restaura os JSONs históricos de `fidelidade_v5` ao final (`historical_restoration.json`). Godot usado: `ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe`.

## 6. Evidências a produzir
Capturas e sequência animada de uma **partida real** (não de cena de demonstração), reaproveitando o padrão de `player.html` / `player_comparativo.html` da V11.4.1; relatório final em `RELATORIO_INTEGRACAO_GLASS.md`.

## 7. Restrições mantidas
Sem commit, push ou tags sem autorização. Não iniciar V11.5. Recomenda-se **commit de segurança autorizado pelo usuário** antes de editar, pois todo o trabalho V11.x está sem commit (branch `feature/v11-hud` = HEAD `1a943a4`).
