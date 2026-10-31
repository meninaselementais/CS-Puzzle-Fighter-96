extends Node2D

const Match = preload("res://core/match_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Replay = preload("res://adapters/mame_replay.gd")
const Gem = preload("res://core/gem_rules.gd")
const Controls = preload("res://core/control_model.gd")
const Arena = preload("res://presentation/cs_arena.gd")
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

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	arcade_accumulator += delta
	if arcade_accumulator < 1.0 / Controls.FRAMES_PER_SECOND: return
	arcade_accumulator -= 1.0 / Controls.FRAMES_PER_SECOND
	if not replay_mode:
		for player in range(2):
			var controls: Array = [KEY_LEFT, KEY_RIGHT, KEY_DOWN] if player == 0 else [KEY_A, KEY_D, KEY_S]
			var direction := int(Input.is_physical_key_pressed(controls[1])) - int(Input.is_physical_key_pressed(controls[0]))
			if observed_pair[player] != model.pair_index[player]:
				observed_pair[player] = model.pair_index[player]
				controls_model.reset_pair(player)
			if controls_model.horizontal(player,direction):
				model.move(player, Vector2i(direction, 0))
			if controls_model.drop(player,Input.is_physical_key_pressed(controls[2]),model.pair_age[player]): model.soft_drop(player)
		model.tick()
		arena.step_from_model(model, BOARD_ORIGINS)
	queue_redraw()

func _process(delta: float) -> void:
	if replay_mode and playing and not keys.is_empty():
		elapsed += delta
		if elapsed >= 0.3:
			elapsed = 0.0
			cursor = (cursor + 1) % keys.size()
			apply_frame()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
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
	if key == KEY_TAB:
		replay_mode = not replay_mode
		if replay_mode:
			apply_frame()
		else:
			model.restart()
			arena.reset_state()
		return
	if replay_mode:
		if key == KEY_SPACE:
			playing = not playing
		return
	match key:
		KEY_Z: model.rotate(0, -1)
		KEY_X: model.rotate(0, 1)
		KEY_Q: model.rotate(1, -1)
		KEY_E: model.rotate(1, 1)
		KEY_R:
			model.restart()
			arena.reset_state()
			controls_model = Controls.new()
			observed_pair = [-1,-1]

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
	var next_pairs := [get_next_colors(0), get_next_colors(1)]
	arena.draw_central_arena_and_hud(self, font, model, next_pairs)
	# Desenha as gemas dentro das caixas NEXT centrais
	for i in range(2):
		var nx := 284.0 if i == 0 else 652.0
		var ny := 56.0
		arena.draw_gem_sprite(self, Vector2(nx + 32, ny + 32), int(next_pairs[i][1]), Gem, i * 10 + 1)
		arena.draw_gem_sprite(self, Vector2(nx + 32, ny + 76), int(next_pairs[i][0]), Gem, i * 10 + 2)
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
		var points = pair.positions()
		var sub_y := 0.0
		var pair_scale := Vector2.ONE
		if not replay_mode:
			var below_pair = Pair.new(pair.pivot + Vector2i(0, 1), pair.colors[0], pair.colors[1])
			below_pair.rotation = pair.rotation
			if model.boards[i].can_place(below_pair):
				sub_y = float(model.frame % model.GRAVITY_TICKS) / float(model.GRAVITY_TICKS)
			if bool(model.accelerated[i]):
				pair_scale = Vector2(0.94, 1.07)
		for n in range(2):
			var point := Vector2(points[n])
			if replay_mode:
				point.y += visual_rows[i] - pair.pivot.y
			else:
				point.y += sub_y
				if bool(model.accelerated[i]) and point.y >= 2.25:
					var trail_c := origin + Vector2(point.x * TILE + TILE / 2.0, (point.y - 2.38) * TILE + TILE / 2.0)
					draw_circle(trail_c, 11.0, Color(1.0, 1.0, 1.0, 0.22))
			gem(point, origin, pair.colors[n], 90 + n, pair_scale)
	# Desenha projéteis, explosões e banners de combo sobre os tabuleiros e a arena
	arena.draw_foreground_vfx(self, font)
	# Rodapé de comandos do gabinete
	var mode := "REPLAY DO MAME" if replay_mode else "CPS-2 ARCADE DUEL — CS PUZZLE FIGHTER '96"
	if model.winner >= 0 and not replay_mode: mode = "P%d VENCEU — PRESSIONE R PARA REVANCHE" % (model.winner + 1)
	elif model.winner == -1 and not replay_mode: mode = "EMPATE — PRESSIONE R PARA REVANCHE"
	Arena.draw_outlined_text(self, font, Vector2(36, 658), mode + "   |   P1 (SAS): Setas, Z/X   |   P2 (PHOENIX): A/D/S, Q/E   |   1/2/3/M: Cenário   |   R: Reiniciar", 14, Color("ffe868"))
	Arena.draw_outlined_text(self, font, Vector2(36, 682), "TAB: Replay MAME   |   Espaço: Pausa   |   " + status, 13, Color("9cc8ff"))
