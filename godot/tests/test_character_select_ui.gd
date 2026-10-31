extends SceneTree
const Session = preload("res://core/match_session.gd")
const Selection = preload("res://core/selection_state.gd")
const Catalog = preload("res://core/character_catalog.gd")
var out: String = ""

func _initialize() -> void:
	call_deferred("run")

func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	await send(event)
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	await send(event)

func pad(device: int, button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	await send(event)
	event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = false
	await send(event)

func axis(device: int, value: float, axis_id: JoyAxis = JOY_AXIS_LEFT_X) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis_id
	event.axis_value = value
	await send(event)

func capture(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	# Stretch mantém o canvas arcade; o tamanho físico da janela é independente.
	assert(image.get_width() >= 1000 and image.get_height() >= 700)
	print("UI_CAPTURE ",file_name," window=",root.size," framebuffer=",image.get_size())
	assert(image.save_png(out.path_join(file_name+".png")) == OK)

func change_scene(path: String) -> void:
	change_scene_to_file(path)
	await process_frame
	await process_frame

func run() -> void:
	root.size = Vector2i(1000,700)
	out = OS.get_environment("PF_REPORT")
	if out.is_empty(): out = ProjectSettings.globalize_path("res://../relatorios/coin_flip/final") # lint:ignore res_path — saída criada abaixo
	DirAccess.make_dir_recursive_absolute(out)
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://coin_flip.tscn")
	# Deterministic authoritative fixture: the presentation must never reroll it.
	assert(Session.accept_server_assignment(true,[0,1]))
	var toss_id: int = Session.match_id
	await change_scene("res://coin_flip.tscn")
	var coin: Node = current_scene
	assert(Session.team_for(0) == "CT" and Session.team_for(1) == "TR")
	assert(not coin.revealed and coin.spin_audio.stream != null and coin.spin_audio.playing)
	await create_timer(0.45).timeout
	await capture("01_coin_spinning")
	await key(KEY_ENTER)
	assert(coin.revealed and Session.match_id == toss_id and Session.phase == "select")
	assert(coin.result_audio.stream != null)
	await capture("02_coin_result_ct_tr")
	await create_timer(0.22).timeout
	await key(KEY_ENTER)
	assert(current_scene.get_script().resource_path == "res://presentation/player_select.gd")
	var select: Node = current_scene
	assert(select.selection.available(0) == [0,1,2,3])
	assert(select.selection.available(1) == [4,5,6,7])
	await key(KEY_DOWN)
	await key(KEY_W)
	assert(select.selection.cursors[0] == 0 and select.selection.cursors[1] == 4)
	# No hotkey can cross teams, and direct invalid cursors cannot start.
	select.selection.cursors[0] = 4
	await key(KEY_Z)
	assert(not select.selection.confirmed[0] and select.launch_time < 0.0)
	select.selection.cursors[0] = 0
	await key(KEY_RIGHT)
	await key(KEY_D)
	assert(select.selection.ids() == ["fbi","professional"])
	await capture("03_team_locked_selection")
	await key(KEY_Z)
	await key(KEY_RIGHT)
	assert(select.selection.cursors[0] == 1)
	await key(KEY_X)
	assert(not select.selection.confirmed[0])
	await key(KEY_Z)
	assert(select.launch_time < 0.0)
	await key(KEY_Q)
	await capture("04_selection_confirmed")
	await create_timer(0.72).timeout
	var game: Node = current_scene
	assert(game.get_script().resource_path == "res://presentation/main.gd")
	game.set_physics_process(false)
	assert(game.model.character_ids == [3,3] and Session.characters == ["fbi","professional"])
	assert(Catalog.find(Session.characters[0]).team != Catalog.find(Session.characters[1]).team)
	await capture("05_round_one")
	await key(KEY_X)
	assert(game.model.pairs[0].rotation == 1)
	await key(KEY_R)
	assert(Session.match_id == toss_id and game.model.character_ids == [3,3])
	for round_winner in [0,1,0]:
		game.model.lost[1-round_winner] = true
		game.model.check_winner()
		game.arena.step_from_model(game.model,game.BOARD_ORIGINS)
		game.sync_round_result()
		game.sync_round_result()
		assert(Session.match_id == toss_id and Session.team_for(0) == "CT" and Session.team_for(1) == "TR")
		if Session.phase != "finished":
			await key(KEY_R)
			assert(game.model.winner == -2 and game.model.character_ids == [3,3])
	assert(Session.round_wins == [2,1] and Session.round_number == 3)
	await key(KEY_TAB)
	assert(game.replay_mode)
	await key(KEY_TAB)
	assert(not game.replay_mode and game.model.winner == 0 and Session.phase == "finished")
	await capture("06_best_of_three_finished")
	await key(KEY_R)
	assert(current_scene.get_script().resource_path == "res://presentation/coin_flip.gd")
	assert(Session.match_id == toss_id+1 and Session.phase == "coin" and Session.authority == "local")
	# Opposite fixture; no input skip, auto-transitions after the full animation.
	assert(Session.accept_server_assignment(false,[0,1]))
	await change_scene("res://coin_flip.tscn")
	coin = current_scene
	await create_timer(1.6).timeout
	assert(coin.revealed and Session.team_for(0) == "TR" and Session.team_for(1) == "CT")
	await capture("07_coin_result_tr_ct")
	await create_timer(1.15).timeout
	select = current_scene
	assert(select.selection.ids() == ["phoenix","sas"])
	# Controller path: D-pad, both analog axes, deadzone and button confirmations.
	await pad(0,JOY_BUTTON_DPAD_DOWN)
	await pad(1,JOY_BUTTON_DPAD_UP)
	assert(select.selection.ids() == ["phoenix","sas"])
	await pad(0,JOY_BUTTON_DPAD_RIGHT)
	await axis(1,0.8)
	await axis(1,0.85)
	assert(select.selection.ids() == ["professional","fbi"])
	await axis(1,0.0)
	await axis(1,0.1)
	assert(select.selection.cursors[1] == 1)
	await axis(0,0.9,JOY_AXIS_LEFT_Y)
	assert(select.selection.cursors[0] == 5)
	await capture("08_controller_reversed_teams")
	await pad(0,JOY_BUTTON_A)
	await pad(0,JOY_BUTTON_B)
	assert(not select.selection.confirmed[0])
	await pad(0,JOY_BUTTON_A)
	assert(select.launch_time < 0.0)
	await pad(1,JOY_BUTTON_A)
	await create_timer(0.72).timeout
	game = current_scene
	game.set_physics_process(false)
	assert(game.model.character_ids == [3,3] and Session.characters == ["professional","fbi"])
	await capture("09_reversed_match")
	await pad(0,JOY_BUTTON_START)
	assert(game.menu_open)
	var frame: int = game.model.frame
	game._physics_process(1.0)
	assert(game.model.frame == frame)
	await capture("10_new_match_menu")
	toss_id = Session.match_id
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	assert(current_scene.get_script().resource_path == "res://presentation/coin_flip.gd")
	assert(Session.match_id == toss_id+1)
	# A direct main-scene entry with invalid identities must redirect to the coin.
	Session.characters.assign(["sas","fbi"])
	await change_scene("res://main.tscn")
	await process_frame
	await process_frame
	assert(current_scene.get_script().resource_path == "res://presentation/coin_flip.gd")
	# Stretching keeps the fixed arcade canvas usable in a larger window.
	root.size = Vector2i(1280,900)
	current_scene.skip()
	await create_timer(0.22).timeout
	await capture("11_coin_large_window")
	current_scene.finish()
	await process_frame
	await process_frame
	await capture("12_selection_large_window")
	print("COIN_SELECT_UI_OK: real viewport keyboard/gamepad events, coin/audio, skip/auto, locked sides, three rounds, fresh match, invalid-entry guard, two window sizes; 12 captures")
	quit(0)
