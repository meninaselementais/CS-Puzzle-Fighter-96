extends RefCounted
## Sorteio, seleção e rounds pertencem à partida; o motor das gemas não muda.
const Catalog = preload("res://core/character_catalog.gd")
static var rng: RandomNumberGenerator = RandomNumberGenerator.new()
static var match_id: int = 0
static var phase: String = "idle"
static var authority: String = "local"
static var team_zero_ct: bool = true
static var player_groups: Array[int] = [0, 1]
static var characters: Array[String] = []
static var round_wins: Array[int] = [0, 0]
static var round_number: int = 1
static var round_recorded: bool = false
static var winner: int = -1
static var last_round_result: int = -2

static func begin_local_match() -> void:
	# Um único bit, sem consumir o RNG determinístico das gemas.
	_set_assignment(rng.randi_range(0, 1) == 0, [0, 1], "local")

static func accept_server_assignment(first_team_ct: bool, groups: Array[int]) -> bool:
	# Entrada para futuro resultado autoritativo; nunca sorteia no cliente.
	# Slots 2x2: [0,0,1,1]. Não inicia quatro tabuleiros nesta etapa.
	if groups != [0, 1] and groups != [0, 0, 1, 1]: return false
	_set_assignment(first_team_ct, groups, "server")
	return true

static func _set_assignment(first_team_ct: bool, groups: Array[int], source: String) -> void:
	match_id += 1
	team_zero_ct = first_team_ct
	player_groups.assign(groups)
	authority = source
	phase = "coin"
	characters.clear()
	round_wins.assign([0, 0])
	round_number = 1
	round_recorded = false
	winner = -1
	last_round_result = -2

static func team_for(player: int) -> String:
	if phase == "idle" or player < 0 or player >= player_groups.size(): return ""
	var ct: bool = team_zero_ct == (player_groups[player] == 0)
	return "CT" if ct else "TR"

static func reveal() -> void:
	if phase == "coin": phase = "select"

static func valid_characters(ids: Array[String]) -> bool:
	if phase == "idle" or ids.size() != player_groups.size(): return false
	for player in range(ids.size()):
		var character: Dictionary = Catalog.find(ids[player])
		if character.is_empty() or character.team != team_for(player): return false
	return true

static func lock_characters(ids: Array[String]) -> bool:
	if phase != "select" or not valid_characters(ids): return false
	characters.assign(ids)
	phase = "playing"
	return true

static func record_round(result: int) -> bool:
	if phase != "playing" or round_recorded or result not in [-1, 0, 1]: return false
	round_recorded = true
	last_round_result = result
	if result >= 0: round_wins[result] += 1
	if result >= 0 and round_wins[result] == 2:
		winner = result
		phase = "finished"
	else:
		phase = "between_rounds"
	return true

static func advance_round() -> bool:
	if phase != "between_rounds": return false
	# Empates repetem o round, sem consumir a melhor de três.
	round_number = mini(3, round_wins[0] + round_wins[1] + 1)
	round_recorded = false
	last_round_result = -2
	phase = "playing"
	return true

static func close_match() -> void:
	phase = "idle"
	characters.clear()
