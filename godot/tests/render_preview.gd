extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1000, 700)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.replay_mode = true
	scene.playing = false
	for i in range(scene.keys.size()):
		if scene.keys[i].case == "rotacao_2" and int(scene.keys[i].frame) == 16:
			scene.cursor = i
			break
	scene.apply_frame()
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	assert(image.get_width() == 1000 and image.get_height() == 700)
	var report_dir := OS.get_environment("PF_REPORT")
	if report_dir.is_empty(): report_dir = ProjectSettings.globalize_path("res://../relatorios/automacao_20261028_consolidada")
	assert(image.save_png(report_dir.path_join("prototipo_godot.png")) == OK)
	print("GODOT_RENDER_OK")
	quit(0)
