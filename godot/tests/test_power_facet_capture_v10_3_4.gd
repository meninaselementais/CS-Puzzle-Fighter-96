extends SceneTree
## Controle diferencial: cristal com e sem facetas no mesmo estado da cena.
var failures: Array[String] = []
var checks: int = 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		reject("Use -- <capture folder>")
		return
	var folder: String = args[0]
	var input_path: String = folder.path_join("captures.json")
	if not FileAccess.file_exists(input_path):
		reject("Capture manifest missing: " + input_path)
		return
	var records: Variant = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	if not valid_records(records): return
	var results: Array[Dictionary] = []
	for record in records:
		var stem: String = "%s_f%03d.png" % [record.case, record.frame]
		for name in [stem, "%s_base_f%03d.png" % [record.case, record.frame]]:
			if not FileAccess.file_exists(folder.path_join(name)):
				reject("Capture image missing: " + folder.path_join(name))
				return
		var image: Image = Image.load_from_file(folder.path_join(stem))
		var base: Image = Image.load_from_file(folder.path_join("%s_base_f%03d.png" % [record.case, record.frame]))
		if image == null or base == null:
			reject("Invalid capture image: " + stem)
			return
		if image.get_size() != Vector2i(1000,700) or base.get_size() != image.get_size():
			reject("Expected 1000x700 image pair: " + stem)
			return
		expect(true, "images: " + stem)
		var changed: Dictionary = {}
		var outside: int = 0
		var perimeter: int = 0
		for y in range(108, 492):
			for x in range(64, 256):
				if image.get_pixel(x,y) == base.get_pixel(x,y): continue
				var gx: int = floori(float(x - 64) / 32.0)
				var gy: int = floori(float(y - 108) / 32.0) + 2
				var idx: int = gy * 6 + gx
				changed[idx] = int(changed.get(idx,0)) + 1
				var age: int = record.ages[idx]
				if age < 8 or age >= 48: outside += 1
				for r in record.regions:
					var area: Rect2i = Rect2i(64+r[0]*32+1,108+(r[1]-2)*32+1,r[2]*32-2,r[3]*32-2)
					if area.has_point(Vector2i(x,y)) and not area.grow(-4).has_point(Vector2i(x,y)): perimeter += 1
		expect(outside == 0, "effect outside active cells: " + stem)
		expect(perimeter == 0, "changed crystal perimeter: " + stem)
		for idx in range(84):
			var age: int = record.ages[idx]
			if age >= 8 and age < 48:
				expect(changed.has(idx), "missing facet in cell %d: %s" % [idx,stem])
		results.append({"case":record.case,"frame":record.frame,"changed_cells":changed,"outside":outside,"perimeter":perimeter})
	var file: FileAccess = FileAccess.open(OS.get_environment("PF_REPORT").path_join("capture_structure.json"),FileAccess.WRITE)
	if file == null:
		reject("Cannot write capture_structure.json; check PF_REPORT")
		return
	file.store_string(JSON.stringify({"checks":checks,"captures":records.size(),"failures":failures,"results":results},"  "))
	print("POWER_FACET_CAPTURE checks=",checks," captures=",records.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func reject(message: String) -> bool:
	push_error("POWER_FACET_CAPTURE input: " + message)
	quit(1)
	return false

func valid_records(records: Variant) -> bool:
	if not records is Array: return reject("Invalid JSON capture array")
	if records.size() != 181: return reject("Expected 181 captures, got " + str(records.size()))
	var ranges: Dictionary = {"power_2x2": [1,65], "power_growth": [35,90], "power_union_5x2": [35,94]}
	var seen: Dictionary = {}
	for record in records:
		if not record is Dictionary: return reject("Invalid capture object")
		if not record.get("case") is String or not ranges.has(record.case): return reject("Unknown/missing capture case")
		if not (record.get("frame") is float or record.get("frame") is int): return reject("Missing/invalid capture frame")
		var frame: int = int(record.frame)
		if float(record.frame) != frame or frame < ranges[record.case][0] or frame > ranges[record.case][1]: return reject("Unexpected capture frame")
		var key: String = "%s:%d" % [record.case,frame]
		if seen.has(key): return reject("Duplicate capture: " + key)
		seen[key] = true
		if not record.get("ages") is Array or record.ages.size() != 84: return reject("Expected 84 cell ages: " + key)
		for age in record.ages:
			if not (age is float or age is int): return reject("Invalid cell age: " + key)
			if float(age) != int(age): return reject("Noninteger cell age: " + key)
		if not record.get("regions") is Array or record.regions.is_empty(): return reject("Missing regions: " + key)
		for region in record.regions:
			if not region is Array or region.size() != 4: return reject("Invalid region: " + key)
			for value in region:
				if not (value is float or value is int): return reject("Invalid region coordinate: " + key)
				if float(value) != int(value): return reject("Noninteger region coordinate: " + key)
			if region[0] < 0 or region[1] < 0 or region[2] <= 0 or region[3] <= 0 or region[0]+region[2] > 6 or region[1]+region[3] > 14: return reject("Region outside board: " + key)
	return true
