extends SceneTree

const Board = preload("res://core/board_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Match = preload("res://core/match_model.gd")
const Replay = preload("res://adapters/mame_replay.gd")

func _initialize() -> void:
	var board = Board.new()
	var pair = Pair.new(Vector2i(0, 4))
	assert(board.can_place(pair))
	pair.rotation = 3
	assert(not board.can_place(pair))
	assert(not board.commit(pair))
	assert(board.cells.count(0) == 84)
	pair.rotation = 0
	assert(board.commit(pair))
	assert(not board.can_place(pair))
	assert(board.cells[4 * 6] == 2 and board.cells[3 * 6] == 4)
	var old = board.cells.duplicate()
	assert(not board.load_cells(PackedInt32Array([1, 2])))
	assert(board.cells == old)
	var model = Match.new()
	model.pairs[0].pivot = Vector2i(5, 5)
	assert(not model.move(0, Vector2i.RIGHT))
	assert(model.rotate(0, 1))
	assert(model.pairs[0].rotation == 1 and model.pairs[0].pivot.x == 4)
	model.pairs[0].rotation = 0
	model.pairs[0].pivot = Vector2i(2, 13)
	model.soft_drop(0)
	finish_turn(model,0)
	assert(model.boards[0].cells[13 * 6 + 2] != 0)
	assert(model.pairs[0].pivot == Vector2i(3, 1))
	assert(model.boards[1].cells.count(0) == 84)
	var replay = Replay.new()
	assert(not replay.load_data({"schema_version": 5}))
	assert(replay.load_file("res://data/replay_mame.json"), replay.error_message)
	var observed := {}
	for item in replay.frames:
		if int(item.frame) == 16:
			observed[item.case] = item.players
	var control: Dictionary = observed.controle_a[0]
	model.restart()
	assert(model.boards[0].load_cells(PackedInt32Array(control.cells)))
	model.pairs[0] = Pair.new(Vector2i(int(control.x), int(control.y)))
	assert(model.move(0, Vector2i.RIGHT))
	assert(model.pairs[0].pivot.x == int(observed.direita_a[0].x))
	assert(model.move(0, Vector2i.LEFT))
	assert(model.move(0, Vector2i.LEFT))
	assert(model.pairs[0].pivot.x == int(observed.esquerda_a[0].x))
	model.pairs[0].pivot.x = int(control.x)
	assert(model.rotate(0, 1))
	assert(model.pairs[0].rotation == int(observed.rotacao_2[0].rotation))
	for i in range(3):
		assert(model.rotate(0, 1))
	assert(model.pairs[0].rotation == 0)
	print("GODOT_TESTS_OK: limites, colisao, assentamento atomico, dois tabuleiros, importacao e geometria MAME")
	quit(0)

func finish_turn(model: RefCounted, player: int) -> void:
	var index: int = model.pair_index[player]
	for _frame in range(600):
		if model.pair_index[player] != index or model.winner != -2: return
		model.tick()
	assert(false,"Temporal turn did not finish")
