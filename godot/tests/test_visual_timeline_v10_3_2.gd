extends SceneTree
const MatchModel = preload("res://core/match_model.gd")
const PairModel = preload("res://core/pair_model.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
var checks: int = 0
var failures: Array[String] = []
var trace: Array[Dictionary] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed, value.state]
	if value is RefCounted:
		var result: Dictionary = {}
		var script: Script = value.get_script()
		for item in script.get_script_property_list():
			result[item.name] = state(value.get(item.name))
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(state(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = state(value[key])
		return result
	return value

func step(model: RefCounted, arena: RefCounted) -> void:
	model.tick()
	var before: String = var_to_str(state(model))
	arena.step_from_model(model)
	expect(var_to_str(state(model)) == before,"arena is read-only at frame %d" % model.frame)
	for player in range(2):
		expect(arena.get_visual_cells(player,model.boards[player].cells) == model.boards[player].cells,"live cells equal current simulation")
		for idx in range(84):
			expect(arena.get_cell_visual_offset(player,idx) == 0.0 and arena.get_cell_squash_scale(player,idx) == Vector2.ONE,"no artificial fall or squash")

func setup_result(model: RefCounted) -> void:
	model.motion[0].result = {"waves":[],"score":0,"attack":0,"converted":0,"gravity":0}
	model.motion[1].fall_countdown = 10000

func contour_count(image: Image) -> int:
	var count: int = 0
	for y in range(0,32,2):
		for x in range(0,32,2):
			if image.get_pixel(x,y).a > 0.5: count += 1
	return count

func landing(same_color: bool) -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	model.pairs[0] = PairModel.new(Vector2i(2,12 if same_color else 13),1,3)
	model.motion[0].offset = -8
	model.motion[0].fall_start = false
	model.motion[0].fall_countdown = 0
	model.pair_age[0] = 32
	setup_result(model)
	if same_color: model.boards[0].cells[80] = 1
	for frame in range(1,81):
		step(model,arena)
		if frame == 15: expect(model.motion[0].contact == 16,"contact starts at native CPU F15")
		if frame >= 15 and frame <= 30: expect(model.motion[0].contact == 31-frame,"16..1 contact window unchanged")
		if frame == 31: expect(model.motion[0].phase == 1,"deposit at native CPU F31")
		var idx: int = 74 if same_color else 80
		var stage: int = arena.temporal_connection_stage(0,idx)
		if same_color and frame >= 31:
			var expected: int = 0 if frame < 35 else (1 if frame < 39 else 2)
			expect(stage == expected,"same-color tile stages match native CPU clock")
		elif not same_color: expect(stage == 0,"isolated body never compresses")
		trace.append({"case":"same_color" if same_color else "isolated","frame":frame,"phase":model.motion[0].phase,"contact":model.motion[0].contact,"connection_stage":stage,"offset":model.motion[0].offset})
	expect(contour_count(arena.temporal_halo_texture().get_image()) == 60,"measured halo is separate from body")
	for stage in range(3):
		var image: Image = arena.normal_contour_texture(1,stage).get_image()
		expect(contour_count(image) == [184,212,244][stage],"exact measured native contour area")
		var rect: Rect2i = image.get_used_rect()
		expect(rect.size == [Vector2i(28,28),Vector2i(28,32),Vector2i(32,32)][stage],"native outline dimensions at 2x")

func split_fall() -> void:
	for rotation in [1,3]:
		for supported_pivot in [true,false]:
			for depth in [1,3,6]:
				var model: RefCounted = MatchModel.new()
				var arena: RefCounted = Arena.new()
				var px: int = 2 if rotation == 1 else 3
				var sx: int = px + (1 if rotation == 1 else -1)
				var support_col: int = px if supported_pivot else sx
				var free_col: int = sx if supported_pivot else px
				var free_code: int = 2 if supported_pivot else 1
				var start: int = 13 - depth
				for y in range(start+1,14): model.boards[0].cells[y*6+support_col] = 4
				model.pairs[0] = PairModel.new(Vector2i(px,start),1,2)
				model.pairs[0].rotation = rotation
				model.motion[0].contact = 2
				setup_result(model)
				for frame in range(1,depth+6):
					step(model,arena)
					if frame >= 2:
						var row: int = mini(13,start+frame-2)
						expect(arena.get_visual_cells(0,model.boards[0].cells)[row*6+free_col] == free_code,"unsupported gem follows each native row")
						trace.append({"case":"split_r%d_%s_d%d" % [rotation,supported_pivot,depth],"frame":frame,"free_row":row,"phase":model.motion[0].phase})

func ghost() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	for x in range(1,4): model.boards[0].cells[78+x] = 2
	model.boards[0].cells[78] = 10
	model.motion[0].phase = 3
	setup_result(model)
	var disappeared: bool = false
	var impacts: int = 0
	for frame in range(1,100):
		step(model,arena)
		var visual: int = arena.get_visual_cells(0,model.boards[0].cells)[79]
		if visual == 0: disappeared = true
		expect(not disappeared or visual == 0,"ghost must never reappear")
		expect(arena.wave_queues[0].is_empty(),"live path never predicts future waves")
		if frame == 65: expect(visual == 2 and model.motion[0].clear_timer == 1,"no early logical removal")
		if frame == 66:
			expect(visual == 0 and model.motion[0].phase == 3,"mask released with actual removal")
			impacts = arena.vfx_sprites.size()
		trace.append({"case":"ghost","frame":frame,"phase":model.motion[0].phase,"timer":model.motion[0].clear_timer,"logical":model.boards[0].cells[79],"visual":visual})
	expect(impacts > 0,"actual wave emits impact once")

func rotations() -> void:
	for contact in [16,15,2,1]:
		for direction in [-1,1]:
			var model: RefCounted = MatchModel.new()
			var arena: RefCounted = Arena.new()
			model.pairs[0] = PairModel.new(Vector2i(2,10),1,3)
			model.motion[0].contact = contact
			var accepted: bool = model.rotate(0,direction)
			expect(accepted == (contact in [15,2]),"rotation permission unchanged at contact %d" % contact)
			var before: String = var_to_str(state(model))
			arena.step_from_model(model)
			expect(var_to_str(state(model)) == before,"presentation never extends rotation window")

func powers() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	for x in [0,1,3,4]:
		for y in [12,13]: model.boards[0].cells[y*6+x] = 1
	model.Rules.form_powers(model.boards[0])
	model.frame = 1
	setup_result(model)
	arena.step_from_model(model)
	for y in [12,13]: model.boards[0].cells[y*6+2] = 1
	model.motion[0].phase = 3
	step(model,arena)
	step(model,arena)
	for age in range(11):
		var logical: Array = model.boards[0].power_gems
		var visual: Array = arena.get_visual_powers(0,logical)
		expect(logical == [Rect2i(0,12,5,2)],"power simulation rectangle untouched")
		expect(visual == ([Rect2i(0,12,3,2),Rect2i(3,12,2,2)] if age < 10 else logical),"native union intermediate geometry")
		expect(arena.power_flash_ticks[0] == 0,"no arbitrary 14-frame crystallization flash")
		step(model,arena)
	for size in [Vector2i(2,2),Vector2i(2,3)]:
		model = MatchModel.new()
		arena = Arena.new()
		for y in range(14-size.y,14):
			for x in range(2): model.boards[0].cells[y*6+x] = 1
		model.motion[0].phase = 3
		setup_result(model)
		step(model,arena)
		step(model,arena)
		var rect: Rect2i = Rect2i(Vector2i(0,14-size.y),size)
		for age in range(20):
			expect(arena.get_visual_powers(0,model.boards[0].power_gems) == [rect],"formation/growth has exact current geometry")
			step(model,arena)

	model = MatchModel.new()
	arena = Arena.new()
	for y in [12,13]:
		for x in [0,1]: model.boards[0].cells[y*6+x] = 1
	model.Rules.form_powers(model.boards[0])
	model.frame = 1
	setup_result(model)
	arena.step_from_model(model)
	for x in [0,1]: model.boards[0].cells[11*6+x] = 1
	model.motion[0].phase = 3
	step(model,arena)
	step(model,arena)
	expect(arena.get_visual_powers(0,model.boards[0].power_gems) == [Rect2i(0,11,2,3)],"existing 2x2 grows to 2x3 without anticipation")

func unmeasured_shapes() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	for y in [11,12,13]: model.boards[0].cells[y*6+2] = 1
	model.frame = 1
	setup_result(model)
	for tick in range(20):
		arena.step_from_model(model)
		for y in [11,12,13]: expect(arena.temporal_connection_stage(0,y*6+2) == 0,"do not extrapolate two-gem contour to triples")

func multiple_waves() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	model.boards[0].load_cells(Fixtures.chain_board(3))
	model.motion[0].phase = 3
	setup_result(model)
	var waves: int = 0
	for frame in range(300):
		step(model,arena)
		var actual: int = model.motion[0].result.get("waves",[]).size()
		if actual > waves:
			expect(actual == waves+1,"three-wave presentation follows one real removal at a time")
			waves = actual
		expect(arena.wave_queues[0].is_empty(),"no precomputed chain in temporal presentation")
		if not arena.active_wave[0].is_empty():
			expect(arena.active_wave[0].chain == waves+1,"only the current native wave is presented")
	expect(waves == 3 and arena.active_wave[0].is_empty(),"all three native waves finish without retained ghosts")

func _initialize() -> void:
	landing(false)
	landing(true)
	split_fall()
	rotations()
	unmeasured_shapes()
	powers()
	ghost()
	multiple_waves()
	var output: String = OS.get_environment("PF_REPORT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		var file: FileAccess = FileAccess.open(output.path_join("visual_timeline_v10_3_2.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"trace":trace},"  "))
	print("VISUAL_TIMELINE_V10_3_2 ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
