extends SceneTree
## V10.3.4 — render das Power Gems em main.tscn, capturando PNGs nos quadros
## medidos no MAME (snap/power_*.png) e gravando a linha do tempo de facetas.

const Session = preload("res://core/match_session.gd")
const PairModel = preload("res://core/pair_model.gd")
var scene: Node2D
var output: String
var records: Array[Dictionary] = []

func _initialize() -> void:
	Session.accept_server_assignment(true, [0, 1])
	Session.reveal()
	assert(Session.lock_characters(["sas", "phoenix"]))
	output = OS.get_environment("PF_REPORT").path_join("render")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func prepare(kind: String) -> void:
	scene.model.restart()
	scene.arena.reset_state()
	scene.replay_mode = false
	scene.position = Vector2.ZERO
	while scene.model.stream.size() < 8: scene.model.stream.append([2, 4])
	scene.model.pairs[1] = PairModel.new(Vector2i(3, 0), 1, 2)
	scene.model.motion[1].fall_countdown = 10000
	if kind == "power_2x2":
		for y in [12, 13]:
			for x in [0, 1]: scene.model.boards[0].cells[y * 6 + x] = 1
		scene.model.motion[0].phase = 3
	elif kind == "power_growth":
		for y in [12, 13]:
			for x in [0, 1]: scene.model.boards[0].cells[y * 6 + x] = 1
		scene.model.motion[0].phase = 3
	elif kind == "power_union_5x2":
		for y in [12, 13]:
			for x in [0, 1, 3, 4]: scene.model.boards[0].cells[y * 6 + x] = 1
		scene.model.motion[0].phase = 3
	scene.model.motion[0].result = {"waves": [], "score": 0, "attack": 0, "converted": 0, "gravity": 0}
	scene.model.Rules.form_powers(scene.model.boards[0])

func capture(kind: String, frame: int) -> void:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.save_png(output.path_join("%s_f%03d.png" % [kind, frame])) == OK)

func capture_base(kind: String, frame: int) -> void:
	var saved: PackedInt32Array = scene.arena.power_facet_age[0].duplicate()
	scene.arena.power_facet_age[0].fill(48)
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join("%s_base_f%03d.png" % [kind, frame])) == OK)
	scene.arena.power_facet_age[0] = saved

func key_cells(kind: String) -> Array[int]:
	if kind == "power_growth": return [66, 72]
	if kind == "power_union_5x2": return [74, 72]
	return [72]

func run() -> void:
	root.size = Vector2i(1000, 700)
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var ranges := {"power_2x2": [1, 65], "power_growth": [35, 90], "power_union_5x2": [35, 94]}
	for kind in ["power_2x2", "power_growth", "power_union_5x2"]:
		prepare(kind)
		var lo: int = ranges[kind][0]
		var hi: int = ranges[kind][1]
		for frame in range(1, hi + 1):
			if frame == 35 and kind != "power_2x2":
				if kind == "power_growth":
					for x in [0, 1]: scene.model.boards[0].cells[11 * 6 + x] = 1
				else:
					for y in [12, 13]: scene.model.boards[0].cells[y * 6 + 2] = 1
				scene.model.motion[0].phase = 3
			scene.model.tick()
			scene.arena.step_from_model(scene.model, scene.BOARD_ORIGINS)
			if frame >= lo:
				var rec: Dictionary = {"case": kind, "frame": frame}
				for idx in key_cells(kind):
					rec["facet_%d" % idx] = scene.arena.power_facet_phase(0, idx)
					rec["age_%d" % idx] = scene.arena.power_facet_age[0][idx]
				rec["ages"] = Array(scene.arena.power_facet_age[0])
				rec["regions"] = scene.arena.get_visual_powers(0, scene.model.boards[0].power_gems).map(func(r): return [r.position.x, r.position.y, r.size.x, r.size.y])
				records.append(rec)
				await capture(kind, frame)
				await capture_base(kind, frame)
	var file: FileAccess = FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "  "))
	print("POWER_FACET_RENDER ", records.size(), " captures from unmodified main.tscn")
	scene.queue_free()
	quit()
