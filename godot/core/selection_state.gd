extends RefCounted
const Catalog = preload("res://core/character_catalog.gd")
const Session = preload("res://core/match_session.gd")
var cursors: Array[int] = [0, 4, 0, 4]
var confirmed: Array[bool] = [false, false, false, false]
var player_count: int = 2

func _init(count: int = 2) -> void:
	assert(count == 2 or count == 4)
	player_count = count
	for player in range(count):
		var choices: Array[int] = available(player)
		if not choices.is_empty(): cursors[player] = choices[0]

func available(player: int) -> Array[int]:
	var choices: Array[int] = []
	if player < 0 or player >= player_count: return choices
	for index in range(Catalog.ROSTER.size()):
		if Catalog.ROSTER[index].team == Session.team_for(player): choices.append(index)
	return choices

func can_select(player: int, index: int) -> bool:
	return Session.phase == "select" and index in available(player)

func choose(player: int, index: int) -> bool:
	if not can_select(player, index) or confirmed[player]: return false
	cursors[player] = index
	return true

func move(player: int, direction: Vector2i) -> void:
	if player < 0 or player >= player_count or confirmed[player]: return
	var choices: Array[int] = available(player)
	if choices.is_empty(): return
	# Vertical nunca troca de equipe. Confirmação também valida o cursor.
	var index: int = choices.find(cursors[player])
	if index < 0: index = 0
	choose(player, choices[posmod(index + direction.x, choices.size())])

func confirm(player: int) -> bool:
	if player < 0 or player >= player_count or not can_select(player, cursors[player]): return false
	confirmed[player] = true
	return true

func cancel(player: int) -> void:
	if player >= 0 and player < player_count: confirmed[player] = false

func ready_to_start() -> bool:
	if player_count != Session.player_groups.size(): return false
	for player in range(player_count):
		if not confirmed[player] or not can_select(player, cursors[player]): return false
	return Session.valid_characters(ids())

func ids() -> Array[String]:
	var result: Array[String] = []
	for player in range(player_count):
		if cursors[player] < 0 or cursors[player] >= Catalog.ROSTER.size(): return []
		result.append(Catalog.ROSTER[cursors[player]].id)
	return result

func save_selection() -> bool:
	return ready_to_start() and Session.lock_characters(ids())

static func apply_to_match(model: RefCounted) -> bool:
	if Session.phase not in ["playing","between_rounds","finished"]: return false
	if Session.characters.size() != 2 or not Session.valid_characters(Session.characters): return false
	for player in range(2): model.character_ids[player] = Catalog.pattern_index(Session.characters[player])
	return true
