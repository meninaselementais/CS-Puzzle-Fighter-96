extends SceneTree
const Rotation = preload("res://presentation/pair_rotation_visual.gd")
const Fixture = preload("res://tests/rotation_fixture_v10_3_3.gd")
var checks: int = 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var primary_steps: int = 0
var active_samples: int = 0
var residual_samples: int = 0
var spawn_residual_samples: int = 0
var failure_count: int = 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failure_count += 1
		if failures.size() < 100: failures.append(label)

func verify_case(item: Dictionary, primary: bool) -> void:
	var model: RefCounted = Fixture.prepare(item,primary)
	var visual: RefCounted = Rotation.new()
	var first_identity: String = str(Rotation.snapshot(model,0).identity)
	var new_pair_rotation_seen: bool = false
	for row in item.samples:
		if int(row.frame) == 0: continue
		model.input_masks[0] = int(row.input)
		var before_state: String = var_to_str(Fixture.state(model))
		var before: Dictionary = Rotation.snapshot(model,0)
		expect(var_to_str(Fixture.state(model)) == before_state,"snapshot read-only "+str(item.id))
		model.tick()
		var after: Dictionary = Rotation.snapshot(model,0)
		var after_state: String = var_to_str(Fixture.state(model))
		visual.step(before,after)
		expect(var_to_str(Fixture.state(model)) == after_state,"step read-only "+str(item.id))
		var label: String = "%s F%d" % [item.id,row.frame]
		var active: bool = int(row.phase) == 0
		if str(after.identity) != first_identity and int(before.phase) == 0 and (int(before.input) & ~int(before.previous_input) & 768) != 0:
			new_pair_rotation_seen = true
		expect(int(after.phase) == int(row.phase),label+" phase")
		if active:
			active_samples += 1
			var native_displacement: Vector2i = Vector2i(row.dx,row.dy)
			# Native RAM resumes its stale counter at spawn. The authorized contract explicitly clears it.
			var spawn_residual: bool = str(after.identity) != first_identity and not new_pair_rotation_seen and int(row.timer) > 0
			if spawn_residual:
				spawn_residual_samples += 1
				native_displacement = Vector2i.ZERO
				expect(visual.timer == 0 and visual.native_offset == Vector2i.ZERO,label+" no transfer of stale native RAM to new pair")
			else:
				expect(visual.timer == int(row.timer),label+" timer got %d expected %d" % [visual.timer,row.timer])
				expect(visual.native_offset == native_displacement,label+" displacement got %s expected (%d,%d)" % [visual.native_offset,row.dx,row.dy])
				if int(row.timer) > 0: expect(visual.mode == int(row.mode),label+" direction")
			expect(model.pairs[0].pivot == Vector2i(row.x,row.y) and model.pairs[0].rotation == int(row.rotation),label+" geometry")
			expect(model.pairs[0].colors == PackedInt32Array(row.colors),label+" color identity")
			var points: Array[Vector2] = visual.points(model.pairs[0],model.motion[0],str(after.identity))
			var pivot: Vector2 = Vector2(row.x,float(row.y)+float(row.offset)/16.0)
			var satellite: Vector2 = pivot+Vector2(Rotation.OFFSETS[int(row.rotation)])+Vector2(native_displacement)/16.0
			expect(points[0] == pivot and points[1] == satellite,label+" graphical coordinates")
			if primary and int(row.frame) >= 4 and int(row.frame) <= 11:
				primary_steps += 1
				records.append({"case":item.id,"frame":row.frame,"timer":visual.timer,"mode":visual.mode,"dx":visual.native_offset.x,"dy":visual.native_offset.y,"native_dx":row.dx,"native_dy":row.dy,"pivot":[points[0].x,points[0].y],"satellite":[points[1].x,points[1].y],"match":true})
		else:
			if int(row.timer) != 0: residual_samples += 1
			expect(visual.timer == 0 and visual.native_offset == Vector2i.ZERO,label+" discarded after deposit")
		var saved: Array = [visual.timer,visual.mode,visual.native_offset]
		visual.step(before,after)
		expect(saved == [visual.timer,visual.mode,visual.native_offset],label+" duplicate observation does not advance")
	visual.reset()
	expect(visual.timer == 0 and visual.native_offset == Vector2i.ZERO and visual.identity.is_empty(),"explicit reset "+str(item.id))

func extra_checks(data: Dictionary) -> void:
	var model: RefCounted = Fixture.prepare(data.primary[0],true)
	var visual: Array[RefCounted] = [Rotation.new(),Rotation.new()]
	model.pairs[1] = model.pairs[0].copy()
	model.motion[1].fall_countdown = 100
	model.input_masks.assign([512,256])
	var before: Array[Dictionary] = [Rotation.snapshot(model,0),Rotation.snapshot(model,1)]
	model.tick()
	for player in range(2): visual[player].step(before[player],Rotation.snapshot(model,player))
	expect(visual[0].mode == 0 and visual[1].mode == 1 and visual[0].timer == 7 and visual[1].timer == 7,"two players have independent simultaneous trajectories")
	var paused: Vector2i = visual[0].native_offset
	for draw in range(100): visual[0].points(model.pairs[0],model.motion[0],visual[0].identity)
	expect(visual[0].native_offset == paused and visual[0].timer == 7,"render calls cannot advance timer / pause")
	model.pair_index[0] += 1
	var positions: Array[Vector2] = visual[0].points(model.pairs[0],model.motion[0],Rotation.snapshot(model,0).identity)
	expect(positions[1] == Vector2(model.pairs[0].positions()[1]),"identity prevents transfer even before next observation")
	model.restart()
	before[0] = Rotation.snapshot(model,0)
	model.tick()
	visual[0].step(before[0],Rotation.snapshot(model,0))
	expect(visual[0].timer == 0,"frame discontinuity resets observer")

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pair_rotation_v10_3_3.json"))
	for item in data.primary: verify_case(item,true)
	for item in data.cases: verify_case(item,false)
	extra_checks(data)
	expect(primary_steps == 80,"all 80 primary trajectory pairs checked")
	var output: String = OS.get_environment("PF_REPORT")
	DirAccess.make_dir_recursive_absolute(output)
	var file: FileAccess = FileAccess.open(output.path_join("rotation_tests.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failure_count":failure_count,"failures":failures,"primary_steps":primary_steps,"active_samples":active_samples,"inactive_native_residual_samples":residual_samples,"spawn_native_residual_samples":spawn_residual_samples,"trajectory":records},"  "))
	print("ROTATION_V10_3_3 checks=",checks," primary=",primary_steps," active=",active_samples," failures=",failures)
	quit(0 if failures.is_empty() else 1)
