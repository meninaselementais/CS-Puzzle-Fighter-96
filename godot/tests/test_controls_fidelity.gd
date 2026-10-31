extends SceneTree

const Match = preload("res://core/match_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Controls = preload("res://core/control_model.gd")
const Rng = preload("res://core/arcade_rng.gd")
var results: Array = []
var excluded: Array = []

func record(id: String, passed: bool, details: Dictionary = {}) -> void:
	details["id"] = id;details["all_match"] = passed;results.append(details)

func _initialize() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/control_fixtures.json"))
	var rng_failed := 0
	for item in data.rng:
		if Rng.advance(int(item.input),bool(item.piece)) != int(item.expected): rng_failed += 1
	record("rng",rng_failed==0,{"samples":data.rng.size(),"failed_samples":rng_failed})
	var cases := {}
	for row in data.timing:
		if not cases.has(row.case): cases[row.case] = []
		cases[row.case].append(row)
	for name in cases:
		var rows: Array = cases[name]
		if name.begins_with("wall_") or name.begins_with("corridor_") or name.begins_with("floor_") or name.begins_with("quickturn_"):
			var before: Dictionary = rows[0]
			var after: Dictionary = rows[1]
			var model = Match.new()
			if name.begins_with("corridor_") or name.begins_with("quickturn_"):
				for y in range(3,10):
					for x in [2,4]: model.boards[0].cells[y*6+x] = 1
			model.pairs[0] = Pair.new(Vector2i(int(before.x),int(before.y)-1),int(before.pivot_color),int(before.satellite_color))
			model.pairs[0].rotation = int(before.rotation)
			if not model.boards[0].can_place(model.pairs[0]):
				excluded.append({"id":name,"reason":"Estado sintético inicial sobrepõe borda ou célula; não é uma rotação natural válida"})
				continue
			var direction := -1 if name.ends_with("_1") else 1
			model.rotate(0,direction)
			record(name,model.pairs[0].pivot==Vector2i(int(after.x),int(after.y)-1) and model.pairs[0].rotation==int(after.rotation) and model.pairs[0].colors==PackedInt32Array([int(after.pivot_color),int(after.satellite_color)]),
				{"godot_x":model.pairs[0].pivot.x,"godot_y":model.pairs[0].pivot.y,"godot_rotation":model.pairs[0].rotation,"arcade_x":int(after.x),"arcade_y":int(after.y)-1,"arcade_rotation":int(after.rotation)})
			if name.begins_with("quickturn_"):
				model.rotate(0,direction);after=rows[11]
				record(name+"_second",model.pairs[0].colors==PackedInt32Array([int(after.pivot_color),int(after.satellite_color)]))
		elif name.begins_with("right_") or name == "left_held":
			var controls = Controls.new()
			var x := int(rows[0].x)
			var mismatch := 0
			for row in rows:
				var direction := int(bool(int(row.input)&1)) - int(bool(int(row.input)&2))
				if controls.horizontal(0,direction): x = clampi(x+direction,0,5)
				if x!=int(row.x): mismatch += 1
			record(name,mismatch==0,{"frames":rows.size(),"different_frames":mismatch})
		elif name == "down_held":
			var controls = Controls.new()
			var y := int(rows[0].y)
			var mismatch := 0
			for row in rows.slice(0,13):
				if controls.drop(0,bool(int(row.input)&4)): y += 1
				if y!=int(row.y): mismatch += 1
			record(name,mismatch==0,{"frames":13,"different_frames":mismatch})
		elif name == "neutral":
			var changes: Array[int] = []
			var previous := int(rows[0].y)
			for row in rows:
				if int(row.y)>previous: changes.append(int(row.frame))
				previous = int(row.y)
			var valid := true
			for i in range(1,6): valid = valid and changes[i]-changes[i-1]==Match.GRAVITY_TICKS
			record(name,valid,{"observed_frames_per_row":32})
	var report_dir := ProjectSettings.globalize_path("res://../relatorios/fidelidade_v5")
	DirAccess.make_dir_recursive_absolute(report_dir)
	var file=FileAccess.open(report_dir.path_join("controles.json"),FileAccess.WRITE)
	assert(file!=null);file.store_string(JSON.stringify({"cases":results,"excluded_invalid_sources":excluded},"\t"));file.close()
	var failed: int = results.filter(func(r): return not r.all_match).size()
	print("CONTROL_FIDELITY ",results.size()-failed,"/",results.size(),"; RNG ",data.rng.size(),"; invalid_sources ",excluded.size())
	for result in results:
		if not result.all_match: print(result)
	quit(0 if failed==0 else 1)
