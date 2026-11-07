extends RefCounted
## Relógio da dupla: valores medidos no MAME 0.289, spf2tu USA 960620.
var phase: int = 0
var contact: int = 0
var contacts: int = 0
var upkicks: int = 0
var rotation_disabled: bool = false
var offset: int = 0
var fall_countdown: int = 1
var fall_interval: int = 1
var fall_increment: int = 1
var fall_offset: int = -16
var fall_start: bool = true
var down_counter: int = 1
var down_timer: int = 0
var horizontal_timer: int = 0
var previous_input: int = 0
var manual_bonus: bool = false
var gravity_moved: bool = false
var pre_resolve_cells: PackedInt32Array = PackedInt32Array()
var result: Dictionary = {}
var clear_timer: int = 0
var counters_advanced: bool = false
var flood_steps: int = 0
var flood_active: bool = false
var chain_count: int = 0
var attack_row: int = 0
var attack_slot: int = 0

func supported(model: RefCounted, player: int) -> bool:
	var candidate: RefCounted = model.pairs[player].copy()
	candidate.pivot.y += 1
	return not model.boards[player].can_place(candidate)

func enter_contact() -> void:
	offset = 0
	contacts += 1
	contact = 1 if contacts == 8 else 16

func rotate(model: RefCounted, player: int, direction: int) -> bool:
	if phase != 0 or contact in [1,16] or rotation_disabled: return false
	var old_pivot: Vector2i = model.pairs[player].pivot
	var old_rotation: int = model.pairs[player].rotation
	if not model.rotate_geometry(player,direction): return false
	if model.pairs[player].pivot.y < old_pivot.y:
		upkicks += 1
		if upkicks > 2:
			upkicks = 5
			rotation_disabled = true
			contact = 1
			model.pairs[player].rotation = old_rotation
	return true

func deposit(model: RefCounted, player: int, mask: int) -> void:
	if not model.boards[player].commit(model.pairs[player]):
		model.lost[player] = true
		model.check_winner()
		return
	if manual_bonus or mask == 4: model.scores[player] += 10
	model.accelerated[player] = false
	manual_bonus = false
	phase = 1
	model.turn_number[player] += 1
	contact = 0
	contacts = 0
	upkicks = 0
	rotation_disabled = false
	model.pair_age[player] = 0
	model.pairs[player].pivot = Vector2i(3,-1)
	model.pairs[player].rotation = 0
	offset = 0
	fall_countdown = 1
	down_counter = 1
	gravity_moved = false
	counters_advanced = false
	flood_steps = 0
	flood_active = false
	chain_count = 0
	clear_timer = 0
	attack_row = 0
	attack_slot = 0
	pre_resolve_cells = PackedInt32Array()
	result = {"waves": [], "score": 0, "attack": 0, "converted": 0, "gravity": 0}

func spawn_counter_row(model: RefCounted, player: int) -> int:
	var board: RefCounted = model.boards[player]
	var source: int = 1 - player
	var placed: int = 0
	if attack_slot == 0 and model.pending[player] >= 6:
		for col in range(6):
			var color: int = model.Economy.counter_color(model.character_ids[source], attack_row, col)
			if board.cells[col] == 0 or attack_row == 0:
				board.cells[col] = model.Gem.counter(color, 5)
				placed += 1
		model.pending[player] -= 6
		attack_row += 1
		return placed
	var cols: Array = model.Economy.columns(model.residual_index[player])
	while model.pending[player] > 0 and attack_slot < 6:
		var col: int = int(cols[attack_slot])
		if board.cells[col] == 0:
			var color: int = model.Economy.counter_color(model.character_ids[source], attack_row, col)
			board.cells[col] = model.Gem.counter(color, 5)
			placed += 1
		model.pending[player] -= 1
		attack_slot += 1
	if attack_slot >= 6:
		attack_row += 1
		attack_slot = 0
	return placed

