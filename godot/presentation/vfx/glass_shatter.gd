extends RefCounted
## Opt-in prototype: blue single gems and red 5x2 plates only. No model references.
## V11.4.1 art pass: tempered glass pulverised into micro shards and crystal dust.
const FRAGMENT = preload("res://presentation/vfx/glass_fragment.gdshader")
const SURFACE = preload("res://presentation/vfx/glass_surface.gdshader")
const ATLAS = preload("res://assets/vfx/glass/shards.png")
const GRAIN = preload("res://assets/vfx/glass/grain.png")
const PLATE = preload("res://assets/vfx/glass/plate_fracture.png")
const GEM = preload("res://assets/vfx/glass/gem_fracture.png")
## Per-player simultaneous instance caps.
const MAX_MACRO: int = 48
const MAX_MICRO: int = 4096
const MAX_DUST: int = 3072
## Per destroyed cell: a 5x2 plate yields 16 slivers, 3000 micro shards and 2000 dust grains.
const MACRO_PER_CELL: float = 1.6
const MICRO_PER_CELL: int = 300
const DUST_PER_CELL: int = 200
const LIFETIME: int = 56
## V11.4.2 match integration. The default (full_scope=false) is the approved V11.4.1 behaviour.
const TINTS: Array[Color] = [Color.WHITE,Color("58baff"),Color("ffe05c"),Color("5cf59c"),Color("ff5478")]
## Shared quality profiles: density multiplies the approved per-cell counts, per-player caps stay fixed.
const QUALITY: Dictionary = {"high":1.0,"medium":0.5,"low":0.25}
const CACHE_LIMIT: int = 4
const WARM_SIZES: Array[Vector2i] = [Vector2i(2,2),Vector2i(2,3),Vector2i(3,2),Vector2i(3,3),Vector2i(4,2),Vector2i(6,2)]
enum Kind { MACRO, MICRO, DUST }
## Density multiplier used only for budget comparisons (1.0 = target counts).
var density: float = 1.0
var groups: Array[Dictionary] = []
var history: Array[Dictionary] = []
var clock: int = 0
## false = V11.4.1 selection (blue single gems and red 5x2 plates). true = all selectable gems and powers.
var full_scope: bool = false
## Small identity cache so handles() stays O(1) per cell for the wave being resolved.
var cache: Array[Dictionary] = []

