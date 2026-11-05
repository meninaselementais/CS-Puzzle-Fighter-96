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
	if fixture_path.is_empty() or out.is_empty():
		reject("Use --fixtures=<JSON> and --out=<report>")
		return
	if not FileAccess.file_exists(fixture_path):
		reject("Fixture file missing: " + fixture_path)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	if not valid_fixtures(data): return
	var records: Array = []
	for item in data.cases:
		var first: Dictionary = item.expected_samples[0]
		var ram_path: String = ProjectSettings.globalize_path("res://../laboratorio/")+str(item.source_session)+"/captures/"+str(item.id)+"_initial.bin"
		var ram: PackedByteArray = FileAccess.get_file_as_bytes(ram_path)
		if ram.size() != 65536:
			reject("Initial RAM missing or invalid (expected 65536 bytes): " + ram_path)
			return
		var hash: HashingContext = HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(ram)
		if hash.finish().hex_encode() != item.initial_ram_sha256:
			reject("Initial RAM SHA256 mismatch: " + ram_path)
			return
		var model: RefCounted = Match.new()
		var cells: PackedInt32Array = PackedInt32Array()
		for code in str(first.grid).split(":"): cells.append(str(code).hex_to_int())
		if not model.boards[0].load_cells(cells):
			reject("Invalid initial board: " + str(item.id))
			return
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
	if f == null:
		reject("Cannot write report: " + out)
		return
	f.store_string(JSON.stringify(summary,"\t"))
	f.close()
	print("GEM_TIMELINE cases=",cases_ok,"/112 samples=",matching,"/",total," failures=",field_failures)
	quit(0 if cases_ok == 112 and total == 14072 and matching == total else 1)

func reject(message: String) -> bool:
	push_error("GEM_TIMELINE input: " + message)
	quit(1)
	return false

func valid_fixtures(data: Variant) -> bool:
	if not data is Dictionary: return reject("Invalid JSON object: " + fixture_path)
	if not data.get("cases") is Array: return reject("Missing cases array")
	if data.cases.size() != 112: return reject("Expected 112 cases, got " + str(data.cases.size()))
	var required: Dictionary = required_cases()
	var ids: Dictionary = {}
	var samples: int = 0
	for item in data.cases:
		if not item is Dictionary: return reject("Invalid case object")
		for key in ["id", "source_session", "initial_ram_sha256"]:
			if not item.get(key) is String or item[key].is_empty(): return reject("Missing/invalid case field: " + key)
		if ids.has(item.id): return reject("Duplicate case: " + item.id)
		if not required.has(item.id): return reject("Unknown case: " + item.id)
		ids[item.id] = true
		if not item.get("expected_samples") is Array or item.expected_samples.is_empty(): return reject("Missing samples: " + item.id)
		if item.expected_samples.size() != required[item.id]: return reject("Incomplete sample coverage: " + item.id)
		var frame: int = 0
		for row in item.expected_samples:
			if not row is Dictionary: return reject("Invalid sample: " + item.id)
			for key in ["frame", "x", "y", "offset", "rotation", "contact", "phase", "turn", "pivot", "satellite", "input", "pair_age", "contact_count", "score", "global_seed", "fall_countdown", "fall_interval", "fall_increment", "fall_offset", "down_counter"]:
				if not (row.get(key) is float or row.get(key) is int): return reject("Missing/invalid sample field: " + item.id + ": " + key)
				if float(row[key]) != int(row[key]): return reject("Noninteger sample field: " + key)
			for key in ["upkick_count", "rotation_disabled"]:
				if row.has(key):
					if not (row[key] is float or row[key] is int): return reject("Invalid optional field: " + key)
					if float(row[key]) != int(row[key]): return reject("Noninteger optional field: " + key)
			if int(row.frame) != frame: return reject("Missing/duplicate/out-of-order frame: " + item.id)
			frame += 1
			if not row.get("grid") is String: return reject("Missing grid: " + item.id)
			var codes: PackedStringArray = row.grid.split(":")
			if codes.size() != 84: return reject("Expected 84 board cells: " + item.id)
			for code in codes:
				if code.length() != 4 or not code.is_valid_hex_number(): return reject("Invalid board hex: " + item.id)
			samples += 1
	if samples != 14072: return reject("Expected 14072 samples, got " + str(samples))
	return true

func required_cases() -> Dictionary:
	# Fixed coverage contract of the audited V10 physics matrix.
	var required: Dictionary = {}
	for speed in [0,7,15]:
		for down in [0,1]: required["speed_%d_down_%d" % [speed,down]] = 121
	for orientation in range(4): required["floor_orientation_%d" % orientation] = 121
	for button in [1,2]:
		for contact in range(16): required["rotate_b%d_issued_c%02d" % [button,contact]] = 121
	for direction in ["left","right"]:
		for contact in [0,8,12,13,14,15]: required["move_%s_issued_c%02d" % [direction,contact]] = 121
	for command in ["right_cw","left_ccw","both_rotate","both_horizontal","down_cw"]:
		for contact in [0,12,13]: required["sim_%s_c%02d" % [command,contact]] = 121
	for wall in [0,5]:
		for command in ["cw","ccw","inward_cw","outward_cw"]: required["wall_%d_%s" % [wall,command]] = 121
	for kind in ["corridor","irregular"]:
		for button in [1,2]: required["%s_b%d" % [kind,button]] = 121
	for orientation in [1,3]:
		for part in ["pivot","satellite"]:
			for depth in [1,3,6]: required["split_r%d_%s_depth%d" % [orientation,part,depth]] = 121
	for name in ["split_forms_power","prior_contact_count_6","prior_contact_count_7","held_right","held_rotation","repeated_rotation","upkick_third_synthetic"]: required[name] = 121
	for command in ["cw","right","right_cw"]:
		for frame in [38,39,40]: required["first_contact_%s_issue_f%d" % [command,frame]] = 121
	required["leave_support_move"] = 281
	required["leave_support_rotate"] = 281
	required["upkick_cycles_natural_after_setup"] = 321
	return required
