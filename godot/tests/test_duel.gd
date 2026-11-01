extends SceneTree

const Match = preload("res://core/match_model.gd")
const Gem = preload("res://core/gem_rules.gd")

func _initialize() -> void:
	var model = Match.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 28996
	var rounds := 1
	var waves := 0
	var sent := 0
	for turn in range(1500):
		if turn > 0 and turn % 500 == 0:
			model.restart();rng.seed = 28996 + turn / 500;rounds += 1
		if model.winner != -2:
			model.restart();rounds += 1
		var player := turn % 2
		var column := rng.randi_range(0,5)
		while model.pairs[player].pivot.x != column:
			var direction := signi(column-model.pairs[player].pivot.x)
			if not model.move(player,Vector2i(direction,0)): break
		for _r in range(rng.randi_range(0,3)): model.rotate(player,1)
		var initial: int = model.pair_index[player]
		for _drop in range(16):
			model.soft_drop(player)
			if model.pair_index[player] != initial or model.winner != -2: break
		for _frame in range(600):
			if model.pair_index[player] != initial or model.winner != -2: break
			model.tick()
		assert(model.pair_index[player] != initial or model.winner != -2)
		var result: Dictionary = model.last_results[player]
		if not result.is_empty():
			waves += result.waves.size();sent += int(result.attack)
		for board in model.boards:
			assert(board.cells.size()==84)
			for code in board.cells:
				assert(code==0 or Gem.is_diamond(code) or Gem.color(code) in [1,2,3,4])
			for rect in board.power_gems:
				assert(rect.size.x>=2 and rect.size.x<=6 and rect.size.y>=2 and rect.size.y<=8)
				for i in board.indices(rect): assert(Gem.kind(board.cells[i])==Gem.Kind.POWER)
	assert(waves>0 and sent>0 and rounds>1)
	print("DUEL_OK: 1500 turnos, ",rounds," partidas, ",waves," ondas, ",sent," ataques brutos")
	quit(0)