func selected_prototype(wave: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region: Rect2i in wave.powers_before:
		if region.size != Vector2i(5,2): continue
		var cells: Array[Vector2i] = []
		for item in wave.removed:
			var cell: Vector2i = Vector2i(item.x,item.y)
			if region.has_point(cell) and int(item.color)==4: cells.append(cell)
		if cells.size()==10: result.append({"rect":region,"cells":cells,"color":Color("ff5478")})
	for item in wave.removed:
		if not bool(item.is_power) and int(item.code)==1 and int(item.y)>=2:
			var cell: Vector2i = Vector2i(item.x,item.y)
			result.append({"rect":Rect2i(cell,Vector2i.ONE),"cells":[cell],"color":Color("58baff")})
	return result

## V11.4.2: every gem the glass presentation takes over in a real match.
## Common gems of the four colours, Crash Gems and complete Power Gem rectangles of any size.
## The C4 diamond itself and Counter gems stay with the V11.4 effects (LED, shock ring, rays, flash).
func selected_full(wave: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var covered: Dictionary = {}
	for region: Rect2i in wave.powers_before:
		if region.position.y < 2 or region.size.x < 1 or region.size.y < 1: continue
		var cells: Array[Vector2i] = []
		var region_color: int = 0
		for item in wave.removed:
			var power_cell: Vector2i = Vector2i(int(item.x),int(item.y))
			if bool(item.is_power) and region.has_point(power_cell):
				cells.append(power_cell)
				region_color = int(item.color)
		if cells.size() == region.size.x*region.size.y and region_color >= 1 and region_color <= 4:
			result.append({"rect":region,"cells":cells,"color":TINTS[region_color],"kind":"power"})
			for covered_cell in cells: covered[covered_cell] = true
	for item in wave.removed:
		var cell: Vector2i = Vector2i(int(item.x),int(item.y))
		var code: int = int(item.code)
		var color_id: int = int(item.color)
		if covered.has(cell) or bool(item.is_power) or int(item.y) < 2: continue
		if color_id < 1 or color_id > 4: continue
		if (code & 7) == 5 or ((code & 15) in [6,7]): continue
		result.append({"rect":Rect2i(cell,Vector2i.ONE),"cells":[cell],"color":TINTS[color_id],"kind":"crash" if (code & 8) != 0 else "gem"})
	return result

func lookup(wave: Dictionary) -> Dictionary:
	var removed: Array = wave.removed
	var powers: Array = wave.powers_before
	for entry in cache:
		if is_same(entry.removed,removed) and is_same(entry.powers,powers): return entry
	var result: Array[Dictionary] = selected_full(wave) if full_scope else selected_prototype(wave)
	var cells: Dictionary = {}
	for group in result:
		for cell in group.cells: cells[cell] = true
	var fresh: Dictionary = {"removed":removed,"powers":powers,"result":result,"cells":cells}
	cache.append(fresh)
	if cache.size() > CACHE_LIMIT: cache.remove_at(0)
	return fresh

## Returns the cached templates: callers that keep a group must duplicate() it first.
func selected(wave: Dictionary) -> Array[Dictionary]:
	return lookup(wave).result

func handles(wave: Dictionary, cell: Vector2i) -> bool:
	return lookup(wave).cells.has(cell)

func set_quality(profile: String) -> void:
	density = float(QUALITY.get(profile,1.0))

## Called by the arena when the glass presentation is switched on for real matches.
func configure_integrated(profile: String = "high") -> void:
	full_scope = true
	set_quality(profile)
	for dimensions: Vector2i in WARM_SIZES:
		var area: int = dimensions.x*dimensions.y
		layout(dimensions,Kind.MACRO,maxi(3,roundi(area*MACRO_PER_CELL*density)))
		layout(dimensions,Kind.MICRO,mini(MAX_MICRO,roundi(area*MICRO_PER_CELL*density)))
		layout(dimensions,Kind.DUST,mini(MAX_DUST,roundi(area*DUST_PER_CELL*density)))

func observe(player: int, wave: Dictionary) -> void:
	if wave.is_empty() or str(wave.phase)!="pre": return
	for template in selected(wave):
		var source: Dictionary = template.duplicate()
		var found: bool = false
		for group in groups:
			if group.player==player and group.rect==source.rect and group.age<0:
				group.remaining=int(wave.timer)
				group.total=maxi(int(group.total),int(wave.timer))
				found=true
		if not found:
			source.merge({"player":player,"age":-1,"remaining":int(wave.timer),"total":maxi(1,int(wave.timer)),"node":null})
			groups.append(source)

func emit(player: int, wave: Dictionary) -> void:
	observe(player,wave)
	var used_macro: int = 0
	var used_micro: int = 0
	var used_dust: int = 0
	for group in groups:
		if group.player==player and group.age>=0:
			used_macro+=int(group.get("macro",0)); used_micro+=int(group.get("micro",0)); used_dust+=int(group.get("dust",0))
	for group in groups:
		if group.player!=player or group.age>=0: continue
		group.age=0
		var area: int = group.cells.size()
		group.macro=mini(MAX_MACRO-used_macro,maxi(3,roundi(area*MACRO_PER_CELL*density)))
		group.micro=mini(MAX_MICRO-used_micro,roundi(area*MICRO_PER_CELL*density))
		group.dust=mini(MAX_DUST-used_dust,roundi(area*DUST_PER_CELL*density))
		used_macro+=group.macro; used_micro+=group.micro; used_dust+=group.dust
		history.append({"player":player,"kind":str(group.get("kind","prototype")),"cells":group.cells.duplicate(),"rect":group.rect,"macro":group.macro,"micro":group.micro,"dust":group.dust,"tick":clock})

func step() -> void:
	clock+=1
	for group in groups:
		if group.age>=0: group.age+=1
	for i in range(groups.size()-1,-1,-1):
		if groups[i].age>LIFETIME:
			if is_instance_valid(groups[i].node): groups[i].node.queue_free()
			groups.remove_at(i)

func clear() -> void:
	for group in groups:
		if is_instance_valid(group.node): group.node.queue_free()
	groups.clear(); history.clear(); cache.clear(); clock=0

## Deterministic integer hash -> [0,1). No RNG object is touched.
static func unit_hash(a: int, b: int) -> float:
	var h: int = (a*73856093) ^ (b*19349663) ^ 0x5bd1e995
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16),1000003))/1000003.0

## Instance layouts are cached per (formation size, kind) and shared between batches, so a
## burst does not rebuild thousands of instances in GDScript. A smaller burst only draws a
## prefix (visible_instance_count); the R2 sequence keeps any prefix evenly spread.
## Per-event variation comes from the "salt" shader uniform.
static var layouts: Dictionary = {}

