extends SceneTree
const Session = preload("res://core/match_session.gd")
const Rotation = preload("res://presentation/pair_rotation_visual.gd")
const Fixture = preload("res://tests/rotation_fixture_v10_3_3.gd")
var scene: Node2D
var output: String
var records: Array[Dictionary] = []

func _initialize() -> void:
	Session.accept_server_assignment(true,[0,1])
	Session.reveal()
	assert(Session.lock_characters(["sas","phoenix"]))
	output = OS.get_environment("PF_REPORT").path_join("render")
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")

func capture(name: String) -> void:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name+".png")) == OK)

func step(mask: int) -> void:
	scene.model.input_masks[0] = mask
	var before: Array[Dictionary] = [Rotation.snapshot(scene.model,0),Rotation.snapshot(scene.model,1)]
	scene.model.tick()
	for player in range(2): scene.pair_rotation[player].step(before[player],Rotation.snapshot(scene.model,player))
	scene.arena.step_from_model(scene.model,scene.BOARD_ORIGINS)

func case_capture(item: Dictionary, primary: bool) -> void:
	scene.model = Fixture.prepare(item,primary)
	scene.arena.reset_state()
	for visual in scene.pair_rotation: visual.reset()
	for row in item.samples:
		if int(row.frame) == 0: continue
		step(int(row.input))
		var selected: bool = int(row.frame) >= 3 and int(row.frame) <= 12 if primary else int(row.frame) in [38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,75,76,77,78,79,80,81,82]
		if not selected: continue
		var stem: String = "%s_f%03d" % [item.id,row.frame]
		await capture(stem)
		var old_pivot: Vector2i = scene.model.pairs[0].pivot
		scene.model.pairs[0].pivot.y = -100
		await capture(stem+"_background")
		scene.model.pairs[0].pivot = old_pivot
		var visual: RefCounted = scene.pair_rotation[0]
		var points: Array[Vector2] = visual.points(scene.model.pairs[0],scene.model.motion[0],Rotation.identity_of(scene.model,0))
		records.append({"case":item.id,"frame":row.frame,"phase":scene.model.motion[0].phase,"contact":scene.model.motion[0].contact,"timer":visual.timer,"mode":visual.mode,"dx":visual.native_offset.x,"dy":visual.native_offset.y,"pivot":[points[0].x,points[0].y],"satellite":[points[1].x,points[1].y]})

func bridge_checks() -> void:
	# Exercise main's actual tick bridge, pause and restart rather than a second input implementation.
	scene.model = Fixture.prepare({"samples":[{"x":2,"y":6,"rotation":0}],"id":"bridge"},true)
	scene.arena.reset_state()
	for visual in scene.pair_rotation: visual.reset()
	scene.keyboard_masks.assign([512,256])
	scene.arcade_accumulator = 0.0
	scene._physics_process(1.0/scene.Controls.FRAMES_PER_SECOND)
	assert(scene.model.pairs[0].rotation == 1 and scene.model.pairs[1].rotation == 3)
	assert(scene.pair_rotation[0].timer == 7 and scene.pair_rotation[1].timer == 7)
	var before: String = var_to_str(Fixture.state(scene.model))
	scene.menu_open = true
	scene._physics_process(0.5)
	assert(var_to_str(Fixture.state(scene.model)) == before and scene.pair_rotation[0].timer == 7)
	scene.menu_open = false
	scene.keyboard_masks.assign([0,0])
	await capture("two_players_bridge")
	scene.session_game = false
	scene.continue_round_or_match()
	assert(scene.pair_rotation[0].timer == 0 and scene.pair_rotation[1].timer == 0)
	await capture("restart_bridge")

func run() -> void:
	root.size = Vector2i(1000,700)
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pair_rotation_v10_3_3.json"))
	for item in data.primary: await case_capture(item,true)
	for item in data.cases:
		if item.id in ["wall_0_ccw","irregular_b2","corridor_b1","repeated_rotation","sim_both_rotate_c12","rotate_b2_issued_c12","first_contact_cw_issue_f39","upkick_third_synthetic"]:
			var selected: Dictionary = item.duplicate()
			selected.id = "edge_"+str(item.id)
			await case_capture(selected,false)
	await bridge_checks()
	var file: FileAccess = FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"bridge_pause_restart_two_players":true,"records":records},"  "))
	print("ROTATION_RENDER records=",records.size()," bridge/pause/restart/two players PASS")
	scene.queue_free()
	quit()
