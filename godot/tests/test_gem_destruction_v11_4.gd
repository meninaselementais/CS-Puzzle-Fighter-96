extends SceneTree
const MatchModel = preload("res://core/match_model.gd")
const Rules = preload("res://core/resolution.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
const Hud = preload("res://presentation/hud_presenter.gd")
class GameView extends "res://presentation/main.gd":
	pass
var checks: int = 0
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var timings: Array[int] = []
var baseline_timings: Array[int] = []
var game: Node2D
var before_game: Node2D
var before_view: SubViewport
var folder: String
var reference: GDScript

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed,value.state]
	if value is RefCounted:
		var result: Dictionary = {}
		for property in value.get_script().get_script_property_list(): result[property.name] = state(value.get(property.name))
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

func fingerprint(model: RefCounted) -> String:
	return JSON.stringify(state(model))

func _initialize() -> void:
	call_deferred("run")

func setup(model: RefCounted, dimensions: Vector2i, color_code: int, is_c4: bool = false, chain: int = 0, both: bool = false) -> void:
	for player in range(2):
		model.boards[player].cells.fill(0)
		if player==1 and not both: continue
		if chain>0:
			model.boards[player].load_cells(Fixtures.chain_board(chain))
		elif is_c4:
			model.boards[player].load_cells(Fixtures.build_c4_board())
		else:
			for y in range(14-dimensions.y,14):
				for x in range(0 if dimensions.x==6 else 1,dimensions.x if dimensions.x==6 else 1+dimensions.x): model.boards[player].cells[y*6+x] = color_code
			if dimensions.x<4:
				for y in range(11,14): model.boards[player].cells[y*6+5] = color_code%4+1
			model.boards[player].cells[13*6] = color_code|8
		Rules.form_powers(model.boards[player])
		model.motion[player].phase = 3
		model.motion[player].result = {"waves":[],"score":0,"attack":0,"converted":0,"gravity":0}

func render_both() -> void:
	game.queue_redraw()
	before_game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func capture(case_name: String, stage: String, tick: int) -> void:
	var target: String = folder.path_join(case_name)
	DirAccess.make_dir_recursive_absolute(target)
	var image: Image = root.get_texture().get_image()
	var old_image: Image = before_view.get_texture().get_image()
	expect(image.save_png(target.path_join(stage+"_after.png")) == OK,"save after " + case_name + stage)
	expect(old_image.save_png(target.path_join(stage+"_before.png")) == OK,"save before " + case_name + stage)
	expect(image.get_region(Rect2i(56,100,216,400)).save_png(target.path_join(stage+"_detail.png")) == OK,"save well detail")
	cases[-1].captures.append({"stage":stage,"tick":tick,"logical_frame":int(game.model.frame)})

func capture_sequence(case_name: String) -> void:
	var index: int = int(cases[-1].sequence_frames)
	for version in ["after","before"]:
		var sequence: String = folder.path_join(case_name+"/sequence_"+version)
		DirAccess.make_dir_recursive_absolute(sequence)
		var image: Image = root.get_texture().get_image() if version=="after" else before_view.get_texture().get_image()
		image.get_region(Rect2i(56,100,216,400)).save_png(sequence.path_join("%03d.png" % index))
	cases[-1].sequence_frames = index+1