func _init() -> void:
	# Warm the layouts used by the prototype so the first burst does not hitch.
	for dimensions in [Vector2i(5,2),Vector2i.ONE]:
		var area: int = dimensions.x*dimensions.y
		layout(dimensions,Kind.MACRO,maxi(3,roundi(area*MACRO_PER_CELL*density)))
		layout(dimensions,Kind.MICRO,mini(MAX_MICRO,roundi(area*MICRO_PER_CELL*density)))
		layout(dimensions,Kind.DUST,mini(MAX_DUST,roundi(area*DUST_PER_CELL*density)))

static func layout(dimensions: Vector2i, kind: int, count: int) -> MultiMesh:
	var key: String = "%d_%d_%d" % [dimensions.x,dimensions.y,kind]
	var cached: MultiMesh = layouts.get(key) as MultiMesh
	if cached!=null and cached.instance_count>=count: return cached
	var built: MultiMesh = build_layout(dimensions,kind,count)
	layouts[key]=built
	return built

func make_batch(group: Dictionary, count: int, kind: int) -> MultiMeshInstance2D:
	var node: MultiMeshInstance2D = MultiMeshInstance2D.new()
	var mm: MultiMesh = layout(group.rect.size,kind,count)
	var salt: float = fposmod(float(int(group.rect.position.x)*31+int(group.rect.position.y)*17+int(group.player)*101)*0.6180339,1.0)
	node.multimesh=mm
	node.set_meta("instances",count)
	node.texture=ATLAS
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader=FRAGMENT
	material.set_shader_parameter("tint",group.color)
	material.set_shader_parameter("kind",kind)
	material.set_shader_parameter("salt",salt)
	material.set_shader_parameter("visible_count",count)
	node.material=material
	return node

static func build_layout(dimensions: Vector2i, kind: int, count: int) -> MultiMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size=Vector2.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_2D
	mm.use_custom_data=true
	mm.mesh=mesh
	mm.instance_count=count
	var bounds: Vector2 = Vector2(dimensions)*32.0
	var salt: int = kind*7919+dimensions.x*131+dimensions.y*17
	# Layout per instance: 8 floats (2D transform rows + padding) + 4 custom floats.
	var data: PackedFloat32Array = PackedFloat32Array()
	data.resize(count*12)
	for index in range(count):
		var seed_value: float = unit_hash(index,salt)
		var jitter_x: float = unit_hash(index,salt+1)
		var jitter_y: float = unit_hash(index,salt+2)
		# R2 low-discrepancy sequence plus jitter: even coverage of the whole surface, irregular look.
		var u: float = fposmod(0.5+float(index)*0.7548777+(jitter_x-0.5)*0.35/maxf(1.0,sqrt(float(count))),1.0)
		var v: float = fposmod(0.5+float(index)*0.5698403+(jitter_y-0.5)*0.35/maxf(1.0,sqrt(float(count))),1.0)
		var origin: Vector2 = Vector2(u*bounds.x,v*bounds.y)
		var radial: Vector2 = (origin-bounds*0.5)/(bounds*0.5)
		var angle: float = fposmod(atan2(radial.y,radial.x)/TAU,1.0) if radial.length()>0.08 else seed_value
		var length: float
		var aspect: float
		match kind:
			Kind.MACRO:
				length=2.6+seed_value*2.4      # 2.6..5.0 px
				aspect=0.45+jitter_x*0.4
			Kind.MICRO:
				length=1.0+seed_value*seed_value*1.6  # mostly ~1px, rare 2.6px
				aspect=0.55+jitter_y*0.45
			_:
				length=1.0+seed_value*0.5
				aspect=0.8+jitter_x*0.2
		var size: Vector2 = Vector2(length,length*aspect)
		var o: int = index*12
		data[o]=size.x; data[o+1]=0.0; data[o+2]=0.0; data[o+3]=origin.x
		data[o+4]=0.0; data[o+5]=size.y; data[o+6]=0.0; data[o+7]=origin.y
		data[o+8]=float(int(unit_hash(index,salt+3)*8.0)%8)+seed_value*0.999
		data[o+9]=angle; data[o+10]=size.x; data[o+11]=size.y
	if count>0: mm.buffer=data
	return mm

func formation_pixels(group: Dictionary) -> Vector2:
	return Vector2(group.rect.size)*32.0

