extends SceneTree
const Arena = preload("res://presentation/cs_arena.gd")
const Match = preload("res://core/match_model.gd")
const Board = preload("res://core/board_model.gd")
const Rules = preload("res://core/resolution.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func _initialize() -> void:
	call_deferred("run")

func snapshot(model) -> String:
	return var_to_str([model.boards[0].cells, model.boards[1].cells, model.scores, model.pending,
		model.pairs[0].pivot, model.pairs[1].pivot, model.pair_index, model.frame, model.global_seed,
		model.rng.state, model.stream, model.winner, model.lost])

func run() -> void:
	var arena = Arena.new()
	var model = Match.new()
	for player in range(2):
		for state in Arena.FIGHTER_ANIMS[player]:
			for frame in Arena.FIGHTER_ANIMS[player][state]:
				expect(arena.load_tex(frame.tex) != null and int(frame.ticks) > 0, "asset %s" % frame.tex)
	for chain in range(1, 6):
		var cells := Fixtures.chain_board(chain)
		var board = Board.new(); board.load_cells(cells)
		var result: Dictionary = Rules.resolve(board)
		expect(result.waves.size() == chain, "fixture %dX" % chain)
		arena.reset_state()
		var count: int = arena.enqueue_visual_waves(0, cells, Vector2(64,108))
		expect(count == chain, "visual wave count")
		var scores: Array = [arena.active_wave[0].score]
		for w in arena.wave_queues[0]: scores.append(w.score)
		for i in range(scores.size()): expect(int(scores[i]) == int(result.waves[i].score), "real score %d/%d" % [chain, i])
		var before := snapshot(model)
		var bursts := 0
		var previous_phase := ""
		for _tick in range(600):
			arena.step_from_model(model)
			if not arena.active_wave[0].is_empty():
				var phase: String = arena.active_wave[0].phase
				if phase == "burst" and previous_phase != "burst":
					bursts += 1
					expect(not arena.combo_flashes.any(func(f): return int(f.player) == 0), "no phantom cell after impact")
				previous_phase = phase
			expect(snapshot(model) == before, "visual cannot mutate match")
		expect(bursts == chain and arena.active_wave[0].is_empty() and not arena.has_visual_override(0), "waves drain once")
		expect(arena.combo_flashes.is_empty() and arena.gem_sparks.is_empty() and arena.vfx_sprites.is_empty(), "effects expire")
	arena.reset_state()
	arena.trigger_wave_presentation(0, 5, 1000, false, false, Vector2(64,108), Vector2(160,420))
	expect(arena.fighter_state[0] == "grenade", "5X keeps grenade")
	expect(arena.projectiles.is_empty(), "wait for release pose")
	var release_tick := 0
	for keyframe in Arena.FIGHTER_ANIMS[0].grenade:
		if keyframe.get("release",false): break
		release_tick += int(keyframe.ticks)
	for _tick in range(release_tick): arena.step_from_model(model)
	expect(arena.projectiles.any(func(p): return p.kind == "he"), "grenade released on keyframe")
	arena.reset_state()
	for p in range(2): arena.trigger_wave_presentation(p, 1, 200, false, false, Vector2(64,108), Vector2(160,420))
	expect(arena.fighter_state == ["shoot", "shoot"], "both attacks survive simultaneous hits")
	for _tick in range(4): arena.step_from_model(model)
	for p in range(2): expect(arena.projectiles.any(func(pr): return int(pr.owner) == p), "both release projectile")
	for _tick in range(100): arena.step_from_model(model)
	expect(arena.fighter_state == ["idle", "idle"] and arena.pending_hit == [0,0], "recover after simultaneous attacks")
	arena.reset_state()
	for p in range(2):
		arena.set_fighter_state(p, "victory")
		for _tick in range(160): arena.advance_fighter_anim(p, model)
		expect(arena.fighter_anim_frame[p] == Arena.FIGHTER_ANIMS[p].victory.size() - 1, "victory holds final pose")
	# Native snapshots: validate trace construction against the same complete resolution fixtures.
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mechanics_fixtures.json"))
	for f in data.fixtures:
		arena.reset_state()
		var cells := PackedInt32Array(f.input)
		var b = Board.new(); b.load_cells(cells)
		var resolved: Dictionary = Rules.resolve(b)
		var count: int = arena.enqueue_visual_waves(0,cells,Vector2(64,108))
		expect(count == resolved.waves.size(), "trace %s" % f.id)
		if count > 0:
			var last: Dictionary = arena.wave_queues[0][-1] if not arena.wave_queues[0].is_empty() else arena.active_wave[0]
			expect(last.cells_after == b.cells, "trace endpoint %s" % f.id)
	# Scene includes selectors, frame stepping and all fourteen requested demonstrations.
	var scene = load("res://animation_showcase.tscn").instantiate()
	root.add_child(scene); scene.set_physics_process(false); scene.autoplay = false
	for topic in range(scene.TOPICS.size()):
		scene.select_topic(topic)
		for _tick in range(300): scene.advance_showcase()
		expect(scene.model.frame == 0, "showcase isolates match clock")
		if topic in [6,7,8,9,10,11,12,13]: expect(scene.arena.active_wave[0].is_empty(), "showcase finishes topic %d" % topic)
	scene.queue_free()
	print("PRESENTATION_TESTS ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
