extends Node2D

const Match = preload("res://core/match_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Replay = preload("res://adapters/mame_replay.gd")
const Gem = preload("res://core/gem_rules.gd")
const Controls = preload("res://core/control_model.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const Hud = preload("res://presentation/hud_presenter.gd")
const PairRotation = preload("res://presentation/pair_rotation_visual.gd")
var pair_rotation: Array[RefCounted] = [PairRotation.new(),PairRotation.new()]
const Session = preload("res://core/match_session.gd")
const MenuInput = preload("res://presentation/selection_input.gd")
var input_decoder: RefCounted = MenuInput.new()
var session_game: bool = false
const Selection = preload("res://core/selection_state.gd")
var pause_menu: CanvasLayer
var menu_open: bool = false

const TILE: int = 32
const BOARD_ORIGINS: Array[Vector2] = [Vector2(64, 108), Vector2(744, 108)]

var model = Match.new()
var replay = Replay.new()
var arena = Arena.new()
var replay_mode: bool = false
var playing: bool = true
var cursor: int = 0
var elapsed: float = 0.0
var keys: Array = []
var status: String = ""
var visual_rows: Array[float] = [0.0, 0.0]
var controls_model = Controls.new()
var observed_pair: Array[int] = [-1,-1]
var arcade_accumulator: float = 0.0
var keyboard_masks: Array[int] = [0,0]
var joy_masks: Array[int] = [0,0]
var latched_masks: Array[int] = [0,0]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# V11.4.2: glass presentation is OFF unless PF_GLASS=1 (quality: PF_GLASS_QUALITY=high|medium|low). Key G toggles it.
	if OS.get_environment("PF_GLASS") in ["1","true","on"]:
		arena.set_glass_presentation(true,OS.get_environment("PF_GLASS_QUALITY"))
	# O Showcase mantém sua referência original SAS/Phoenix, independente da seleção.
	if get_script().resource_path == "res://presentation/main.gd":
		if not Selection.apply_to_match(model):
			get_tree().change_scene_to_file("res://coin_flip.tscn")
			set_physics_process(false)
			return
		session_game = true
		arena.configure_characters(Session.characters)
		arena.wins.assign(Session.round_wins)
		if Session.phase in ["between_rounds","finished"]: model.winner = Session.last_round_result
		create_pause_menu()
	if replay.load_file("res://data/replay_mame.json"):
		for item in replay.frames:
			if item.players[0].colors[0] != 0 or item.players[1].colors[0] != 0:
				keys.append(item)
		status = "%d quadros MAME carregados" % replay.frames.size()
	else:
		status = replay.error_message

func apply_frame() -> void:
	if keys.is_empty():
		return
	var item: Dictionary = keys[cursor]
	for i in range(2):
		var player: Dictionary = item.players[i]
		model.boards[i].load_cells(PackedInt32Array(player.cells))
		model.pairs[i] = Pair.new(Vector2i(int(player.x), int(player.y)), int(player.colors[0]), int(player.colors[1]))
		model.pairs[i].rotation = int(player.rotation)
		visual_rows[i] = float(player.render_y)
	status = "MAME | %s | quadro %d | %d/%d" % [item.case, item.frame, cursor + 1, keys.size()]

func _physics_process(delta: float) -> void:
	if menu_open: return
	arcade_accumulator += delta
	var quantum: float = 1.0 / Controls.FRAMES_PER_SECOND
	while arcade_accumulator >= quantum:
		arcade_accumulator -= quantum
		if not replay_mode:
			for player in range(2):
				var mask: int = keyboard_masks[player] | joy_masks[player] | latched_masks[player]
				var keys_now: Array = [KEY_RIGHT,KEY_LEFT,KEY_DOWN,KEY_X,KEY_Z] if player == 0 else [KEY_D,KEY_A,KEY_S,KEY_E,KEY_Q]
				var bits: Array = [1,2,4,512,256]
				for index in range(keys_now.size()):
					if Input.is_physical_key_pressed(keys_now[index]) or Input.is_key_pressed(keys_now[index]): mask |= int(bits[index])
				if Input.get_connected_joypads().has(player):
					var axis: float = Input.get_joy_axis(player,JOY_AXIS_LEFT_X)
					if absf(axis)>0.55: mask |= 1 if axis>0 else 2
					if Input.get_joy_axis(player,JOY_AXIS_LEFT_Y)>0.55: mask |= 4
				model.input_masks[player] = mask
				latched_masks[player] = 0
			var before_rotation: Array[Dictionary] = [PairRotation.snapshot(model,0),PairRotation.snapshot(model,1)]
			model.tick()
			for player in range(2):
				pair_rotation[player].step(before_rotation[player],PairRotation.snapshot(model,player))
			arena.step_from_model(model,BOARD_ORIGINS)
			sync_round_result()
	queue_redraw()

func _process(delta: float) -> void:
	if menu_open: return
	if replay_mode and playing and not keys.is_empty():
		elapsed += delta
		if elapsed >= 0.3:
			elapsed = 0.0
			cursor = (cursor + 1) % keys.size()
			apply_frame()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var mappings: Array = [[KEY_RIGHT,KEY_LEFT,KEY_DOWN,KEY_X,KEY_Z],[KEY_D,KEY_A,KEY_S,KEY_E,KEY_Q]]
	for player in range(2):
		var index: int = mappings[player].find(key)
		if index >= 0:
			var bit: int = [1,2,4,512,256][index]
			if event.pressed:
				keyboard_masks[player] |= bit
				latched_masks[player] |= bit
			else: keyboard_masks[player] &= ~bit
	if not event.pressed: return
	if key == KEY_ESCAPE:
		toggle_menu()
		return
	if menu_open: return
	if key == KEY_F4:
		get_tree().change_scene_to_file("res://animation_showcase.tscn")
		return
	if key == KEY_M:
		arena.cycle_stage(1)
		queue_redraw()
		return
	elif key == KEY_1 or key == KEY_F1:
		arena.set_stage(0)
		queue_redraw()
		return
	elif key == KEY_2 or key == KEY_F2:
		arena.set_stage(1)
		queue_redraw()
		return
	elif key == KEY_3 or key == KEY_F3:
		arena.set_stage(2)
		queue_redraw()
		return
	if key == KEY_G:
		var glass_on: bool = arena.set_glass_presentation(not arena.glass_enabled,OS.get_environment("PF_GLASS_QUALITY"))
		print("GLASS_PRESENTATION ",glass_on)
		queue_redraw()
		return
	if key == KEY_TAB:
		replay_mode = not replay_mode
		if replay_mode:
			for visual in pair_rotation: visual.reset()
			apply_frame()
		else:
			model.restart()
			for visual in pair_rotation: visual.reset()
			arena.reset_state()
			if session_game and Session.phase in ["between_rounds","finished"]: model.winner = Session.last_round_result
		return
	if replay_mode:
		if key == KEY_SPACE:
			playing = not playing
		return
	match key:
		KEY_R: continue_round_or_match()

func gem(point: Vector2, origin: Vector2, code: int, phase_seed: int = 0, scale_mod: Vector2 = Vector2.ONE) -> void:
	if point.y < 2.0 or point.y >= 14.0 or point.x < 0.0 or point.x >= 6.0:
		return
	var center := origin + Vector2(point.x * TILE + TILE / 2.0, (point.y - 2.0) * TILE + TILE / 2.0)
	arena.draw_gem_sprite(self, center, code, Gem, phase_seed, scale_mod)

func power_gem(rect: Rect2i, origin: Vector2, code: int, player: int = 0) -> void:
	var offset := arena.get_cell_visual_offset(player, rect.position.y * 6 + rect.position.x)
	arena.draw_power_gem_crystal(self, rect, origin + Vector2(0, offset), code, Gem.color(code), player)

func get_next_colors(player: int) -> Array:
	var next_idx: int = model.pair_index[player] + 1
	while model.stream.size() <= next_idx:
		var idx: int = model.stream.size()
		var c := [model.rng.randi_range(1, 4), model.rng.randi_range(1, 4)]
		if (idx + 1) % 25 == 0:
			c[1] = 5
		elif idx % 5 == 1:
			c[1] |= 8
		model.stream.append(c)
	return model.stream[next_idx]

func _draw() -> void:
	position = arena.get_screen_shake_offset()
	var font := ThemeDB.fallback_font
	arena.draw_backdrop(self)
	# Keep V10 generation order and frequency; the presenter reads the populated cache.
	var _next_pairs: Array = [get_next_colors(0), get_next_colors(1)]
	var hud_snapshot: Dictionary = Hud.snapshot(model, session_game and not replay_mode)
	arena.draw_central_arena_and_hud(self, font, model, hud_snapshot)
	# Desenha os dois poços de puzzle laterais (P1 e P2)
	for i in range(2):
		var origin: Vector2 = BOARD_ORIGINS[i]
		arena.draw_board_well_frame(self, font, i, origin, model.pending[i])
		var draw_cells: PackedInt32Array = arena.get_visual_cells(i, model.boards[i].cells)
		var draw_powers: Array = arena.get_visual_powers(i, model.boards[i].power_gems)
		var covered := {}
		for rect in draw_powers:
			for index in model.boards[i].indices(rect): covered[index] = true
			power_gem(rect, origin, draw_cells[rect.position.y * 6 + rect.position.x], i)
		for y in range(2, 14):
			for x in range(6):
				var idx := y * 6 + x
				var code: int = draw_cells[idx]
				if code != 0 and not covered.has(idx) and not arena.is_cell_hidden_by_flash(i, idx):
					var wy := float(y) + arena.get_cell_visual_offset(i, idx) / float(TILE)
					var sq: Vector2 = arena.get_cell_squash_scale(i, idx)
					gem(Vector2(x, wy), origin, code, idx, sq)
		# Desenha pedras em fase de Pré-Explosão (Flash/Tremor/Ativação de Orbe e C4)
		arena.draw_combo_flashes(self, i, Gem)
		var result: Dictionary = model.last_results[i]
		if not result.is_empty() and not result.waves.is_empty():
			Arena.draw_outlined_text(self, font, origin + Vector2(6, 412), "%d CADEIA(S)  +%d PTS" % [result.waves.size(), result.score], 16, Color("55ff90"))
		var pair = model.pairs[i]
		if model.lost[i]: continue
		if not replay_mode:
			pair_rotation[i].draw_pair(self,arena,pair,model.motion[i],PairRotation.identity_of(model,i),origin,model.lost[i])
			continue
		var points = pair.positions()
		for n in range(2):
			var point := Vector2(points[n])
			point.y += visual_rows[i] - pair.pivot.y
			gem(point, origin, pair.colors[n], 90 + n)
	# Desenha projéteis, explosões e banners de combo sobre os tabuleiros e a arena
	arena.draw_foreground_vfx(self, font)
	# Rodapé de comandos do gabinete
	var mode := "REPLAY DO MAME" if replay_mode else "CPS-2 ARCADE DUEL — CS PUZZLE FIGHTER '96"
	if model.winner >= 0 and not replay_mode: mode = "P%d VENCEU O ROUND — R: CONTINUAR" % (model.winner + 1)
	elif model.winner == -1 and not replay_mode: mode = "EMPATE — R: REPETIR ROUND"
	if session_game:
		var series: String = "ROUND %d / MD3     P1 %s  %d - %d  P2 %s" % [Session.round_number,Session.team_for(0),Session.round_wins[0],Session.round_wins[1],Session.team_for(1)]
		if Session.phase == "finished":
			series = "P%d VENCEU A PARTIDA  %d - %d / R: NOVO SORTEIO" % [Session.winner+1,Session.round_wins[0],Session.round_wins[1]]
			mode = "P%d VENCEU A PARTIDA — R: NOVO SORTEIO" % (Session.winner+1)
		draw_rect(Rect2(275,607,450,25),Color("090f20"))
		Arena.draw_outlined_text(self,font,Vector2(283,625),series,13,Color("ffe49a"))
	Arena.draw_outlined_text(self, font, Vector2(36, 658), mode + "   |   P1: Setas, Z/X   |   P2: A/D/S, Q/E   |   1/2/3/M: Cenário   |   R: Reiniciar", 14, Color("ffe868"))
	Arena.draw_outlined_text(self, font, Vector2(36, 682), "ESC: Menu   |   F4: Animation Showcase   |   TAB: Replay MAME   |   " + status, 13, Color("9cc8ff"))

	# Historical presentation fixtures intentionally have no V11.5 renderer.
	if arena.has_method("draw_attack_warning_hud"): arena.draw_attack_warning_hud(self,font,hud_snapshot)

func create_pause_menu() -> void:
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 10
	add_child(pause_menu)
	var overlay := ColorRect.new()
	overlay.color = Color(0.015,0.025,0.07,0.88)
	overlay.size = Vector2(1000,700)
	pause_menu.add_child(overlay)
	var title := Label.new()
	title.text = "PAUSA / PLAYER MENU"
	title.position = Vector2(300,220)
	title.size = Vector2(400,50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",28)
	overlay.add_child(title)
	var labels := ["CONTINUAR", "NOVA PARTIDA / SORTEAR LADOS", "ANIMATION SHOWCASE"]
	for index in range(labels.size()):
		var button := Button.new()
		button.text = labels[index]
		button.position = Vector2(320,290+index*64)
		button.size = Vector2(360,50)
		button.add_theme_font_size_override("font_size",18)
		overlay.add_child(button)
		match index:
			0: button.pressed.connect(toggle_menu)
			1: button.pressed.connect(return_to_selection)
			2: button.pressed.connect(func(): get_tree().change_scene_to_file("res://animation_showcase.tscn"))
	pause_menu.hide()

func toggle_menu() -> void:
	if pause_menu == null: return
	menu_open = not menu_open
	pause_menu.visible = menu_open
	if menu_open:
		pause_menu.get_child(0).get_child(1).grab_focus()
	else:
		get_viewport().gui_release_focus()

func return_to_selection() -> void:
	Session.close_match()
	get_tree().change_scene_to_file("res://coin_flip.tscn")

func sync_round_result() -> void:
	if session_game and not replay_mode and model.winner != -2:
		if Session.record_round(model.winner):
			arena.wins.assign(Session.round_wins)
			queue_redraw()

func continue_round_or_match() -> void:
	sync_round_result()
	if session_game and Session.phase == "finished":
		return_to_selection()
		return
	if session_game and Session.phase == "between_rounds": Session.advance_round()
	model.restart()
	for visual in pair_rotation: visual.reset()
	arena.reset_state()
	if session_game: arena.wins.assign(Session.round_wins)
	controls_model = Controls.new()
	observed_pair = [-1,-1]
	arcade_accumulator = 0.0
	keyboard_masks = [0,0]
	joy_masks = [0,0]
	latched_masks = [0,0]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton: return
	if event.device in [0,1]:
		var buttons: Array = [JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_A,JOY_BUTTON_B]
		var index: int = buttons.find(event.button_index)
		if index >= 0:
			var bit: int = [1,2,4,512,256][index]
			if event.pressed:
				joy_masks[event.device] |= bit
				latched_masks[event.device] |= bit
			else: joy_masks[event.device] &= ~bit
	var command: Dictionary = input_decoder.decode(event)
	if command.is_empty(): return
	if command.command == "menu":
		toggle_menu()
	elif not menu_open:
		if model.winner != -2 and command.command == "confirm": continue_round_or_match()
