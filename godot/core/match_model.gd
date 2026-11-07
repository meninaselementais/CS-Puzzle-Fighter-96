extends RefCounted

const Board = preload("res://core/board_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Rules = preload("res://core/resolution.gd")
const Gem = preload("res://core/gem_rules.gd")
const Economy = preload("res://core/attack_rules.gd")
const ArcadeRng = preload("res://core/arcade_rng.gd")
const Motion = preload("res://core/gem_motion.gd")
const GRAVITY_TICKS: int = 32
var motion: Array = []
var input_masks: Array[int] = [0,0]
var turn_number: Array[int] = [1,1]
var boards: Array = []
var pairs: Array = []
var lost: Array[bool] = [false, false]
var frame: int = 0
var rng := RandomNumberGenerator.new()
var scores: Array[int] = [0, 0]
var pending: Array[int] = [0, 0]
var pair_index: Array[int] = [0, 0]
var pair_age: Array[int] = [0,0]
var stream: Array = []
var last_results: Array = [{}, {}]
var residual_index: Array[int] = [0, 0]
var locked_residual: Array[int] = [-1, -1]
var character_ids: Array[int] = [2, 3]
var global_seed: int = 0x5785
var winner: int = -2
var last_sent_attack: Array[int] = [0,0]
var sent_event_id: Array[int] = [0,0]
var sent_turn: Array[int] = [-1,-1]
var first_attack: bool = false
var accelerated: Array[bool] = [false, false]
# PadrÃƒÆ’Ã‚Âµes medidos de Ryu (colunas) e Ken (linhas), nesta revisÃƒÆ’Ã‚Â£o do arcade.

func _init() -> void:
	restart()

func restart() -> void:
	rng.seed = 96
	boards = [Board.new(), Board.new()]
	motion = [Motion.new(), Motion.new()]
	input_masks = [0,0]
	turn_number = [1,1]
	lost = [false, false]
	pairs = [null, null]
	frame = 0
	scores = [0, 0]
	pending = [0, 0]
	pair_index = [0, 0]
	stream = []
	last_results = [{}, {}]
	residual_index = [0, 0]
	locked_residual = [-1, -1]
	global_seed = 0x5785
	winner = -2
	last_sent_attack = [0,0]
	sent_event_id = [0,0]
	sent_turn = [-1,-1]
	first_attack = false
	accelerated = [false, false]
	spawn(0)
	spawn(1)

func spawn(player: int) -> void:
	pair_age[player] = 0
	var previous_motion: RefCounted = motion[player]
	motion[player] = Motion.new()
	motion[player].fall_interval = previous_motion.fall_interval
	motion[player].fall_increment = previous_motion.fall_increment
	motion[player].fall_offset = previous_motion.fall_offset
	motion[player].previous_input = previous_motion.previous_input
	motion[player].horizontal_timer = previous_motion.horizontal_timer
	while stream.size() <= pair_index[player]:
		var idx := stream.size()
		var colors := [rng.randi_range(1, 4), rng.randi_range(1, 4)]
		if (idx + 1) % 25 == 0:
			colors[1] = 5
		elif idx % 5 == 1:
			colors[1] |= 8
		stream.append(colors)
	var colors: Array = stream[pair_index[player]]
	pairs[player] = Pair.new(Vector2i(3, 1), colors[0], colors[1])
	lost[player] = not boards[player].can_place(pairs[player])

func move(player: int, delta: Vector2i) -> bool:
	if player not in [0, 1] or lost[player] or winner != -2 or motion[player].phase != 0 or motion[player].contact == 1:
		return false
	var candidate = pairs[player].copy()
	candidate.pivot += delta
	if not boards[player].can_place(candidate):
		return false
	pairs[player] = candidate
	return true

func rotate(player: int, direction: int) -> bool:
	if player not in [0,1] or lost[player] or winner != -2: return false
	return motion[player].rotate(self,player,direction)

func rotate_geometry(player: int, direction: int) -> bool:
	if player not in [0, 1] or lost[player] or winner != -2 or direction not in [-1, 1]:
		return false
	var candidate = pairs[player].copy()
	candidate.rotation = posmod(candidate.rotation + direction, 4)
	if pairs[player].rotation in [0,2]:
		var point: Vector2i = pairs[player].pivot
		var blocked_left: bool = point.x == 0 or boards[player].cells[point.y*6+point.x-1]!=0
		var blocked_right: bool = point.x == 5 or boards[player].cells[point.y*6+point.x+1]!=0
		if blocked_left and blocked_right:
			var swap: int = pairs[player].colors[0]
			pairs[player].colors[0] = pairs[player].colors[1]
			pairs[player].colors[1] = swap
			return true
	if not boards[player].can_place(candidate):
		if candidate.rotation in [1,3]: candidate.pivot.x += -1 if candidate.rotation == 1 else 1
		elif candidate.rotation == 2: candidate.pivot.y -= 1
		else: return false
		if not boards[player].can_place(candidate): return false
	pairs[player] = candidate
	return true

func soft_drop(player: int, manual: bool = true) -> void:
	if player not in [0,1] or lost[player] or winner != -2 or motion[player].phase != 0: return
	if manual:
		accelerated[player] = true
		motion[player].manual_bonus = true
	if motion[player].contact > 0: return
	if not move(player,Vector2i.DOWN): motion[player].enter_contact()
	motion[player].offset = 0

func resolve_turn(player: int) -> void:
	var result: Dictionary = Rules.resolve(boards[player], true)
	last_results[player] = result
	scores[player] += int(result.score) + (10 if accelerated[player] else 0)
	accelerated[player] = false
	var outgoing := cancel_attack(player, int(result.attack))
	pending[1 - player] += outgoing
	record_sent_attack(player,outgoing,true)
	if pending[player] > 0:
		var amount: int = pending[player]
		pending[player] = 0
		if receive_attack(player, amount, 1 - player) > 0 and not first_attack:
			scores[1 - player] += 1000
			first_attack = true
	var center: int = boards[player].cells[2 * 6 + 3]
	lost[player] = lost[player] or center != 0
	if not lost[player]:
		pair_index[player] += 1
		spawn(player)
	check_winner()

func deliver_opponent_pending(player: int) -> void:
	if pending[1 - player] > 0:
		var amount: int = pending[1 - player]
		pending[1 - player] = 0
		if receive_attack(1 - player, amount, player) > 0 and not first_attack:
			scores[player] += 1000
			first_attack = true

func cancel_attack(player: int, attack: int) -> int:
	if attack > pending[player]:
		var outgoing := attack - pending[player]
		pending[player] = 0
		return outgoing
	pending[player] = maxi(0,pending[player]-Economy.counter_strength(attack))
	return 0

func receive_attack(player: int, amount: int, source: int) -> int:
	var placed := 0
	var remainder_columns: Array = Economy.columns(residual_index[player])
	var attack_row := 0
	while amount > 0:
		var count := mini(amount, 6)
		for i in range(count):
			var column: int = i if count == 6 else remainder_columns[i]
			var row := 13
			for y in range(14):
				if boards[player].cells[y * 6 + column] != 0:
					row = y - 1
					break
			if row < 0:
				if attack_row == 0:
					var top_color: int = Economy.counter_color(character_ids[source], attack_row, column)
					boards[player].cells[column] = Gem.counter(top_color, 5)
				lost[player] = true
				continue
			var color: int = Economy.counter_color(character_ids[source], attack_row, column)
			boards[player].cells[row * 6 + column] = Gem.counter(color, 5)
			placed += 1
		attack_row += 1
		amount -= count
	return placed

func check_winner() -> void:
	if lost[0] and lost[1]: winner = -1
	elif lost[0]: winner = 1
	elif lost[1]: winner = 0

func tick() -> void:
	frame += 1
	for player in range(2):
		if not lost[player] and winner == -2:
			# O consumo global anterior ÃƒÆ’Ã‚Â© preservado; sincronizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de todos os consumidores CPS-2 continua sendo uma limitaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o explÃƒÆ’Ã‚Â­cita.
			global_seed = ArcadeRng.advance(global_seed)
			residual_index[player] = locked_residual[player] if locked_residual[player] >= 0 else (global_seed & 7)
			motion[player].step(self,player,input_masks[player])

## Read-only HUD telemetry: net total accepted by the opposing queue during the player's current resolution (zero-valued waves keep the total).
func record_sent_attack(player: int, accepted: int, new_resolution: bool = false) -> void:
	if new_resolution or sent_turn[player] != turn_number[player]:
		last_sent_attack[player] = 0
	sent_turn[player] = turn_number[player]
	last_sent_attack[player] += accepted
	sent_event_id[player] += 1
