extends "res://presentation/main.gd"
## Isolated presentation lab. No match clock, attack delivery or scoring is advanced here.
const Rules = preload("res://core/resolution.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
const TOPICS := ["Idle", "Disparos", "Granadas", "Dano", "Vitória / derrota", "Crash Orbs", "C4", "Power Gems", "Combo 1X", "Combo 2X", "Combo 3X", "Combo 4X", "Combo 5X", "Ataques simultâneos"]
var topic: int = 0
var actor: int = 2
var topic_tick: int = 0
var paused: bool = false
var autoplay: bool = true
var loop_sequence: bool = false
var playback_speed: float = 1.0
var speed_picker: OptionButton
var loop_button: CheckButton
var picker: OptionButton
var actors: OptionButton
var pause_button: Button
var auto_button: CheckButton
var information: Label
var showcase_accumulator: float = 0.0

func _ready() -> void:
	super._ready()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color("111a2a")
	panel.position = Vector2(0, 614)
	panel.size = Vector2(1000, 86)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.position = Vector2(20, 622)
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)
	picker = OptionButton.new()
	for name in TOPICS: picker.add_item(name)
	picker.custom_minimum_size.x = 184
	picker.item_selected.connect(select_topic)
	row.add_child(picker)
	actors = OptionButton.new()
	for name in ["SAS", "Phoenix", "Ambos"]: actors.add_item(name)
	actors.select(actor)
	actors.item_selected.connect(func(i): actor = i; select_topic(topic))
	row.add_child(actors)
	pause_button = Button.new()
	pause_button.text = "Pausar"
	pause_button.pressed.connect(toggle_pause)
	row.add_child(pause_button)
	var step_button := Button.new()
	step_button.text = "+1 quadro"
	step_button.pressed.connect(single_step)
	row.add_child(step_button)
	var restart_button := Button.new()
	restart_button.text = "Repetir"
	restart_button.pressed.connect(func(): select_topic(topic))
	row.add_child(restart_button)
	auto_button = CheckButton.new()
	auto_button.text = "Catálogo"
	auto_button.button_pressed = autoplay
	auto_button.toggled.connect(func(value):
		autoplay = value
		if value and loop_button != null: loop_button.button_pressed = false)
	row.add_child(auto_button)
	speed_picker = OptionButton.new()
	for text in ["¼×", "½×", "1×", "2×"]: speed_picker.add_item(text)
	speed_picker.select(2)
	speed_picker.item_selected.connect(func(index): playback_speed = [0.25,0.5,1.0,2.0][index]; refresh_information())
	row.add_child(speed_picker)
	loop_button = CheckButton.new()
	loop_button.text = "Loop"
	loop_button.toggled.connect(func(value):
		loop_sequence = value
		if value: auto_button.button_pressed = false)
	row.add_child(loop_button)
	information = Label.new()
	information.position = Vector2(22, 668)
	information.add_theme_font_size_override("font_size", 13)
	layer.add_child(information)
	select_topic(0)

func selected_players() -> Array:
	return [0, 1] if actor == 2 else [actor]

func select_topic(index: int) -> void:
	topic = posmod(index, TOPICS.size())
	if picker != null: picker.select(topic)
	topic_tick = 0
	showcase_accumulator = 0.0
	model.restart()
	arena.reset_state()
	# Park active pairs outside the visible rows and seed the shared preview once.
	for i in range(2): model.pairs[i] = Pair.new(Vector2i(3, 0), 1, 2)
	while model.stream.size() < 2: model.stream.append([2, 5])
	model.stream[1] = [2, 5]
	for player in selected_players():
		if topic == 1: arena.trigger_action(player, "shoot", 30)
		elif topic == 2: arena.trigger_action(player, "grenade", 36)
		elif topic == 3: arena.trigger_action(player, "hit", 26)
		elif topic == 4:
			var winner: int = 0 if actor == 2 else actor
			arena.set_fighter_state(winner, "victory")
			arena.set_fighter_state(1 - winner, "defeat")
		elif topic == 5:
			for c in range(1, 5):
				model.boards[player].cells[12 * 6 + c] = c | 8
				model.boards[player].cells[13 * 6 + c] = (c % 4) + 1
		elif topic == 6:
			model.boards[player].load_cells(Fixtures.build_c4_board())
			Rules.form_powers(model.boards[player])
		elif topic == 7:
			model.boards[player].load_cells(Fixtures.power_board())
			model.boards[player].cells[13 * 6 + 4] = 0
			Rules.form_powers(model.boards[player])
		elif topic >= 8 and topic <= 12:
			present_board(player, Fixtures.chain_board(topic - 7))
	if topic == 13:
		for player in range(2): present_board(player, Fixtures.chain_board(5))
	prime_observation()
	refresh_information()
	queue_redraw()

func prime_observation() -> void:
	for i in range(2):
		arena.prev_scores[i] = model.scores[i]
		arena.prev_cells[i] = model.boards[i].cells.duplicate()
		arena.prev_pair_idx[i] = model.pair_index[i]
		arena.prev_pair_snapshot[i] = model.pairs[i].copy()
		arena.prev_powers[i] = model.boards[i].power_gems.duplicate()

func present_board(player: int, cells: PackedInt32Array) -> void:
	var board = model.boards[player]
	assert(board.load_cells(cells))
	var result: Dictionary = Rules.resolve(board, true)
	model.last_results[player] = result
	model.scores[player] = int(result.score)
	var waves: int = arena.enqueue_visual_waves(player, cells, BOARD_ORIGINS[player], true)
	assert(waves == result.waves.size())

func refresh_information() -> void:
	if information == null: return
	var states: Array[String] = []
	for i in range(2):
		var state: String = arena.fighter_state[i]
		states.append("%s: %s %d/%d" % ["SAS" if i==0 else "Phoenix", state,arena.fighter_anim_frame[i]+1,arena.FIGHTER_ANIMS[i][state].size()])
	information.text = "%s | %s | quadro %d · %.2f× | Espaço: pausa · N: passo · F4: jogar" % [states[0],states[1],topic_tick,playback_speed]

func sequence_duration() -> int:
	if topic == 1: return 75
	if topic == 2: return 110
	if topic == 3: return 70
	return 300 if topic >= 8 else 180

func single_step() -> void:
	paused = true
	pause_button.text = "Continuar"
	advance_showcase()

func toggle_pause() -> void:
	paused = not paused
	pause_button.text = "Continuar" if paused else "Pausar"

func _physics_process(delta: float) -> void:
	if paused: return
	showcase_accumulator += delta * playback_speed
	while showcase_accumulator >= 1.0 / Controls.FRAMES_PER_SECOND:
		showcase_accumulator -= 1.0 / Controls.FRAMES_PER_SECOND
		advance_showcase()

func advance_showcase() -> void:
	topic_tick += 1
	if topic == 6 and topic_tick == 72:
		for player in selected_players(): present_board(player, Fixtures.build_c4_board())
		prime_observation()
	if topic == 7 and topic_tick == 72:
		for player in selected_players(): present_board(player, Fixtures.power_board())
		prime_observation()
	arena.step_from_model(model, BOARD_ORIGINS)
	refresh_information()
	if topic_tick >= sequence_duration():
		if loop_sequence: select_topic(topic)
		elif autoplay: select_topic(topic + 1)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_SPACE: toggle_pause()
		KEY_N: single_step()
		KEY_LEFT: select_topic(topic - 1)
		KEY_RIGHT: select_topic(topic + 1)
		KEY_R: select_topic(topic)
		KEY_F4: get_tree().change_scene_to_file("res://main.tscn")
		_: return
	get_viewport().set_input_as_handled()
