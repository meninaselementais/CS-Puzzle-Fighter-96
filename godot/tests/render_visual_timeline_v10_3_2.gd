extends SceneTree
const Session = preload("res://core/match_session.gd")
const PairModel = preload("res://core/pair_model.gd")
var scene: Node2D
var output: String
var records: Array[Dictionary] = []
const CAPTURE_FRAMES: Array[int] = [1,2,14,15,16,30,31,32,34,35,36,38,39,40,48,56,60,65,66,80]

func _initialize() -> void:
	Session.accept_server_assignment(true,[0,1])
	Session.reveal()
	assert(Session.lock_characters(["sas","phoenix"]))
	output = OS.get_environment("PF_REPORT").path_join("render")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func prepare(kind: String) -> void:
	scene.model.restart()
	scene.arena.reset_state()
	scene.replay_mode = false
	scene.position = Vector2.ZERO
	# Fixed test input stream, prepared before observations; no draw-time RNG extension.
	while scene.model.stream.size() < 8: scene.model.stream.append([2,4])
	scene.model.pairs[1] = PairModel.new(Vector2i(3,0),1,2)
	scene.model.motion[1].fall_countdown = 10000
	scene.model.pairs[0] = PairModel.new(Vector2i(2,12 if kind == "same_color" else 13),1,3)
	scene.model.motion[0].offset = -8
	scene.model.motion[0].fall_start = false
	scene.model.motion[0].fall_countdown = 0
	scene.model.pair_age[0] = 32
	if kind == "same_color": scene.model.boards[0].cells[80] = 1
	if kind == "background":
		scene.model.pairs[0] = PairModel.new(Vector2i(2,0),0,0)
		scene.model.motion[0].fall_countdown = 10000
	if kind == "ghost":
		scene.model.boards[0].cells[78] = 10
		for x in range(1,4): scene.model.boards[0].cells[78+x] = 2
		scene.model.motion[0].phase = 3
	if kind == "split":
		scene.model.pairs[0] = PairModel.new(Vector2i(2,10),1,2)
		scene.model.pairs[0].rotation = 1
		for y in [11,12,13]: scene.model.boards[0].cells[y*6+2] = 4
		scene.model.motion[0].contact = 2
		scene.model.motion[0].offset = 0
	if kind.begins_with("power"):
		scene.model.pairs[0] = PairModel.new(Vector2i(5,13),3,4)
		for y in [12,13]:
			for x in ([0,1,3,4] if kind == "power_union" else [0,1]): scene.model.boards[0].cells[y*6+x] = 1
		scene.model.motion[0].phase = 3
	scene.model.motion[0].result = {"waves":[],"score":0,"attack":0,"converted":0,"gravity":0}

func capture(kind: String, frame: int) -> void:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.save_png(output.path_join("%s_f%03d.png" % [kind,frame])) == OK)
	records.append({"case":kind,"frame":frame,"phase":scene.model.motion[0].phase,"contact":scene.model.motion[0].contact,"offset":scene.model.motion[0].offset,"cells":Array(scene.arena.get_visual_cells(0,scene.model.boards[0].cells)),"powers":var_to_str(scene.arena.get_visual_powers(0,scene.model.boards[0].power_gems)),"stage_74":scene.arena.temporal_connection_stage(0,74),"halo":scene.arena.active_halo[0]})

func run() -> void:
	root.size = Vector2i(1000,700)
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	for kind in ["background","isolated","same_color","split","power_2x2","power_growth","power_union","ghost"]:
		prepare(kind)
		for frame in range(1,81):
			if frame == 35 and kind in ["power_growth","power_union"]:
				if kind == "power_growth":
					for x in [0,1]: scene.model.boards[0].cells[11*6+x] = 1
				else:
					for y in [12,13]: scene.model.boards[0].cells[y*6+2] = 1
				scene.model.motion[0].phase = 3
			scene.model.tick()
			scene.arena.step_from_model(scene.model,scene.BOARD_ORIGINS)
			if frame in CAPTURE_FRAMES or (kind == "split" and frame <= 7) or (kind == "power_union" and frame in [37,41,42,43,44,45,46]):
				await capture(kind,frame)
	var file: FileAccess = FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	print("VISUAL_V10_3_2_RENDER ",records.size()," captures from unmodified main.tscn")
	scene.queue_free()
	quit()
