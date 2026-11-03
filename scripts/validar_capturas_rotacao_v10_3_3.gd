extends SceneTree

func _initialize() -> void:
	var base: String = OS.get_environment("PF_CAPTURE_SOURCE")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("captures.json")))
	var reference: Image = Image.load_from_file(base.path_join("rotation_r0_b1_f003.png"))
	var ref_background: Image = Image.load_from_file(base.path_join("rotation_r0_b1_f003_background.png"))
	var body: Array[Vector2i] = []
	for y in range(-16,16):
		for x in range(-16,16):
			if reference.get_pixel(144+x,252+y) != ref_background.get_pixel(144+x,252+y): body.append(Vector2i(x,y))
	assert(body.size() == 736)
	var results: Array[Dictionary] = []
	var invalid: int = 0
	var inactive: int = 0
	for row in data.records:
		var stem: String = "%s_f%03d" % [row.case,row.frame]
		var image: Image = Image.load_from_file(base.path_join(stem+".png"))
		var background: Image = Image.load_from_file(base.path_join(stem+"_background.png"))
		var expected: Dictionary = {}
		if int(row.phase) == 0:
			for point in [row.pivot,row.satellite]:
				if point[0] < 0 or point[0] >= 6 or point[1] < 2 or point[1] >= 14: continue
				var center: Vector2i = Vector2i(roundi(80+point[0]*32),roundi(124+(point[1]-2)*32))
				for pixel in body: expected[center+pixel] = true
		else: inactive += 1
		var unexpected: int = 0
		var missing: int = 0
		var visible: int = 0
		for y in range(108,492):
			for x in range(64,256):
				var actual: Color = image.get_pixel(x,y)
				var changed: bool = actual != background.get_pixel(x,y) and actual.to_rgba32() != 0xffbbbbff
				if changed:
					visible += 1
					if not expected.has(Vector2i(x,y)): unexpected += 1
				elif expected.has(Vector2i(x,y)): missing += 1
		if unexpected > 0 or missing > 0: invalid += 1
		results.append({"case":row.case,"frame":row.frame,"phase":row.phase,"contact":row.contact,"timer":row.timer,"pixels":visible,"unexpected":unexpected,"missing":missing})
	var file: FileAccess = FileAccess.open(OS.get_environment("PF_REPORT").path_join("capture_masks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":results.size(),"inactive_captures":inactive,"invalid":invalid,"records":results},"  "))
	print("CAPTURE_MASKS captures=",results.size()," inactive=",inactive," invalid=",invalid)
	quit(0 if invalid == 0 else 1)
