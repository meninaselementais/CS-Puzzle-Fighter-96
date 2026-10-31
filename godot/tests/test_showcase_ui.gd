extends SceneTree
const Session = preload("res://core/match_session.gd")

func _initialize() -> void:
	Session.accept_server_assignment(true,[0,1])
	Session.reveal()
	assert(Session.lock_characters(["sas","phoenix"]))
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1000,700)
	var scene = load("res://animation_showcase.tscn").instantiate()
	root.add_child(scene); scene.set_physics_process(false)
	scene.auto_button.button_pressed = false
	scene.picker.item_selected.emit(6)
	assert(scene.topic == 6)
	scene.actors.item_selected.emit(0)
	assert(scene.actor == 0)
	scene.pause_button.pressed.emit()
	assert(scene.paused)
	var tick: int = scene.topic_tick
	scene._physics_process(1.0)
	assert(scene.topic_tick == tick)
	for _step in range(84): scene.advance_showcase()
	assert(scene.model.frame == 0 and scene.model.last_results[0].waves[0].diamond)
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	assert(img.get_size() == Vector2i(1000,700))
	var out := OS.get_environment("PF_REPORT")
	if out.is_empty(): out = ProjectSettings.globalize_path("res://../relatorios/animation_showcase_v7")
	assert(img.save_png(out.path_join("showcase_ui_c4.png")) == OK)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F4; event.pressed = true
	scene._unhandled_key_input(event)
	await process_frame
	await process_frame
	var game = current_scene
	assert(game != null and game.get_script().resource_path == "res://presentation/main.gd")
	game.set_physics_process(false)
	game._unhandled_key_input(event)
	await process_frame
	await process_frame
	assert(current_scene.get_script().resource_path == "res://presentation/animation_showcase.gd")
	print("SHOWCASE_UI_OK: selectors, pause, frame step, C4 render, F4 round trip")
	quit(0)
