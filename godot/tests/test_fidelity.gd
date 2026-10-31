extends SceneTree

const Board = preload("res://core/board_model.gd")
const Rules = preload("res://core/resolution.gd")
const Match = preload("res://core/match_model.gd")
var results: Array = []

func ordered_powers(rectangles: Array) -> Array:
	var result: Array = []
	for rect in rectangles: result.append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	result.sort_custom(func(a,b): return str(a) < str(b))
	return result

func _initialize() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mechanics_fixtures.json"))
	if not data is Dictionary:
		push_error("Fixtures ausentes");quit(2);return
	for fixture in data.fixtures:
		var board = Board.new()
		assert(board.load_cells(PackedInt32Array(fixture.input)))
		board.power_gems.clear()
		for rect in fixture.input_powers: board.power_gems.append(Rect2i(int(rect[0]),int(rect[1]),int(rect[2]),int(rect[3])))
		var outcome: Dictionary = Rules.resolve(board, bool(fixture.decrement_counters))
		var differences: Array = []
		for i in range(84):
			if board.cells[i] != int(fixture.expected[i]): differences.append({"x":i%6,"y":i/6,"godot":board.cells[i],"arcade":fixture.expected[i]})
		var expected_rects: Array = []
		for rect in fixture.expected_powers: expected_rects.append([int(rect[0]),int(rect[1]),int(rect[2]),int(rect[3])])
		expected_rects.sort_custom(func(a,b): return str(a) < str(b))
		var power_match: bool = ordered_powers(board.power_gems) == expected_rects
		var record := {"id":fixture.id,"board_match":differences.is_empty(),"power_match":power_match,
			"score_match":int(outcome.score)==int(fixture.expected_score),"attack_match":not fixture.compare_attack or int(outcome.attack)==int(fixture.expected_attack),
			"godot_score":outcome.score,"arcade_score":fixture.expected_score,"godot_attack":outcome.attack,"arcade_attack":fixture.expected_attack,
			"waves":outcome.waves,"differences":differences,"godot_powers":ordered_powers(board.power_gems),"arcade_powers":expected_rects}
		record["all_match"] = record.board_match and record.power_match and record.score_match and record.attack_match
		results.append(record)
		print(fixture.id," board=",record.board_match," power=",power_match," score=",record.godot_score,"/",record.arcade_score," attack=",record.godot_attack,"/",record.arcade_attack)
	for fixture in data.get("deliveries", []):
		var model = Match.new()
		assert(model.boards[int(fixture.target)].load_cells(PackedInt32Array(fixture.input)))
		model.residual_index[int(fixture.target)] = int(fixture.permutation)
		model.character_ids[int(fixture.source)] = int(fixture.character)
		model.receive_attack(int(fixture.target), int(fixture.amount), int(fixture.source))
		var differences: Array = []
		for i in range(84):
			if model.boards[int(fixture.target)].cells[i] != int(fixture.expected[i]): differences.append({"x":i%6,"y":i/6,"godot":model.boards[int(fixture.target)].cells[i],"arcade":fixture.expected[i]})
		results.append({"id":"delivery_"+fixture.id,"all_match":differences.is_empty(),"differences":differences})
	for fixture in data.get("counterattacks", []):
		var model = Match.new()
		model.pending[1] = int(fixture.incoming)
		var outgoing: int = model.cancel_attack(1, int(fixture.attack))
		results.append({"id":fixture.id,"all_match":outgoing==int(fixture.expected_outgoing) and model.pending[1]==int(fixture.expected_pending),
			"godot_pending":model.pending[1],"arcade_pending":fixture.expected_pending,"godot_outgoing":outgoing,"arcade_outgoing":fixture.expected_outgoing})
	var report_dir := ProjectSettings.globalize_path("res://../relatorios/fidelidade_v5")
	DirAccess.make_dir_recursive_absolute(report_dir)
	var file=FileAccess.open(report_dir.path_join("comparacao.json"),FileAccess.WRITE)
	assert(file!=null)
	file.store_string(JSON.stringify({"source":data.session,"cases":results},"\t"));file.close()
	var failed: int = results.filter(func(r): return not r.all_match).size()
	print("FIDELITY_RESULT ",results.size()-failed,"/",results.size()," matches")
	quit(0 if failed==0 else 1)