func run_case(case_name: String, dimensions: Vector2i, color_code: int, is_c4: bool = false, chain: int = 0, both: bool = false, animate: bool = false) -> void:
	game.model = MatchModel.new()
	before_game.model = MatchModel.new()
	game.arena = Arena.new()
	before_game.arena = reference.new()
	setup(game.model,dimensions,color_code,is_c4,chain,both)
	setup(before_game.model,dimensions,color_code,is_c4,chain,both)
	cases.append({"id":case_name,"captures":[],"peak_motes":0,"peak_bursts":0,"peak_shards":0,"burst_frames":[],"render_usec":[],"white_fraction":[],"sequence_frames":0,"draw_calls_peak":0})
	await render_both()
	for player in range(2):
		var clip: Control = game.get_node("DestructionLight%d" % player) as Control
		expect(clip.clip_contents and clip.size==Vector2(192,384) and clip.mouse_filter==Control.MOUSE_FILTER_IGNORE,"additive layer clipped and cannot intercept controls")
	capture(case_name,"00_before",0)
	var after_burst: int = -1
	var saw_pre: bool = false
	var saw_first: bool = false
	for tick in range(1,181 if chain<3 else 360):
		game.model.tick()
		before_game.model.tick()
		var unchanged: String = fingerprint(game.model)
		var begin: int = Time.get_ticks_usec()
		game.arena.step_from_model(game.model)
		var elapsed: int = Time.get_ticks_usec()-begin
		timings.append(elapsed)
		begin = Time.get_ticks_usec()
		before_game.arena.step_from_model(before_game.model)
		baseline_timings.append(Time.get_ticks_usec()-begin)
		expect(fingerprint(game.model)==unchanged,"presentation preserves all properties " + case_name)
		expect(fingerprint(game.model)==fingerprint(before_game.model),"V11.3 model, RNG, stream, turns and attacks unchanged " + case_name)
		for player in range(2):
			expect(game.arena.get_visual_cells(player,game.model.boards[player].cells)==game.model.boards[player].cells,"live cells never hidden or restored " + case_name)
		var fx: RefCounted = game.arena.destruction
		cases[-1].peak_motes = maxi(int(cases[-1].peak_motes),fx.motes.size())
		cases[-1].peak_bursts = maxi(int(cases[-1].peak_bursts),fx.bursts.size())
		cases[-1].peak_shards = maxi(int(cases[-1].peak_shards),game.arena.gem_sparks.size())
		if not fx.anticipation[0].is_empty() and not saw_pre and int(fx.anticipation[0].remaining)<=maxi(1,int(int(fx.anticipation[0].total)/2.0)):
			saw_pre = true
			await render_both()
			capture(case_name,"01_activation",tick)
		if int(fx.emitted[0])>cases[-1].burst_frames.size():
			cases[-1].burst_frames.append(game.model.frame)
			await render_both()
			capture(case_name,"wave_%02d_flash" % int(fx.emitted[0]),tick)
			expect(int(fx.emitted[0])==game.model.motion[0].chain_count,"one VFX event per actual resolution wave")
			if not saw_first:
				saw_first = true
				after_burst = 0
				if dimensions in [Vector2i(2,2),Vector2i(2,3),Vector2i(5,2)]:
					var power_events: Array = fx.bursts.filter(func(event: Dictionary) -> bool: return event.kind=="power" and int(event.player)==0)
					expect(power_events.size()==1 and power_events[0].extent==Vector2(dimensions)*32.0*0.55,"Power flash shape follows actual formation " + case_name)
				if is_c4: expect(fx.bursts.filter(func(event: Dictionary) -> bool: return event.kind=="c4").size()==1,"one exclusive C4 central blast")
		if after_burst>=0:
			var stage: String = ""
			if after_burst==0: stage="02_flash"
			elif after_burst==5: stage="03_fragments"
			elif after_burst==12: stage="04_particles"
			elif after_burst==25: stage="05_dissipation"
			elif after_burst==55: stage="06_result"
			if not stage.is_empty():
				await render_both()
				capture(case_name,stage,tick)
				if after_burst in [5,12,25]:
					var actual: Image = root.get_texture().get_image()
					var white: int = 0
					for y in range(108,492,2):
						for x in range(64,256,2):
							var pixel: Color = actual.get_pixel(x,y)
							if pixel.r>0.94 and pixel.g>0.94 and pixel.b>0.94: white += 1
					var fraction: float = float(white)/(96.0*192.0)
					cases[-1].white_fraction.append({"age":after_burst,"fraction":fraction})
					expect(fraction<0.12,"no broad whiteout after initial flash " + case_name)
				if after_burst==5:
					var frozen_fx: String = var_to_str([fx.bursts,fx.motes,fx.anticipation])
					await render_both()
					expect(var_to_str([fx.bursts,fx.motes,fx.anticipation])==frozen_fx,"paused redraw does not advance visual clocks")
			after_burst += 1
		if animate and tick%2==0:
			await render_both()
			capture_sequence(case_name)
		if tick%8==0:
			begin = Time.get_ticks_usec()
			await render_both()
			cases[-1].render_usec.append(Time.get_ticks_usec()-begin)
			cases[-1].draw_calls_peak = maxi(int(cases[-1].draw_calls_peak),int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		expect(fingerprint(game.model)==fingerprint(before_game.model),"redraw uses the same V10 NEXT generation sequence")
	expect(saw_pre and saw_first,"real anticipation and removal exercised " + case_name)
	expect(game.arena.destruction.emitted[0]==(chain if chain>0 else 1),"all expected actual waves observed " + case_name)
	if both: expect(game.arena.destruction.emitted[1]>0,"simultaneous P2 wave observed")
	# Stop simulation events and drain presentation only: no later wave is fabricated.
	for tick in range(100):
		game.arena.step_from_model(game.model)
		before_game.arena.step_from_model(before_game.model)
	expect(game.arena.destruction.bursts.is_empty() and game.arena.destruction.motes.is_empty(),"all added effects expire " + case_name)
	var frozen: String = fingerprint(game.model)
	for repeat in range(100): Hud.snapshot(game.model)
	expect(fingerprint(game.model)==frozen,"HUD still read-only")
	await render_both()
	capture(case_name,"07_final",game.model.frame)

func deterministic_and_budget() -> void:
	var a: RefCounted = Arena.new()
	var b: RefCounted = Arena.new()
	var cells: PackedInt32Array = PackedInt32Array()
	cells.resize(84)
	for i in range(12,84): cells[i] = 4
	cells[78] = 12
	a.enqueue_visual_waves(0,cells,Vector2(64,108))
	b.enqueue_visual_waves(0,cells,Vector2(64,108))
	for player in range(2):
		var w: Dictionary = a.active_wave[0].duplicate(true)
		a.destruction.emit_wave(player,w)
		b.destruction.emit_wave(player,w)
	expect(var_to_str(a.destruction.bursts)==var_to_str(b.destruction.bursts) and var_to_str(a.destruction.motes)==var_to_str(b.destruction.motes),"identical events produce identical VFX without RNG")
	expect(a.destruction.bursts.size()<=192 and a.destruction.motes.size()<=320,"bounded simultaneous full-board VFX")
	expect(a.destruction.mote_counts==[160,160],"equal particle budgets for both players under full-board load")
	for tick in range(100): a.destruction.step()
	expect(a.destruction.bursts.is_empty() and a.destruction.motes.is_empty(),"full-board effects expire")
	for tick in range(100): b.destruction.step()
	expect(var_to_str(a.destruction.bursts)==var_to_str(b.destruction.bursts) and var_to_str(a.destruction.motes)==var_to_str(b.destruction.motes),"effect lifecycle is deterministic")
	a.destruction.clear()
	expect(a.destruction.emitted==[0,0],"restart clears event counters")

func run() -> void:
	folder = OS.get_environment("PF_REPORT")
	if folder.is_empty(): quit(1); return
	reference = GDScript.new()
	reference.source_code = FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../relatorios/v11_4/arena_before.gd.txt"))
	if reference.reload()!=OK: quit(1); return
	root.size = Vector2i(1000,700)
	game = GameView.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	before_view = SubViewport.new()
	before_view.size = Vector2i(1000,700)
	before_view.snap_2d_transforms_to_pixel = root.snap_2d_transforms_to_pixel
	before_view.snap_2d_vertices_to_pixel = root.snap_2d_vertices_to_pixel
	before_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(before_view)
	before_game = GameView.new()
	before_view.add_child(before_game)
	before_game.set_process(false)
	before_game.set_physics_process(false)
	deterministic_and_budget()
	for color_code in range(1,5): await run_case("color_%d" % color_code,Vector2i(3,1),color_code)
	await run_case("power_2x2",Vector2i(2,2),1)
	await run_case("power_2x3",Vector2i(2,3),3)
	await run_case("power_5x2",Vector2i(5,2),4,false,0,false,true)
	await run_case("combo_small",Vector2i.ONE,1,false,1)
	await run_case("combo_medium",Vector2i.ONE,1,false,3)
	await run_case("combo_large",Vector2i.ONE,1,false,5,false,true)
	await run_case("c4",Vector2i.ONE,1,true,0,false,true)
	await run_case("simultaneous",Vector2i(5,2),2,false,0,true)
	await run_case("stress_simultaneous",Vector2i(6,10),3,false,0,true)
	timings.sort()
	baseline_timings.sort()
	var file: FileAccess = FileAccess.open(folder.path_join("explosion_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"update_usec":{"median":timings[int(timings.size()/2.0)],"p95":timings[int(timings.size()*0.95)],"max":timings[-1]},"update_before_usec":{"median":baseline_timings[int(baseline_timings.size()/2.0)],"p95":baseline_timings[int(baseline_timings.size()*0.95)],"max":baseline_timings[-1]},"performance_note":"CPU presentation update; render timings include synchronization and reference viewport, not a standalone GPU benchmark"},"  "))
	file.close()
	print("EXPLOSIONS_V11_4 checks=",checks," failures=",failures)
	game.queue_free()
	before_view.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
