extends SceneTree
const Match = preload("res://core/match_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Gem = preload("res://core/gem_rules.gd")
var total: int = 0
var matching: int = 0
var cases_ok: int = 0
var failures: Array = []
var field_failures: Dictionary = {}
var fixture_path: String = ""
var out: String = ""

func word(ram: PackedByteArray, address: int) -> int:
	return int(ram[address])*256+int(ram[address+1])

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fixtures="): fixture_path = argument.trim_prefix("--fixtures=")
		if argument.begins_with("--out="): out = argument.trim_prefix("--out=")
	assert(not fixture_path.is_empty() and not out.is_empty())
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var records: Array = []
	for item in data.cases:
		var first: Dictionary = item.expected_samples[0]
		var ram_path: String = ProjectSettings.globalize_path("res://../laboratorio/")+str(item.source_session)+"/captures/"+str(item.id)+"_initial.bin"
		var ram: PackedByteArray = FileAccess.get_file_as_bytes(ram_path)
		assert(ram.size()==65536)
		var hash: HashingContext = HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(ram)
		assert(hash.finish().hex_encode()==item.initial_ram_sha256)
		var model: RefCounted = Match.new()
		var cells: PackedInt32Array = PackedInt32Array()
		for code in str(first.grid).split(":"): cells.append(str(code).hex_to_int())
		assert(model.boards[0].load_cells(cells))
		model.pairs[0] = Pair.new(Vector2i(int(first.x),int(first.y)-1),int(first.pivot),int(first.satellite))
		model.pairs[0].rotation = int(first.rotation)
		model.stream = [[int(first.pivot),int(first.satellite)],[word(ram,0x8456),word(ram,0x8458)]]
		model.scores[0] = int(first.score)
		model.global_seed = int(first.global_seed)
		model.turn_number[0] = int(first.turn)
		var clock: RefCounted = model.motion[0]
		clock.offset = int(first.offset)
		clock.fall_countdown = int(first.fall_countdown)
		clock.fall_interval = int(first.fall_interval)
		clock.fall_increment = int(first.fall_increment)
		clock.fall_offset = int(first.fall_offset)
		clock.fall_start = ram[0x857e] != 0
		clock.contacts = int(first.contact_count)
		clock.upkicks = word(ram,0x8614)
		clock.rotation_disabled = ram[0x8616] != 0
		clock.down_counter = int(first.down_counter)
		clock.down_timer = int(ram[0x84a9])
		clock.horizontal_timer = word(ram,0x8488)
		var case_failed: bool = false
		var sample_errors: int = 0
		for row in item.expected_samples:
			if int(row.frame)>0:
				# Entradas são dados do ensaio; nenhuma posição ou resposta futura alimenta a simulação.
				model.input_masks[0] = int(row.input)
				model.tick()
			clock = model.motion[0]
			var observed: Dictionary = {"x":model.pairs[0].pivot.x,"y":model.pairs[0].pivot.y+1,"offset":clock.offset,"rotation":model.pairs[0].rotation,"contact":clock.contact,"phase":clock.phase,"turn":model.turn_number[0],"pivot":model.pairs[0].colors[0],"satellite":model.pairs[0].colors[1],"pair_age":model.pair_age[0],"contact_count":clock.contacts,"score":model.scores[0]}
			if row.has("upkick_count"): observed.upkick_count = clock.upkicks
			if row.has("rotation_disabled"): observed.rotation_disabled = int(clock.rotation_disabled)
			var different: Dictionary = {}
			for key in observed:
				if int(observed[key]) != int(row[key]):
					different[key] = [observed[key],row[key]]
					field_failures[key] = int(field_failures.get(key,0))+1
			var expected_cells: PackedInt32Array = PackedInt32Array()
			for code in str(row.grid).split(":"): expected_cells.append(Gem.canonical(str(code).hex_to_int()))
			if model.boards[0].cells != expected_cells:
				different.grid = true
				field_failures.grid = int(field_failures.get("grid",0))+1
			total += 1
			if different.is_empty(): matching += 1
			else:
				case_failed = true
				sample_errors += 1
				if failures.size()<60: failures.append({"case":item.id,"frame":row.frame,"different":different})
		if not case_failed: cases_ok += 1
		records.append({"case":item.id,"passed":not case_failed,"sample_failures":sample_errors})
	var summary: Dictionary = {"cases":112,"cases_passed":cases_ok,"samples":total,"samples_matched":matching,"fields_compared":"x,y,offset,orientation,contact,phase,turn,colors,age,contact_count,score,canonical board; upkick fields where captured","strict_native_state_complete":false,"not_compared":"raw graphical flags, auxiliary RAM, global RNG consumers, native piece RNG and animation RAM","field_failures":field_failures,"first_failures":failures,"results":records}
	var f: FileAccess = FileAccess.open(out,FileAccess.WRITE)
	f.store_string(JSON.stringify(summary,"\t"))
	f.close()
	print("GEM_TIMELINE cases=",cases_ok,"/112 samples=",matching,"/",total," failures=",field_failures)
	quit(0 if matching==total else 1)