## One crack-mask block. The approved 5x2 plate mask is cropped (never scaled) and the shader maps
## the crop back to 0..1 (uv_rect), so every block keeps 1 texel = 1 logical pixel.
func make_surface(group: Dictionary, texture: Texture2D, crop: Rect2i, origin: Vector2) -> Dictionary:
	var texture_size: Vector2 = Vector2(texture.get_size())
	var formation: Vector2 = formation_pixels(group)
	var base_scale: Vector2 = Vector2(crop.size)/texture_size
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	sprite.scale = base_scale
	sprite.position = origin
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SURFACE
	mat.set_shader_parameter("grain",GRAIN)
	mat.set_shader_parameter("tint",group.color)
	mat.set_shader_parameter("uv_rect",Vector4(float(crop.position.x)/texture_size.x,float(crop.position.y)/texture_size.y,float(crop.size.x)/texture_size.x,float(crop.size.y)/texture_size.y))
	mat.set_shader_parameter("block_frame",Vector4(origin.x/formation.x,origin.y/formation.y,float(crop.size.x)/formation.x,float(crop.size.y)/formation.y))
	mat.set_shader_parameter("formation_px",formation)
	if texture == PLATE:
		mat.set_shader_parameter("g_range",Vector2(float(crop.position.x)/159.0,float(crop.position.x+crop.size.x-1)/159.0))
	sprite.material = mat
	return {"node":sprite,"origin":origin,"scale":base_scale,"material":mat}

func build_surfaces(group: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cells: Vector2i = group.rect.size
	if cells == Vector2i.ONE:
		result.append(make_surface(group,GEM,Rect2i(0,0,32,32),Vector2.ZERO))
		return result
	# Blocks of at most 5x2 cells: 5x2 is exactly the approved plate; other sizes reuse crops of it.
	var by: int = 0
	while by < cells.y:
		var block_h: int = mini(2,cells.y-by)
		var bx: int = 0
		while bx < cells.x:
			var block_w: int = mini(5,cells.x-bx)
			var pick: int = int(unit_hash(bx*7+by*13+int(group.rect.position.x)*3,int(group.rect.position.y)*5+block_w*11+block_h*17)*1000.0)
			var crop_x: int = (pick % (5-block_w+1))*32
			var crop_y: int = ((pick >> 3) % (2-block_h+1))*32
			result.append(make_surface(group,PLATE,Rect2i(crop_x,crop_y,block_w*32,block_h*32),Vector2(bx*32,by*32)))
			bx += block_w
		by += block_h
	return result

func draw_layers(canvas: CanvasItem, origins: Array[Vector2]) -> void:
	for player in range(2):
		var clip: Control = canvas.get_node_or_null("GlassPrototype%d" % player) as Control
		if clip==null:
			clip=Control.new(); clip.name="GlassPrototype%d" % player
			clip.clip_contents=true; clip.size=Vector2(192,384); clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
			canvas.add_child(clip)
		clip.position=origins[player]
		for group in groups:
			if group.player!=player: continue
			if not is_instance_valid(group.node):
				var fresh: Node2D = Node2D.new()
				fresh.position=Vector2(group.rect.position)*32.0-Vector2(0,64)
				clip.add_child(fresh); group.node=fresh
				group["surfaces"]=build_surfaces(group)
				group["spawned"]=false
				for entry in group.surfaces: fresh.add_child(entry.node)
			var root: Node2D = group.node
			var progress: float = 1.0-float(group.remaining)/maxf(1.0,float(group.total))
			for entry in group.surfaces:
				var mat: ShaderMaterial = entry.material
				mat.set_shader_parameter("age",float(group.age))
				mat.set_shader_parameter("progress",progress)
			if group.age>=0:
				if not bool(group.get("spawned",false)):
					group["spawned"]=true
					# Draw order: dust behind, micro shards, then the few larger slivers on top.
					root.add_child(make_batch(group,group.dust,Kind.DUST))
					root.add_child(make_batch(group,group.micro,Kind.MICRO))
					root.add_child(make_batch(group,group.macro,Kind.MACRO))
				for child in root.get_children():
					if child is MultiMeshInstance2D: (child.material as ShaderMaterial).set_shader_parameter("age",float(group.age))
				var expansion: float = 1.0+float(group.age)*0.025
				var formation: Vector2 = formation_pixels(group)
				for entry in group.surfaces:
					var sprite: Sprite2D = entry.node
					sprite.scale=Vector2(entry.scale)*expansion
					sprite.position=Vector2(entry.origin)*expansion-formation*(expansion-1.0)*0.5
