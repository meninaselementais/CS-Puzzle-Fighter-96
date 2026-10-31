extends SceneTree

const Board = preload("res://core/board_model.gd")
const Gem = preload("res://core/gem_rules.gd")
const Rules = preload("res://core/resolution.gd")
const Match = preload("res://core/match_model.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)

func put(board, x: int, y: int, code: int) -> void:
	board.cells[y * 6 + x] = code

func rectangle(board, x: int, y: int, width: int, height: int, color: int) -> void:
	for row in range(y, y + height):
		for col in range(x, x + width): put(board, col, row, color)

func _initialize() -> void:
	var board = Board.new()
	rectangle(board, 0, 12, 2, 2, 3)
	Rules.resolve(board, false)
	expect(board.power_gems == [Rect2i(0, 12, 2, 2)], "Power 2x2")
	put(board, 0, 11, 3); put(board, 1, 11, 3)
	Rules.resolve(board, false)
	expect(board.power_gems == [Rect2i(0, 11, 2, 3)], "Power cresce sem quebrar identidade")
	rectangle(board, 3, 11, 2, 3, 3)
	Rules.resolve(board, false)
	rectangle(board, 2, 11, 1, 3, 3)
	Rules.resolve(board, false)
	expect(board.power_gems == [Rect2i(0, 11, 5, 3)], "Uniao por ponte completa")
	board = Board.new()
	put(board, 0, 11, 3); put(board, 0, 12, 3); put(board, 0, 13, 3); put(board, 1, 13, 3)
	Rules.resolve(board, false)
	expect(board.power_gems.is_empty(), "L nao e Power Gem")
	board = Board.new()
	rectangle(board, 0, 12, 2, 2, 1)
	put(board, 2, 13, 9)
	var result: Dictionary = Rules.resolve(board, false)
	expect(board.cells.count(0) == 84, "Crash elimina Power inteira")
	expect(result.attack > 5 and result.waves.size() == 1, "Power aumenta ataque")
	board = Board.new()
	put(board, 2, 13, 4); put(board, 3, 13, 12)
	put(board, 1, 13, Gem.counter(2, 5)); put(board, 0, 13, Gem.counter(3, 5))
	result = Rules.resolve(board, false)
	expect(board.cells[13 * 6 + 1] == 0, "Counter adjacente explode independentemente da cor")
	expect(Gem.kind(board.cells[13 * 6]) == Gem.Kind.COUNTER, "Colateral nao se propaga por Counter Gems")
	board = Board.new()
	put(board, 0, 13, Gem.counter(2, 5))
	for expected in [4, 3, 2, 1]:
		Rules.resolve(board, true)
		expect(Gem.countdown(board.cells[13 * 6]) == expected, "Counter countdown %d" % expected)
	Rules.resolve(board, true)
	expect(board.cells[13 * 6] == 2, "Counter vira normal apos cinco turnos")
	board = Board.new()
	rectangle(board, 4, 10, 1, 4, 4)
	put(board, 3, 10, 12); put(board, 3, 11, 2); put(board, 3, 12, 2); put(board, 3, 13, 4)
	put(board, 4, 9, 1); put(board, 5, 13, 9)
	result = Rules.resolve(board, false)
	expect(result.waves.size() == 2, "Queda produz segunda reacao em cadeia")
	expect(board.cells[13 * 6 + 4] == 0 and board.cells[13 * 6 + 5] == 0, "Cadeia remove gemas de segunda cor")
	board = Board.new()
	rectangle(board, 0, 10, 2, 2, 3)
	put(board, 0, 12, 12); put(board, 0, 13, 4); put(board, 1, 12, 1); put(board, 1, 13, 1)
	Rules.resolve(board, false)
	expect(board.power_gems == [Rect2i(0, 10, 2, 2)], "Power fica rigida quando uma borda tem suporte")
	var model = Match.new()
	model.pending[0] = 10
	expect(model.cancel_attack(0, 8) == 0 and model.pending[0] == 6, "Arcade: ataque 8 contra fila 10 deixa 6")
	expect(model.cancel_attack(0, 10) == 4 and model.pending[0] == 0, "Arcade: ataque 10 contra fila 6 envia 4")
	model.pending[0] = 6
	expect(model.cancel_attack(0, 6) == 0 and model.pending[0] == 3, "Arcade: igualdade deixa meia fila")
	model.pending[0] = 0
	expect(model.receive_attack(1, 10, 0) == 10, "Recebimento de dez Counter Gems")
	var count := 0
	for code in model.boards[1].cells:
		if Gem.kind(code) == Gem.Kind.COUNTER and Gem.countdown(code) == 5: count += 1
	expect(count == 10, "Ataque inicia contagem em cinco")
	model.restart(); rectangle(model.boards[0], 3, 2, 1, 12, 1); model.resolve_turn(0)
	expect(model.lost[0] and model.winner == 1, "Coluna de entrada bloqueada causa derrota e vitoria adversaria")
	model.restart(); rectangle(model.boards[0], 0, 2, 1, 12, 1); model.resolve_turn(0)
	expect(not model.lost[0], "Coluna lateral cheia nao basta para perder")
	model.restart()
	for p in range(2):
		rectangle(model.boards[p], 4, 10, 1, 4, 4)
		put(model.boards[p], 3, 10, 12);put(model.boards[p], 3, 11, 2);put(model.boards[p], 3, 12, 2);put(model.boards[p], 3, 13, 4)
		model.accelerated[p] = true
	model.resolve_turn(0)
	expect(model.scores[0] == 650 and model.pending[1] == 6, "Duelo envia ataque com pontuacao medida")
	model.resolve_turn(1)
	expect(model.pending == [0,0] and model.scores[0] == 1650, "Duelo aplica contra-ataque, recebe e concede primeiro bonus")
	var counter_count := 0
	for code in model.boards[1].cells:
		if Gem.kind(code) == Gem.Kind.COUNTER: counter_count += 1
	expect(counter_count == 3, "Duelo deixa tres Counter Gems apos ataques iguais")
	model.restart();model.pairs[0].pivot = Vector2i(3,13);model.soft_drop(0,false)
	expect(model.scores[0] == 0, "Queda natural nao concede bonus de aceleracao")
	model.restart();model.pairs[0].pivot = Vector2i(3,13);model.soft_drop(0)
	expect(model.scores[0] == 10, "Queda acelerada concede dez pontos no caso observado")
	# Diamond Gem (código 5) validada no MAME (diamante.lua)
	board = Board.new()
	put(board, 2, 13, 5)
	result = Rules.resolve(board, false)
	expect(board.cells[13 * 6 + 2] == 0 and result.score == 10000 and result.attack == 0, "Diamond no chao concede 10000 pontos e 0 ataque")
	board = Board.new()
	for pos in [Vector2i(0,13),Vector2i(0,12),Vector2i(1,13),Vector2i(2,13),Vector2i(3,13),Vector2i(4,13),Vector2i(4,12),Vector2i(5,13)]:
		put(board, pos.x, pos.y, 1)
	put(board, 4, 11, 5)
	result = Rules.resolve(board, false)
	expect(board.cells.count(0) == 84 and result.score == 970 and result.attack == 4, "Diamond sobre azul normal elimina cor e divide ataque por 2")
	board = Board.new()
	put(board, 0, 13, Gem.counter(1, 5)); put(board, 1, 13, Gem.counter(2, 4)); put(board, 2, 13, 1); put(board, 4, 13, 1); put(board, 2, 12, 5)
	result = Rules.resolve(board, false)
	expect(board.cells[13 * 6 + 0] == 0 and board.cells[13 * 6 + 1] == Gem.counter(2, 4) and result.score == 420 and result.attack == 2, "Diamond elimina Counter Gems da cor alvo como gemas normais")
	board = Board.new()
	rectangle(board, 0, 12, 2, 2, 1)
	Rules.form_powers(board)
	put(board, 2, 13, 1); put(board, 2, 12, 5)
	result = Rules.resolve(board, false)
	expect(board.cells.count(0) == 84 and result.score == 1040 and result.attack == 5, "Diamond elimina Power Gem da cor alvo com pontuacao de Power")
	board = Board.new()
	put(board, 2, 13, Gem.counter(3, 5)); put(board, 0, 13, 3); put(board, 4, 13, 9); put(board, 2, 12, 5)
	result = Rules.resolve(board, false)
	expect(board.cells[13 * 6 + 2] == 0 and board.cells[13 * 6 + 0] == 0 and board.cells[13 * 6 + 4] == 9 and result.score == 310 and result.attack == 1, "Diamond pousando diretamente sobre Counter Gem usa sua cor")
	model.restart()
	model.pair_index[0] = 24
	model.spawn(0)
	expect(model.stream[24][1] == 5 and Gem.kind(model.stream[24][1]) == Gem.Kind.DIAMOND, "25a dupla gera Diamond Gem no satelite")
	print("RULE_TESTS ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
