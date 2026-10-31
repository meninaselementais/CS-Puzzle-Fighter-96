extends SceneTree

const Pair = preload("res://core/pair_model.gd")

func _initialize() -> void:
	call_deferred("capture")

func press(scene, key: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key;event.physical_keycode = key;event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	scene._physics_process(1.0/scene.Controls.FRAMES_PER_SECOND)
	var released = event.duplicate()
	released.pressed = false
	Input.parse_input_event(released)
	Input.flush_buffered_events()

func capture() -> void:
	root.size = Vector2i(1000,700)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	for _frame in range(60): scene._physics_process(1.0/60.0)
	assert(scene.model.frame==59)
	scene.model.restart();scene.arcade_accumulator = 0.0
	press(scene,KEY_RIGHT);assert(scene.model.pairs[0].pivot.x==4)
	press(scene,KEY_X);assert(scene.model.pairs[0].rotation==1)
	press(scene,KEY_A);assert(scene.model.pairs[1].pivot.x==2)
	press(scene,KEY_E);assert(scene.model.pairs[1].rotation==1)
	press(scene,KEY_R);assert(scene.model.pairs[0].pivot.x==3)
	press(scene,KEY_TAB);assert(scene.replay_mode)
	press(scene,KEY_TAB);assert(not scene.replay_mode)
	press(scene,KEY_2);assert(scene.arena.stage_index==1)
	press(scene,KEY_3);assert(scene.arena.stage_index==2)
	press(scene,KEY_1);assert(scene.arena.stage_index==0)
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mechanics_fixtures.json"))
	for fixture in data.fixtures:
		if fixture.id == "power_union_turn2":
			assert(scene.model.boards[0].load_cells(PackedInt32Array(fixture.expected)))
	for fixture in data.deliveries:
		if fixture.id == "attack_red12":
			assert(scene.model.boards[1].load_cells(PackedInt32Array(fixture.expected)))
	scene.model.pairs[0] = Pair.new(Vector2i(3,5),1,5)
	scene.model.pairs[1] = Pair.new(Vector2i(4,4),2,11)
	scene.model.scores.assign([2700,1090])
	scene.model.pending.assign([6,4])
	scene.model.last_results[0] = {"waves":[{},{}],"score":1040}
	scene.arena.trigger_demo_combo(scene.BOARD_ORIGINS)
	scene.status = "Demo CPS-2: Dust2 + SAS vs Phoenix + Power/Diamond/Counter Gems + Combo VFX"
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	assert(image.get_width()==1000 and image.get_height()==700)
	var report_dir := OS.get_environment("PF_REPORT")
	if report_dir.is_empty(): report_dir = ProjectSettings.globalize_path("res://../relatorios/fidelidade_v5")
	DirAccess.make_dir_recursive_absolute(report_dir)
	assert(image.save_png(report_dir.path_join("prototipo_mecanicas.png"))==OK)
	assert(image.save_png(report_dir.path_join("demo_visual_cps2_dust2.png"))==OK)
	scene.arena.set_stage(1)
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(report_dir.path_join("demo_visual_cps2_mirage.png"))==OK)
	scene.arena.set_stage(2)
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(report_dir.path_join("demo_visual_cps2_inferno.png"))==OK)
	scene.arena.set_stage(0)
	print("PRESENTATION_OK: controles P1/P2, rotacao, reinicio, replay e renderizacao")
	quit(0)
