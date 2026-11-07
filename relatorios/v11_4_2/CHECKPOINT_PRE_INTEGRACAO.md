# V11.4.2 — Checkpoint pré-integração (Etapa 1)

Gerado em 2026-11-06 (sessão Claude, sem `git` CLI disponível). **Nenhum commit, push ou tag foi criado.**

## Repositório
- Projeto: `C:\Projetos\CS-Puzzle-Fighter-96`
- Branch: `feature/v11-hud` (lido de `.git/HEAD`)
- HEAD: `1a943a4db4d1dba84a222735187afb6108b4c4c5` (mesmo commit da `main`; o branch não tem commits próprios)
- Consequência: **todo o trabalho V11.2 → V11.4.1 está apenas na árvore de trabalho** (modificado ou não rastreado). Recomenda-se um commit de segurança autorizado pelo usuário antes de continuar.

## Método e limites (leia antes de confiar neste inventário)
- Este ambiente não tem shell: `git status` / `git diff` **não foram executados**.
- O status abaixo foi reconstruído lendo `.git/index` (versão 2, 451 entradas) e comparando o SHA-1 de blob de cada arquivo com a entrada do índice (com e sem normalização CRLF). Isto equivale a "diferente do **índice**", não necessariamente do HEAD.
- O inventário cobre **apenas os 32 arquivos envolvidos** (núcleo protegido, apresentação, testes, assets de vidro, evidências-chave). Não é um inventário completo da árvore.
- Hashes: SHA-256 do conteúdo em disco.

Legenda: `same` = igual ao índice; `MODIFIED` = tracked e diferente do índice; `untracked` = ausente do índice.

## Núcleo protegido (não pode ser modificado na V11.4.2)
| Arquivo | Status | SHA-256 | Bytes |
|---|---|---|---|
| `godot/core/arcade_rng.gd` | same | `3bb4829d5854263d7756ba0da6320d36879e9f45e1d5c92f74efe7e1652765f9` | 326 |
| `godot/core/control_model.gd` | same | `4c8a6cb0dd7f52386f34c5119b46c8c6bd971ed527cdb741f2aa9119db78809e` | 972 |
| `godot/core/pair_model.gd` | same | `1ea94d1262eb7bff868c51443d8f28c6f414bd5188f7d4afb4023cb28e8fda18` | 552 |
| `godot/core/match_model.gd` | same | `408e31e6489b4566fc0f9bb55e399f54a4b117aef9dc00a8be035dfd1c882aaa` | 7440 |
| `godot/core/board_model.gd` | same | `c17ef59ae0a251b06991e48744c501972f31b54b767c65022eadc867a89e391a` | 2626 |
| `godot/core/attack_rules.gd` | same | `df93b626f973efb61c78d86a5fd5395eb4f836e136ce3392051cb4d0a3433dd7` | 1772 |
| `godot/core/gem_rules.gd` | same | `795590059a76d038b1f6866bbace87a73ab0f69816f87717f6d593d46ef1fefe` | 1325 |
| `godot/core/resolution.gd` | same | `1bfd6139ac792693e4d732258aa6131606b9aa0b49db5454e3467717d3a630e6` | 12297 |
| `godot/core/match_session.gd` | same | `e5ae6f0334113c347370b77f8d6b7c2fa1a1d64447734255d60d4cbbdc73f99c` | 3059 |
| `godot/core/gem_motion.gd` | same | `5bed72de670c4b31d13d484d81e85b675cc495076530741219669fa9a1e3267e` | 8321 |

Observação: `godot/core/match_model.gd`, `board_model.gd`, `arcade_rng.gd`, `gem_motion.gd`, `resolution.gd`, `attack_rules.gd`, `pair_model.gd`, `match_session.gd`, `control_model.gd` e `gem_rules.gd` estavam **idênticos ao índice** neste checkpoint.

