extends SceneTree

const Board = preload("res://core/board_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Rules = preload("res://core/resolution.gd")

func _initialize() -> void:
	call_deferred("run_demo")

const Fixtures = preload("res://presentation/showcase_fixtures.gd")

func build_5x_chain_board() -> PackedInt32Array:
	return Fixtures.build_5x_chain_board()

func build_c4_board() -> PackedInt32Array:
	return Fixtures.build_c4_board()

func run_demo() -> void:
	root.size = Vector2i(1000, 700)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)

	var p1_cells := build_5x_chain_board()
	var p2_cells := build_c4_board()

	# Verifica que o núcleo lógico resolve exatamente 5 ondas (5X CHAIN) em P1 e C4 (Diamond Wave) em P2!
	var test_b1 = Board.new()
	assert(test_b1.load_cells(p1_cells))
	var res1: Dictionary = Rules.resolve(test_b1, true)
	print("P1_WAVES=", res1.waves.size(), " SCORE=", res1.score, " ATTACK=", res1.attack)
	assert(res1.waves.size() == 5)

	var test_b2 = Board.new()
	assert(test_b2.load_cells(p2_cells))
	var res2: Dictionary = Rules.resolve(test_b2, true)
	print("P2_C4_WAVES=", res2.waves.size(), " C4_DIAMOND=", res2.waves[0].get("diamond", false), " SCORE=", res2.score)
	assert(res2.waves.size() >= 1 and bool(res2.waves[0].get("diamond", false)))

	# Carrega no jogo real:
	# Coloca C4 (5) no NEXT do P1 e C4 (5) caindo no par ativo do P2 para demonstrar NEXT + queda + ativação!
	scene.model.restart()
	scene.arena.reset_state()
	var next_p1_idx: int = scene.model.pair_index[0] + 1
	var next_p2_idx: int = scene.model.pair_index[1] + 1
	while scene.model.stream.size() <= maxi(next_p1_idx, next_p2_idx) + 2:
		scene.model.stream.append([1, 2])
	scene.model.stream[next_p1_idx] = [2, 5] # C4 no indicador NEXT de P1!
	scene.model.stream[next_p2_idx] = [9, 12] # Crash Orbs Azul e Vermelha no NEXT de P2!
	scene.model.pairs[0] = Pair.new(Vector2i(1, 4), 10, 11) # Crash Orbs Amarela e Verde caindo em P1
	scene.model.pairs[1] = Pair.new(Vector2i(4, 5), 5, 9)   # C4 piscando durante a queda + Crash Orb Azul em P2!

	# Enfileira as 5 ondas visuais em P1 e a detonação de C4 em P2, aplicando a resolução ao modelo
	scene.model.boards[0].load_cells(test_b1.cells)
	scene.model.boards[0].power_gems = test_b1.power_gems.duplicate()
	scene.model.last_results[0] = res1
	scene.model.scores[0] = int(res1.score)
	scene.arena.prev_scores[0] = int(res1.score)
	scene.arena.prev_cells[0] = test_b1.cells.duplicate()
	var w_count1: int = scene.arena.enqueue_visual_waves(0, p1_cells, scene.BOARD_ORIGINS[0], true)
	print("W_COUNT1=", w_count1)
	assert(w_count1 == 5)

	scene.model.boards[1].load_cells(test_b2.cells)
	scene.model.boards[1].power_gems = test_b2.power_gems.duplicate()
	scene.model.last_results[1] = res2
	scene.model.scores[1] = int(res2.score)
	scene.arena.prev_scores[1] = int(res2.score)
	scene.arena.prev_cells[1] = test_b2.cells.duplicate()
	var w_count2: int = scene.arena.enqueue_visual_waves(1, p2_cells, scene.BOARD_ORIGINS[1], true)
	assert(w_count2 >= 1)

	var args := OS.get_cmdline_user_args()
	var out_dir := args[1] if args.size() == 2 and args[0] == "--output" else ProjectSettings.globalize_path("res://../relatorios/fidelidade_v6")
	var frames_dir := out_dir.path_join("frames")
	DirAccess.make_dir_recursive_absolute(frames_dir)

	var milestones := {
		4: "demo_01_c4_next_e_crash_orbs.png",
		34: "demo_02_combo_2x_shatter.png",
		56: "demo_03_combo_3x_chain.png",
		78: "demo_04_combo_4x_chain_grenade.png",
		100: "demo_05_combo_5x_chain_finale.png"
	}

	for f in range(120):
		scene.arena.step_from_model(scene.model, scene.BOARD_ORIGINS)
		scene.status = "Demo 1X..5X CHAIN + C4 + Crash Orbs | Quadro %03d/120" % (f + 1)
		scene.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(frames_dir.path_join("frame_%03d.png" % f))
		if milestones.has(f):
			img.save_png(out_dir.path_join(milestones[f]))
			print("Saved milestone ", milestones[f], " at frame ", f)

	print("DEMO_5X_CHAIN_AND_C4_OK")
	quit(0)
