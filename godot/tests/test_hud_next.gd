extends SceneTree
## Render interception is checked against the pair spawned by the real resolver,
## not against stream[pair_index + 1] or a second presenter calculation.
const MatchModel = preload("res://core/match_model.gd")
const Hud = preload("res://presentation/hud_presenter.gd")
const Session = preload("res://core/match_session.gd")

class ObservedGame extends "res://presentation/main.gd":
	var next_calls: Array[int] = []
	func get_next_colors(player: int) -> Array:
		next_calls.append(player)
		return super.get_next_colors(player)

class ObservedArena extends "res://presentation/cs_arena.gd":
	var submitted: Array[Dictionary] = []
	var loaded: Array[String] = []
	func draw_gem_sprite(canvas: CanvasItem, center: Vector2, code: int, kind_enum, phase_seed: int = 0, scale_mod: Vector2 = Vector2.ONE) -> void:
		# Literal, independent expected NEXT regions; calls still reach the real renderer.
		if center in [Vector2(308,130), Vector2(308,162), Vector2(692,130), Vector2(692,162)]:
			submitted.append({"center": center, "code": code, "seed": phase_seed})
		super.draw_gem_sprite(canvas, center, code, kind_enum, phase_seed, scale_mod)
	func load_tex(file_name: String) -> Texture2D:
		loaded.append(file_name)
		return super.load_tex(file_name)

var checks: int = 0
var failures: Array[String] = []
var evidence: Array[Dictionary] = []
var game: Node2D
var baseline: Node2D
var spy: RefCounted
var baseline_view: SubViewport
var folder: String
var saw_crash: Array[bool] = [false,false]
var saw_c4: Array[bool] = [false,false]
var colors_seen: Array[Dictionary] = [{},{}]

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed, value.state]
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

func model_state(model: RefCounted) -> String:
	return JSON.stringify(state(model))

func _initialize() -> void:
	call_deferred("run")

func render_both() -> void:
	spy.submitted.clear()
	spy.loaded.clear()
	game.next_calls.clear()
	baseline.next_calls.clear()
	game.queue_redraw()
	baseline.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	expect(game.next_calls == [0,1], "one P1 then P2 NEXT query per draw")
	expect(game.next_calls == baseline.next_calls, "V10 query count and order unchanged")
	expect(spy.submitted.size() == 4, "exactly four NEXT gems reach renderer")
	expect(model_state(game.model) == model_state(baseline.model), "all model properties and RNG equal live V10 reference after draw")

func check_draw_and_spawn(player: int, step: int) -> void:
	if spy.submitted.size() != 4: return
	var upper: Dictionary = spy.submitted[player*2]
	var lower: Dictionary = spy.submitted[player*2+1]
	var center_x: float = 308.0 if player == 0 else 692.0
	expect(upper.center == Vector2(center_x,130) and lower.center == Vector2(center_x,162), "P%d satellite above pivot with 32px gap" % player)
	expect(upper.seed == player*10+1 and lower.seed == player*10+2, "V10 animation seeds preserved")
	# Real turn completion, including real spawn(); no direct stream/index prediction.
	game.model.resolve_turn(player)
	baseline.model.resolve_turn(player)
	var actual: PackedInt32Array = game.model.pairs[player].colors
	for code in actual:
		if (code & 7) in [1,2,3,4]: colors_seen[player][code & 7] = true
	expect(int(lower.code) == actual[0] and int(upper.code) == actual[1], "P%d displayed pair is the next real spawned pair, step %d" % [player,step])
	expect(model_state(game.model) == model_state(baseline.model), "V10 state identical after real turn completion")
	if (int(upper.code) & 8) != 0:
		saw_crash[player] = true
		expect("gem_crash_%d.png" % (int(upper.code)&7) in spy.loaded, "Crash uses colored orb asset")
	if int(upper.code) == 5:
		saw_c4[player] = true
		expect("gem_c4_0.png" in spy.loaded or "gem_c4_1.png" in spy.loaded, "C4 uses blinking CS asset")
	if step < 2 or int(upper.code) == 5:
		evidence.append({"step":step,"player":player,"upper_code":upper.code,"lower_code":lower.code,"spawned_colors":Array(actual)})

func capture(label: String) -> void:
	var image: Image = root.get_texture().get_image()
	expect(not image.is_empty(), "nonempty real framebuffer " + label)
	expect(image.save_png(folder.path_join(label+".png")) == OK, "save framebuffer " + label)
	var transform: Transform2D = root.get_final_transform()
	for player in range(2):
		var box: Rect2 = Rect2(Vector2(284 if player == 0 else 668,108),Vector2(48,76))
		var top_left: Vector2 = transform * box.position
		var bottom_right: Vector2 = transform * box.end
		var crop: Rect2i = Rect2i(Vector2i(top_left)-Vector2i(10,30),Vector2i(bottom_right-top_left)+Vector2i(20,70))
		expect(image.get_region(crop).save_png(folder.path_join(label+"_p%d.png" % (player+1))) == OK,"save NEXT detail")
		expect(absf((bottom_right.x-top_left.x) - (bottom_right.y-top_left.y)*48.0/76.0) < 1.0,"NEXT physical aspect preserved " + label)
		expect(absf(transform.x.length()-transform.y.length()) < 0.002,"uniform canvas scale " + label)
	evidence.append({"capture":label,"framebuffer":str(image.get_size()),"canvas_scale":str(transform.get_scale()),"window":str(root.size)})

