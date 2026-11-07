extends SceneTree
const Hud = preload("res://presentation/hud_presenter.gd")
const Session = preload("res://core/match_session.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed, value.state]
	if value is RefCounted:
		var result: Dictionary = {}
		var script: Script = value.get_script()
		for property in script.get_script_property_list(): result[property.name] = state(value.get(property.name))
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(state(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = state(value[key])
		return result
	return value

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	expect(Session.accept_server_assignment(true, [0,1]), "real local scene assignment")
	Session.reveal()
	expect(Session.lock_characters(["sas","phoenix"]), "real characters")
	root.size = Vector2i(1000,700)
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var before_image: Image = root.get_texture().get_image()
	var before_state: String = JSON.stringify(state(scene.model))
	var before_session: String = JSON.stringify([Session.match_id, Session.phase, Session.round_wins, Session.rng.state])
	var first: Dictionary = Hud.snapshot(scene.model, scene.session_game)
	expect(first.players[0].next_pair.available and first.players[1].next_pair.available, "real draw already populated both NEXT caches")
	for player in range(2):
		var value: Dictionary = first.players[player].next_pair.value
		var cached: Array = scene.model.stream[int(scene.model.pair_index[player])+1]
		expect([value.pivot,value.satellite] == cached, "NEXT matches real scene cache")
	for repeat in range(1000): expect(Hud.snapshot(scene.model, scene.session_game) == first, "real scene repeated read %d" % repeat)
	expect(JSON.stringify(state(scene.model)) == before_state, "all scene model properties remain unchanged")
	expect(JSON.stringify([Session.match_id,Session.phase,Session.round_wins,Session.rng.state]) == before_session, "session unchanged")
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var after_image: Image = root.get_texture().get_image()
	expect(before_image.get_size() == Vector2i(1000,700), "actual window framebuffer")
	expect(before_image.get_data() == after_image.get_data(), "HUD queries do not change a single pixel")
	expect(JSON.stringify(state(scene.model)) == before_state, "NEXT still unchanged after redraw")
	var folder: String = OS.get_environment("PF_REPORT")
	expect(not folder.is_empty(), "explicit output directory required")
	if not folder.is_empty():
		expect(before_image.save_png(folder.path_join("before.png")) == OK, "save before")
		expect(after_image.save_png(folder.path_join("after.png")) == OK, "save after")
		var file: FileAccess = FileAccess.open(folder.path_join("hud_scene.json"),FileAccess.WRITE)
		if file == null:
			push_error("Cannot write hud_scene.json")
			quit(1)
			return
		file.store_string(JSON.stringify({"checks": checks, "queries": 1000, "pixel_identical": before_image.get_data() == after_image.get_data(), "failures": failures, "snapshot": first},"  "))
	print("HUD_SCENE checks=",checks," failures=",failures)
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
