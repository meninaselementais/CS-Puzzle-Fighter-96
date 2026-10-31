extends SceneTree
## Captures actual renderer output at half the native tick rate, without advancing game rules.
var timeline: Array = []

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1000,700)
	var scene = load("res://animation_showcase.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.autoplay = false
	scene.auto_button.button_pressed = false
	var args := OS.get_cmdline_user_args()
	var out := ProjectSettings.globalize_path("res://../relatorios/animacoes_v9/demo_v9")
	for i in range(args.size()-1):
		if args[i]=="--output": out=args[i+1]
	if "--reference-v8" in args:
		scene.arena = load("res://tests/reference_v8/cs_arena.gd").new()
		scene.select_topic(0)
	var frames := out.path_join("frames_final")
	DirAccess.make_dir_recursive_absolute(frames)
	var count := 0
	for section in range(scene.TOPICS.size()+1):
		var topic := section if section<scene.TOPICS.size() else 4
		if section==scene.TOPICS.size(): scene.actor=1
		scene.select_topic(topic)
		var length: int = [90,60,90,60,90,90,180,180,120,140,160,180,220,240][topic] if section<scene.TOPICS.size() else 120
		var title: String = scene.TOPICS[topic] if section<scene.TOPICS.size() else "Vitória Phoenix"
		timeline.append({"topic":title,"first_frame":count,"native_ticks":length})
		for tick in range(length):
			scene.advance_showcase()
			if tick % 2 != 0: continue
			await process_frame
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			assert(picture.save_jpg(frames.path_join("frame_%05d.jpg" % count), 0.94) == OK)
			if tick in [0,4,6,10,12,24,48,84,120,168,240]:
				assert(picture.save_png(out.path_join("showcase_%02d_%03d.png" % [section,tick])) == OK)
			count += 1
		print("CAPTURED ", scene.TOPICS[topic], " total frames=", count)
	var file := FileAccess.open(out.path_join("timeline.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps":scene.Controls.FRAMES_PER_SECOND / 2.0,"frames":count,"topics":timeline},"\t"))
	file.close()
	print("SHOWCASE_CAPTURE_OK ",count)
	quit(0)