## Apresentação, testes e assets
| Arquivo | Status | SHA-256 | Bytes |
|---|---|---|---|
| `godot/presentation/hud_presenter.gd` | untracked | `21839b26c69fec5c9909d77babbf752119154fe134f0ac26e65b5ed6333351c6` | 3474 |
| `godot/presentation/showcase_fixtures.gd` | same | `660a418be88843925c9250ee9539d5a5c8a5bd79cde6089db9660a06a334370a` | 2809 |
| `godot/presentation/main.gd` | MODIFIED | `fde25ac9e37dd4d861205270813358644fb255918cb8e403b5f28c33f5ccc559` | 13591 |
| `godot/presentation/cs_arena.gd` | MODIFIED | `5c2313dabebccce3dac62420acae1b977c0b1ebba7c0c4238ea5c1c0f1f260a4` | 93702 |
| `godot/presentation/gem_destruction_vfx.gd` | untracked | `3218cbb0e01d3571c2ae36ea01cc66e4ac34df5b23e76c594508fb321c348017` | 10181 |
| `godot/presentation/vfx/glass_surface.gdshader` | untracked | `843b8c41ed6e3cf8b7e6731584c8ac5cd771d896e3167453a8bdefd79f762712` | 1220 |
| `godot/presentation/vfx/glass_fragment.gdshader` | untracked | `a3a47860c046c02705c435647681945023718c58355aacd79bcc226512e97b3d` | 2988 |
| `godot/presentation/vfx/glass_shatter.gd` | untracked | `dcaf39b44833bd8df27f0b1c9025a28a2d8e048e8b1e620363c57e8bbaee072b` | 9899 |
| `godot/assets/vfx/glass/plate_fracture.png` | untracked | `65bcd64c364f33a4d0be7d642ab56f8df781c8722dab57d1229a015f03fcc014` | 8151 |
| `godot/assets/vfx/glass/shards.png` | untracked | `6859a90bc4cbdb428217d3583162b9eee2dd75a7e016a6203c726497915fac82` | 1147 |
| `godot/assets/vfx/glass/gem_fracture.png` | untracked | `df35802e10cb57f3979871f584311e91cb7c10fea0dcfc24cd2eb48595520cd7` | 1289 |
| `godot/assets/vfx/glass/grain.png` | untracked | `a504977f6177cf796c733c2a0c4c9f273afdba87c78bbcf5ac1a5b979ed7e503` | 112591 |
| `godot/tests/bench_glass_v11_4_1.gd` | untracked | `7a0dd1e9412406051fe91bf5ba383a2cdc370e60a378031be626400d78ff9845` | 4837 |
| `godot/tests/test_glass_v11_4_1.gd` | untracked | `7d5a9d454bb64976548e75364ac95c82ba68522b0bfac4f35831471259d6981e` | 16880 |
| `godot/tests/test_gem_destruction_v11_4.gd` | untracked | `d99055dc9f2c42b98d79184ffcb271984402177de11fde543cd044be5dc8817c` | 13152 |

## Protótipo aprovado V11.4.1 e evidências
| Arquivo | Status | SHA-256 | Bytes |
|---|---|---|---|
| `relatorios/v11_4_1/run_validation.py` | untracked | `61c1d9776a9b6ebe61c820cd52960bdebc51fa50de599b1885fea6dc3b649edf` | 5664 |
| `relatorios/v11_4_1/build_assets.py` | untracked | `0b12da8092a7faf10c05eca79d076cdea883b3cd11403223466bde8d3a6d4006` | 3056 |
| `relatorios/v11_4_1/glass_summary.json` | untracked | `f184d211e21871a46252b9102a675053503ef7e1128125f5f08d2e063136f36a` | 459 |
| `relatorios/v11_4_1/cs_arena.gd.v11_4.txt` | untracked | `18bf2ea2667483c633eb9dc7df3cb5b49a2d6c8544ad3686cb82e18e0d1c3708` | 93651 |
| `relatorios/v11_4_1/gem_destruction_vfx.gd.v11_4.txt` | untracked | `e985c1367b0e0019ebba6b95bf0d2e0829cde50c02f6eb7f143d36ec3fac958d` | 9403 |
| `relatorios/v11_4_1/evidence/glass/player.html` | untracked | `2d5e8ff41c9b7d92e16bbea9258687d7ea68e1a14aa383e01cf96591b89d5a6e` | 4295 |
| `relatorios/v11_4_1/evidence/glass/explosion_results.json` | untracked | `cec926a18ebb3de9a219d153fc9ad5af3b82124ee0e147677b020edd208bdd27` | 4432 |

Protótipo anterior (grosseiro) preservado em `relatorios/v11_4_1/*.coarse_v1.txt` e `relatorios/v11_4_1/evidence/glass_coarse_v1/`. Referência V11.4: `cs_arena.gd.v11_4.txt` e `gem_destruction_vfx.gd.v11_4.txt`.

## Estado do gancho de vidro antes da V11.4.2
- `gem_destruction_vfx.gd` já possui `var prototype`, `handles()`, e chama `prototype.observe/emit/step/clear/draw_layers`.
- `cs_arena.gd:892` já ignora `spawn_board_explosion` quando `destruction.handles(...)`.
- `prototype` só é atribuído em `test_glass_v11_4_1.gd`; no jogo real permanece `null` (V11.4 ativa).
- `glass_shatter.gd::selected()` só seleciona gema azul comum (code==1, y>=2) e Power Gem vermelha 5×2.
