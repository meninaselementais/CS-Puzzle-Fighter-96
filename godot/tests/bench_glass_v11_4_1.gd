extends SceneTree
## V11.4.1 glass prototype budget comparison (isolated; no match model involved).
## Measures real instance counts, CPU time (emit + batch build + per-frame update),
## GPU render time, draw calls and an overdraw estimate for several density limits.
const Glass = preload("res://presentation/vfx/glass_shatter.gd")
var canvas: Node2D
var results: Array = []

func _initialize() -> void:
	call_deferred("run")

func plate_wave(x: int, y: int) -> Dictionary:
	var wave: Dictionary = {"phase":"pre","timer":6,"powers_before":[Rect2i(x,y,5,2)],"removed":[]}
	for yy in range(y,y+2):
		for xx in range(x,x+5): wave.removed.append({"x":xx,"y":yy,"code":4,"color":4,"is_power":true})
	return wave

func single_wave(x: int, y: int) -> Dictionary:
	return {"phase":"pre","timer":6,"powers_before":[],"removed":[{"x":x,"y":y,"code":1,"color":1,"is_power":false}]}

func live_stats(glass: RefCounted) -> Dictionary:
	var instances: int = 0
	var area: float = 0.0
	for group in glass.groups:
		if not is_instance_valid(group.node): continue
		for child in group.node.get_children():
			if child is MultiMeshInstance2D:
				var mm: MultiMesh = child.multimesh
				var used: int = int(child.get_meta("instances",mm.instance_count))
				instances += used
				for i in range(used):
					var s: Vector2 = mm.get_instance_transform_2d(i).get_scale()
					area += s.x*s.y
	return {"instances":instances,"quad_area":area}

func scenario(label: String, density: float, waves: Array) -> void:
	for c in canvas.get_children(): c.free()
	var glass: RefCounted = Glass.new()
	glass.density = density
	var origins: Array[Vector2] = [Vector2(40,40),Vector2(300,40)]
	var begin: int = Time.get_ticks_usec()
	for entry in waves: glass.emit(int(entry[0]),entry[1])
	var cpu: Array[int] = [Time.get_ticks_usec()-begin]
	var gpu: Array[float] = []
	var draws: int = 0
	var peak: Dictionary = {"instances":0,"quad_area":0.0}
	var covered_at_peak: int = 0
	for frame in range(glass.LIFETIME):
		begin = Time.get_ticks_usec()
		glass.draw_layers(canvas,origins)
		glass.step()
		cpu.append(Time.get_ticks_usec()-begin)
		await process_frame
		await RenderingServer.frame_post_draw
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		draws = maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		if frame==3:
			peak = live_stats(glass)
			var img: Image = root.get_texture().get_image()
			for y in range(0,img.get_height()):
				for x in range(0,img.get_width()):
					if img.get_pixel(x,y).get_luminance()>0.02: covered_at_peak += 1
	var build: int = cpu[1]
	var steady: Array[int] = cpu.slice(2)
	steady.sort()
	gpu.sort()
	var item: Dictionary = {"scenario":label,"density":density,"events":glass.history.size(),
		"instances_live":peak.instances,"cpu_emit_usec":cpu[0],"cpu_first_frame_build_usec":build,
		"cpu_update_median_usec":steady[int(steady.size()/2.0)],"cpu_update_max_usec":steady[-1],
		"gpu_ms_median":gpu[int(gpu.size()/2.0)],"gpu_ms_max":gpu[-1],"draw_calls_peak":draws,
		"quad_area_px":snappedf(peak.quad_area,1.0),"covered_px":covered_at_peak,
		"overdraw_estimate":snappedf(peak.quad_area/maxf(1.0,float(covered_at_peak)),0.01)}
	results.append(item)
	print(JSON.stringify(item))
	glass.clear()

func run() -> void:
	root.size = Vector2i(560,480)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.set_default_clear_color(Color.BLACK)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	canvas = Node2D.new()
	root.add_child(canvas)
	await process_frame
	Glass.layouts.clear()
	var warm_begin: int = Time.get_ticks_usec()
	Glass.new()
	var warm_usec: int = Time.get_ticks_usec()-warm_begin
	print("warm_layout_cache_usec=",warm_usec)
	for density in [0.25,0.5,1.0,1.3]:
		await scenario("single_gem",density,[[0,single_wave(2,13)]])
		await scenario("plate_5x2",density,[[0,plate_wave(1,12)]])
		await scenario("plate_both_players",density,[[0,plate_wave(1,12)],[1,plate_wave(0,12)]])
		await scenario("stress_3_plates_4_gems_each",density,[[0,plate_wave(1,12)],[0,plate_wave(0,10)],[0,plate_wave(1,8)],[0,single_wave(0,7)],[0,single_wave(1,7)],[0,single_wave(2,7)],[0,single_wave(3,7)],
			[1,plate_wave(1,12)],[1,plate_wave(0,10)],[1,plate_wave(1,8)],[1,single_wave(0,7)],[1,single_wave(1,7)],[1,single_wave(2,7)],[1,single_wave(3,7)]])
	var folder: String = OS.get_environment("PF_REPORT")
	if not folder.is_empty():
		var file: FileAccess = FileAccess.open(folder.path_join("glass_budget.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"warm_layout_cache_usec":warm_usec,"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"results":results},"  "))
		file.close()
	print("GLASS_BENCH done=",results.size())
	quit(0)
