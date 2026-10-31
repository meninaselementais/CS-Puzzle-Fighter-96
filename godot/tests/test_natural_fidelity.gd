extends SceneTree

const Match = preload("res://core/match_model.gd")
var results: Array = []

func _initialize() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/natural_fixtures.json"))
	for fixture in data.fixtures:
		var model = Match.new()
		var p := int(fixture.player)
		assert(model.boards[p].load_cells(PackedInt32Array(fixture.input)))
		model.boards[p].power_gems.clear()
		for r in fixture.input_powers: model.boards[p].power_gems.append(Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3])))
		model.pending[p] = int(fixture.incoming)
		model.pending[1-p] = int(fixture.outgoing)
		model.residual_index[p] = int(fixture.permutation)
		model.character_ids[1-p] = int(fixture.source_character)
		model.first_attack = bool(fixture.first_bonus)
		if bool(fixture.get("opponent_first_bonus", false)):
			model.deliver_opponent_pending(p)
		model.resolve_turn(p)
		var differences: Array = []
		for i in range(84):
			if model.boards[p].cells[i] != int(fixture.expected[i]): differences.append({"x":i%6,"y":i/6,"godot":model.boards[p].cells[i],"arcade":fixture.expected[i]})
		var score_match: bool = model.scores[p] == int(fixture.expected_score)
		results.append({"id":fixture.id,"all_match":differences.is_empty() and score_match,"board_match":differences.is_empty(),"score_match":score_match,
			"godot_score":model.scores[p],"arcade_score":fixture.expected_score,"incoming":fixture.incoming,"differences":differences})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../relatorios/fidelidade_v5"))
	var file=FileAccess.open(ProjectSettings.globalize_path("res://../relatorios/fidelidade_v5/partidas.json"),FileAccess.WRITE)
	assert(file!=null);file.store_string(JSON.stringify({"scope":data.scope,"cases":results},"\t"));file.close()
	var failed: int = results.filter(func(r): return not r.all_match).size()
	print("NATURAL_FIDELITY ",results.size()-failed,"/",results.size())
	for r in results:
		if not r.all_match: print(r.id," board=",r.board_match," score=",r.godot_score,"/",r.arcade_score," cells=",r.differences.size())
	quit(0 if failed==0 else 1)