func resolve_frame(model: RefCounted, player: int) -> void:
	var board: RefCounted = model.boards[player]
	if phase in [1,3,10]:
		var moved: int = model.Rules.gravity_step(board)
		if moved > 0:
			result["gravity"] = int(result.get("gravity", 0)) + moved
			gravity_moved = true
			return
		if gravity_moved:
			gravity_moved = false
			phase = 1
			return
		phase += 1
	elif phase == 2:
		if not counters_advanced:
			counters_advanced = true
			result["converted"] = int(result.get("converted", 0)) + model.Rules.advance_counters(board)
		phase = 3
	elif phase in [4,12,13,14,15]:
		if not flood_active:
			model.Rules.form_powers(board)
		phase += 1
	elif phase == 8:
		if not flood_active:
			model.Rules.form_powers(board)
			flood_steps = model.Rules.count_flood_steps(board)
			if flood_steps > 0:
				if chain_count == 0:
					pre_resolve_cells = board.cells.duplicate()
				flood_active = true
		if flood_steps > 0:
			flood_steps -= 1
			clear_timer = 40
			phase = 3
		else:
			flood_active = false
			phase = 9
	elif phase == 11:
		if clear_timer > 0:
			clear_timer -= 1
			if clear_timer > 0:
				return
			chain_count += 1
			var wave: Dictionary = model.Rules.resolve_single_wave(board, chain_count)
			if not wave.is_empty():
				result["waves"].append(wave)
				result["score"] = int(result.get("score", 0)) + int(wave.score)
				result["attack"] = int(result.get("attack", 0)) + int(wave.attack)
				model.last_results[player] = result
				model.scores[player] += int(wave.score)
				var queue_before: int = model.pending[1 - player]
				model.pending[1 - player] = mini(250, model.pending[1 - player] + model.cancel_attack(player, int(wave.attack)))
				model.record_sent_attack(player,model.pending[1 - player]-queue_before)
			phase = 3
			return
		model.last_results[player] = result
		phase = 12
	elif phase == 18:
		if not model.lost[1 - player] and model.pending[player] > 0:
			var spawned: int = spawn_counter_row(model, player)
			if spawned > 0 and not model.first_attack:
				model.scores[1 - player] += 1000
				model.first_attack = true
		phase = 19
	elif phase == 19:
		var moved: int = model.Rules.counter_gravity_step(board)
		if moved > 0:
			phase = 17
			return
		phase = 0
		model.lost[player] = model.lost[player] or board.cells[15] != 0
		if not model.lost[player]:
			model.pair_index[player] += 1
			model.spawn(player)
		model.check_winner()
	else:
		phase += 1

func step(model: RefCounted, player: int, mask: int) -> void:
	if phase != 0:
		previous_input = mask
		resolve_frame(model,player)
		return
	var departed: bool = false
	if contact > 0:
		if not supported(model,player):
			contact = 0
			fall_start = true
			horizontal_timer = 0
			mask &= 0xfff0
			model.pairs[player].pivot.y += 1
			offset = fall_offset
			fall_countdown = 10
			fall_start = false
			departed = true
		else:
			contact -= 1
			if contact == 0:
				deposit(model,player,mask)
				previous_input = mask
				return
	if not departed:
		model.pair_age[player] += 1
		if mask & 15 == 4 and model.pair_age[player] > 16:
			down_counter += 1
			down_timer += 1
			var interval: int = 4 if down_counter < 6 else 2 if down_counter < 12 else 1
			if down_timer >= interval:
				down_timer = 0
				fall_countdown = 0
				offset = 0
				model.accelerated[player] = true
		fall_countdown += contact - 1
		if fall_countdown < 0:
			fall_countdown = 10 if fall_start else fall_interval
			fall_start = false
			var can_descend: bool = true
			if offset != 0:
				offset += fall_increment
				if offset < 0: can_descend = false
				elif offset > 0:
					offset = -4
					can_descend = false
			if can_descend and contact == 0:
				if supported(model,player): enter_contact()
				else:
					model.pairs[player].pivot.y += 1
					offset = fall_offset
	if contact != 1:
		var edges: int = mask & ~previous_input
		var kicked: bool = false
		var pair: RefCounted = model.pairs[player]
		var point: Vector2i = pair.pivot
		var left: bool = point.x == 0 or model.boards[player].cells[point.y*6+point.x-1] != 0
		var right: bool = point.x == 5 or model.boards[player].cells[point.y*6+point.x+1] != 0
		if edges & 768 and pair.rotation in [0,2] and left and right:
			rotate(model,player,1)
		else:
			for entry in [[512,1],[256,-1]]:
				if edges & int(entry[0]):
					var before: Vector2i = model.pairs[player].pivot
					rotate(model,player,int(entry[1]))
					kicked = kicked or model.pairs[player].pivot != before
		if not kicked:
			for entry in [[1,1],[2,-1]]:
				var bit: int = int(entry[0])
				if edges & bit:
					horizontal_timer = 0
					model.move(player,Vector2i(int(entry[1]),0))
				elif mask & bit:
					horizontal_timer += 1
					if horizontal_timer >= 12: model.move(player,Vector2i(int(entry[1]),0))
	previous_input = mask