func run() -> void:
	folder = OS.get_environment("PF_REPORT")
	if folder.is_empty():
		push_error("PF_REPORT is required")
		quit(1)
		return
	# Load the untouched V10 presentation saved before editing. It runs the same
	# model on its own viewport, including the old generator inside _draw().
	var reference: GDScript = GDScript.new()
	var baseline_path: String = ProjectSettings.globalize_path("res://").path_join("../relatorios/v11_3/baseline_main.gd.txt")
	var source: String = FileAccess.get_file_as_string(baseline_path)
	source = source.replace("func get_next_colors(player: int) -> Array:", "var next_calls: Array[int] = []\n\nfunc get_next_colors(player: int) -> Array:\n\tnext_calls.append(player)")
	source = source.replace("var arena = Arena.new()", "var arena: RefCounted")
	source = source.replace("var offset := arena", "var offset: float = arena").replace("var wy :=", "var wy: float =")
	reference.source_code = source
	if reference.reload() != OK:
		expect(false,"V10 reference compiles")
		quit(1)
		return
	baseline = reference.new()
	var old_arena: GDScript = GDScript.new()
	old_arena.source_code = FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../relatorios/v11_3/baseline_cs_arena.gd.txt"))
	expect(old_arena.reload() == OK,"V10 arena reference compiles")
	baseline.arena = old_arena.new()
	baseline_view = SubViewport.new()
	baseline_view.size = Vector2i(1000,700)
	baseline_view.snap_2d_transforms_to_pixel = root.snap_2d_transforms_to_pixel
	baseline_view.snap_2d_vertices_to_pixel = root.snap_2d_vertices_to_pixel
	baseline_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(baseline_view)
	baseline_view.add_child(baseline)
	baseline.set_process(false)
	baseline.set_physics_process(false)
	game = ObservedGame.new()
	spy = ObservedArena.new()
	game.arena = spy
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	await render_both()
	expect(spy.NEXT_SIZE == Vector2(48,76),"NEXT logical size 48x76")
	# 90 P1 turns, 45 P2 turns: independent indices, all colors, Crash and C4.
	for step in range(90):
		if step == 0:
			capture("next_initial_1000x700")
			var original: Image = baseline_view.get_texture().get_image()
			expect(original.save_png(folder.path_join("v10_reference_1000x700.png")) == OK,"save live V10 reference")
			var current: PackedByteArray = root.get_texture().get_image().get_data()
			var old_pixels: PackedByteArray = original.get_data()
			var outside_changes: int = 0
			var inside_changes: int = 0
			for y in range(700):
				for x in range(1000):
					var pixel: int = (y*1000+x)*4
					if current[pixel] != old_pixels[pixel] or current[pixel+1] != old_pixels[pixel+1] or current[pixel+2] != old_pixels[pixel+2]:
						if Rect2i(274,24,116,198).has_point(Vector2i(x,y)) or Rect2i(630,24,114,198).has_point(Vector2i(x,y)):
							inside_changes += 1
						else: outside_changes += 1
			expect(outside_changes == 0,"V10 pixels unchanged outside NEXT boxes and attached labels")
			expect(inside_changes > 0,"compact NEXT visibly differs from V10")
			evidence.append({"outside_next_changed_pixels":outside_changes,"inside_next_changed_pixels":inside_changes})
		if step == 23: capture("next_c4_p1_1000x700")
		if step == 46: capture("next_c4_p2_1000x700")
		check_draw_and_spawn(0,step)
		if step % 2 == 0: check_draw_and_spawn(1,step)
		await render_both()
	for player in range(2):
		expect(saw_crash[player] and saw_c4[player], "both Crash and C4 exercised for P%d" % player)
		expect(colors_seen[player].size() == 4,"all four colors exercised for P%d" % player)
	# Restore a natural initial Crash NEXT for the resize evidence.
	game.model.restart()
	baseline.model.restart()
	for dimensions in [Vector2i(1000,700),Vector2i(1280,896),Vector2i(1280,900),Vector2i(1600,900)]:
		root.size = dimensions
		await create_timer(0.3).timeout
		await process_frame
		await render_both()
		expect(root.size == dimensions,"actual window size " + str(dimensions))
		var factor: float = minf(float(dimensions.x)/1000.0,float(dimensions.y)/700.0)
		var actual_size: Vector2i = root.get_texture().get_image().get_size()
		expect(absf(actual_size.x-1000.0*factor) <= 1.0 and absf(actual_size.y-700.0*factor) <= 1.0,"letterboxed content size " + str(dimensions))
		capture("next_%dx%d" % [dimensions.x,dimensions.y])
	# Redraws, presenter reads, replay and paused presentation do not consume
	# additional pieces once the same V10 cache has been populated.
	var before: String = model_state(game.model)
	for repeat in range(1000): Hud.snapshot(game.model)
	expect(model_state(game.model) == before,"1000 presenter reads preserve all state")
	game.replay_mode = true
	game.menu_open = true
	for repeat in range(5): await render_both()
	expect(model_state(game.model) == before,"paused/replay redraws preserve RNG, sequence and indices")
	game.replay_mode = false
	game.menu_open = false
	# Exercise C4 off and on using only the preexisting visual clock.
	game.model.pair_index.assign([23,23])
	baseline.model.pair_index.assign([23,23])
	root.size = Vector2i(1000,700)
	await create_timer(0.3).timeout
	for clock in [0,7]:
		spy.anim_tick = clock
		baseline.arena.anim_tick = clock
		await render_both()
		capture("c4_clock_%d" % clock)
		expect("gem_c4_0.png" in spy.loaded or "gem_c4_1.png" in spy.loaded,"C4 blink renders")
	var file: FileAccess = FileAccess.open(folder.path_join("next_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"turns":[90,45],"crash":saw_crash,"c4":saw_c4,"evidence":evidence},"  "))
	file.close()
	print("HUD_NEXT checks=",checks," failures=",failures)
	game.queue_free()
	baseline_view.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
