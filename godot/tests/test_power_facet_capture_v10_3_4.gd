extends SceneTree
## Controle diferencial: cristal com e sem facetas no mesmo estado da cena.
var failures: Array[String] = []
var checks: int = 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = args[0]
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("captures.json")))
	var results: Array[Dictionary] = []
	for record in records:
		var stem: String = "%s_f%03d.png" % [record.case, record.frame]
		var image: Image = Image.load_from_file(folder.path_join(stem))
		var base: Image = Image.load_from_file(folder.path_join("%s_base_f%03d.png" % [record.case, record.frame]))
		expect(not image.is_empty() and image.get_size() == base.get_size(), "images: " + stem)
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
	file.store_string(JSON.stringify({"checks":checks,"captures":records.size(),"failures":failures,"results":results},"  "))
	print("POWER_FACET_CAPTURE checks=",checks," captures=",records.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
