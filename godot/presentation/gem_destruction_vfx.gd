extends RefCounted
## Deterministic, read-only decoration of the currently observed resolution wave.
## Layers are clipped to each well; additive light never covers NEXT or the HUD.
const PALETTE: Array[Color] = [Color.WHITE,Color("58baff"),Color("ffe05c"),Color("5cf59c"),Color("ff5478"),Color("ff9c48")]
var prototype: RefCounted = null

func handles(wave: Dictionary, cell: Vector2i) -> bool:
	return prototype != null and prototype.handles(wave,cell)

const MAX_BURSTS: int = 192
const MAX_MOTES: int = 320
var bursts: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var anticipation: Array[Dictionary] = [{},{}]
var emitted: Array[int] = [0,0]
var burst_counts: Array[int] = [0,0]
var mote_counts: Array[int] = [0,0]

class GlowLayer extends Node2D:
	var effects: RefCounted
	var player: int = 0
	func _draw() -> void:
		if effects != null: effects.draw_glow(self,player)

func clear() -> void:
	if prototype != null: prototype.clear()
	bursts.clear()
	motes.clear()
	anticipation = [{},{}]
	emitted = [0,0]
	burst_counts = [0,0]
	mote_counts = [0,0]

func step() -> void:
	if prototype != null: prototype.step()
	for burst in bursts: burst.age = int(burst.age)+1
	bursts = bursts.filter(func(b: Dictionary) -> bool: return int(b.age) < int(b.ttl)+int(b.delay))
	for mote in motes:
		mote.age = int(mote.age)+1
		if int(mote.age) < int(mote.delay): continue
		mote.pos += mote.velocity
		mote.velocity = Vector2(mote.velocity)*0.93+Vector2(0,0.07)
	motes = motes.filter(func(m: Dictionary) -> bool: return int(m.age) < int(m.ttl)+int(m.delay))
	burst_counts = [0,0]
	mote_counts = [0,0]
	for burst in bursts: burst_counts[int(burst.player)] += 1
	for mote in motes: mote_counts[int(mote.player)] += 1

func observe_pre(player: int, origin: Vector2, wave: Dictionary) -> void:
	if prototype != null: prototype.observe(player,wave)
	if wave.is_empty() or str(wave.phase) != "pre":
		anticipation[player] = {}
		return
	var old: Dictionary = anticipation[player]
	var total: int = maxi(int(wave.timer),int(old.get("total",0)))
	# V11.4.2: Crash Gems taken over by the glass keep their pulsing ring/star cue (cues is empty when glass is off).
	var cues: Array = wave.removed.filter(func(item: Dictionary) -> bool: return (int(item.code) & 8) != 0 and (int(item.code) & 7) != 5 and (int(item.code) & 128) == 0 and handles(wave,Vector2i(item.x,item.y)))
	anticipation[player] = {"origin":origin,"removed":wave.removed.filter(func(item: Dictionary) -> bool: return not handles(wave,Vector2i(item.x,item.y))),"cues":cues,"remaining":int(wave.timer),"total":maxi(1,total)}

func add_mote(player: int, pos: Vector2, velocity: Vector2, tint: Color, seed_value: int, delay: int = 0) -> void:
	if mote_counts[player] >= int(MAX_MOTES/2.0): return
	mote_counts[player] += 1
	motes.append({"player":player,"pos":pos,"velocity":velocity,"color":tint,"age":0,"ttl":18+posmod(seed_value,10),"delay":delay,"seed":seed_value})

func add_burst(player: int, pos: Vector2, extent: Vector2, tint: Color, kind: String, strength: int, delay: int = 0) -> void:
	if burst_counts[player] >= int(MAX_BURSTS/2.0): return
	burst_counts[player] += 1
	bursts.append({"player":player,"pos":pos,"extent":extent,"color":tint,"kind":kind,"strength":strength,"age":0,"delay":delay,"ttl":22 if kind=="c4" else (18 if kind=="power" else 12)})

func emit_wave(player: int, wave: Dictionary) -> void:
	emitted[player] += 1
	if prototype != null: prototype.emit(player,wave)
	var removed: Array = wave.removed.filter(func(item: Dictionary) -> bool: return not handles(wave,Vector2i(item.x,item.y)))
	var chain: int = int(wave.chain)
	# With the full-scope glass the strength still follows every destroyed gem, so the remaining V11.4 effects (C4) keep their look.
	var strength_cells: int = removed.size()
	if prototype != null and bool(prototype.get("full_scope")): strength_cells = wave.removed.size()
	var strength: int = clampi(1+int(strength_cells/8.0)+int((chain-1)/2.0),1,3)
	var regions: Dictionary = {}
	for item in removed:
		var cell: Vector2i = Vector2i(int(item.x),int(item.y))
		if cell.y < 2: continue
		var pos: Vector2 = Vector2(cell)*32+Vector2(16,-48)
		var code: int = int(item.code)
		var c4: bool = (code & 7)==5
		var tint: Color = PALETTE[5 if c4 else clampi(int(item.color),1,4)]
		var cell_seed: int = cell.y*6+cell.x+chain*17
		var delay: int = posmod(cell.x+cell.y,3) if strength>=2 else 0
		add_burst(player,pos,Vector2(22,22),tint,"cell",strength,delay)
		for particle in range(1+strength):
			var angle: float = float(posmod(cell_seed*37+particle*97,360))*PI/180.0
			var velocity: Vector2 = Vector2(cos(angle),sin(angle))*float(2+particle)+Vector2(0,-1)
			add_mote(player,pos,velocity,tint,cell_seed+particle,delay+2)
		if c4:
			add_burst(player,pos,Vector2(72,72),PALETTE[5],"c4",3)
			for ray in range(16):
				var angle: float = float(ray)*TAU/16.0
				add_mote(player,pos,Vector2(cos(angle),sin(angle))*5,PALETTE[5],ray,4+ray%3)
		if bool(item.is_power):
			for region in wave.powers_before:
				if region.has_point(cell): regions[region] = tint; break
	for region: Rect2i in regions:
		var bounds: Rect2 = Rect2(Vector2(region.position)*32+Vector2(0,-64),Vector2(region.size)*32)
		var center: Vector2 = bounds.get_center()
		var tint: Color = regions[region]
		add_burst(player,center,bounds.size*0.55,tint,"power",strength)
		# Edge sparks scale with perimeter; glass debris already scales per removed cell.
		var edge_count: int = 2*(region.size.x+region.size.y)
		for edge in range(edge_count):
			var distance: float = float(edge)/float(edge_count)*2.0*(bounds.size.x+bounds.size.y)
			var pos: Vector2
			if distance < bounds.size.x: pos = bounds.position+Vector2(distance,0)
			elif distance < bounds.size.x+bounds.size.y: pos = bounds.position+Vector2(bounds.size.x,distance-bounds.size.x)
			elif distance < 2*bounds.size.x+bounds.size.y: pos = bounds.end-Vector2(distance-bounds.size.x-bounds.size.y,0)
			else: pos = bounds.position+Vector2(0,2*(bounds.size.x+bounds.size.y)-distance)
			add_mote(player,pos,(pos-center).normalized()*3.0,tint,edge+region.get_area(),2+edge%3)
	anticipation[player] = {}

func ensure_layers(canvas: CanvasItem, origins: Array[Vector2]) -> void:
	if prototype != null: prototype.draw_layers(canvas,origins)
	for player in range(2):
		var key: String = "DestructionLight%d" % player
		var clip: Control = canvas.get_node_or_null(key) as Control
		if clip == null:
			clip = Control.new()
			clip.name = key
			clip.clip_contents = true
			clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			clip.size = Vector2(192,384)
			canvas.add_child(clip)
			var layer: Node2D = GlowLayer.new()
			layer.name = "Light"
			var additive: CanvasItemMaterial = CanvasItemMaterial.new()
			additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			layer.material = additive
			clip.add_child(layer)
		clip.position = origins[player]
		var light: GlowLayer = clip.get_node("Light") as GlowLayer
		light.effects = self
		light.player = player
		light.queue_redraw()

func star(canvas: CanvasItem, pos: Vector2, radius: float, tint: Color, alpha: float) -> void:
	canvas.draw_rect(Rect2(pos-Vector2(radius,1),Vector2(radius*2,2)),Color(tint,alpha))
	canvas.draw_rect(Rect2(pos-Vector2(1,radius),Vector2(2,radius*2)),Color(tint,alpha))

func ring(canvas: CanvasItem, center: Vector2, extent: Vector2, tint: Color, alpha: float, segments: int = 12) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for corner in range(segments+1):
		var angle: float = float(corner)*TAU/float(segments)
		points.append((center+Vector2(cos(angle)*extent.x,sin(angle)*extent.y)).round())
	canvas.draw_polyline(points,Color(tint,alpha),2.0,false)

func draw_glow(canvas: CanvasItem, player: int) -> void:
	var pre: Dictionary = anticipation[player]
	if not pre.is_empty():
		var progress: float = floorf((1.0-float(pre.remaining)/float(pre.total))*6.0)/6.0
		for item in pre.removed:
			if int(item.y)<2: continue
			var pos: Vector2 = Vector2(int(item.x)*32+16,(int(item.y)-2)*32+16)
			var code: int = int(item.code)
			var tint: Color = PALETTE[clampi(int(item.color),1,4)]
			var energy: float = 0.08+progress*0.28
			canvas.draw_colored_polygon(PackedVector2Array([pos+Vector2(-10,0),pos+Vector2(0,-10),pos+Vector2(10,0),pos+Vector2(0,10)]),Color(tint,energy))
			star(canvas,pos,3+progress*5,Color.WHITE,energy)
			if (code & 8)!=0 and (code & 7)!=5:
				var pulse: float = 0.35+0.35*float(posmod(int(pre.remaining),3)==0)
				ring(canvas,pos,Vector2.ONE*(8+progress*8),tint,pulse)
				star(canvas,pos,4+progress*3,tint,0.5)
			elif (code & 7)==5:
				var period: int = 6 if progress<0.33 else (4 if progress<0.66 else 2)
				var on: bool = posmod(int(pre.total)-int(pre.remaining),period)<maxi(1,int(period/2.0))
				var led: Vector2 = pos+Vector2(7,-7)
				star(canvas,led,5 if on else 2,Color("ff4038"),0.9 if on else 0.25)
				canvas.draw_rect(Rect2(led-Vector2.ONE,Vector2(2,2)),Color(1,0.85,0.7,0.9 if on else 0.3))
	if not pre.is_empty():
		for item in pre.get("cues",[]):
			if int(item.y)<2: continue
			var cue_pos: Vector2 = Vector2(int(item.x)*32+16,(int(item.y)-2)*32+16)
			var cue_tint: Color = PALETTE[clampi(int(item.color),1,4)]
			var cue_progress: float = floorf((1.0-float(pre.remaining)/float(pre.total))*6.0)/6.0
			var cue_pulse: float = 0.35+0.35*float(posmod(int(pre.remaining),3)==0)
			ring(canvas,cue_pos,Vector2.ONE*(8+cue_progress*8),cue_tint,cue_pulse)
			star(canvas,cue_pos,4+cue_progress*3,cue_tint,0.5)
	for burst in bursts:
		if int(burst.player)!=player: continue
		var age: int = int(burst.age)-int(burst.delay)
		if age<0: continue
		var pos: Vector2 = burst.pos
		var tint: Color = burst.color
		var kind: String = str(burst.kind)
		var phase: float = floorf(float(age)/2.0)*2.0/float(burst.ttl)
		var fade: float = maxf(0,1.0-phase)
		var extent: Vector2 = burst.extent
		if age<2:
			star(canvas,pos,12 if kind=="cell" else 22,tint,0.55)
			canvas.draw_colored_polygon(PackedVector2Array([pos+Vector2(-8,0),pos+Vector2(0,-8),pos+Vector2(8,0),pos+Vector2(0,8)]),Color(1,0.95,0.82,0.7))
		if kind=="cell":
			if int(burst.strength)>=2: ring(canvas,pos,extent*(0.35+phase),tint,0.28*fade,8)
			continue
		if age>=2:
			ring(canvas,pos,extent*(0.35+phase*0.9),tint,0.7*fade,16 if kind=="c4" else 8)
			if int(burst.strength)>=2 or kind=="c4": ring(canvas,pos,extent*(0.20+phase*0.65),tint.lightened(0.5),0.3*fade,8)
			if kind=="power" and extent.x>extent.y*1.6:
				star(canvas,pos,extent.x*(0.3+phase*0.5),tint,0.23*fade)
	for mote in motes:
		if int(mote.player)!=player: continue
		var age: int = int(mote.age)-int(mote.delay)
		if age<0: continue
		var fade: float = 1.0-float(age)/float(mote.ttl)
		if age>int(mote.ttl)-6 and posmod(age+int(mote.seed),2)==0: continue
		var pos: Vector2 = Vector2(mote.pos).round()
		var tint: Color = mote.color
		var tail: Vector2 = Vector2(mote.velocity).normalized()*(3 if age<8 else 1)
		canvas.draw_line(pos-tail,pos,Color(tint,0.4*fade),1.0,false)
		star(canvas,pos,2 if posmod(int(mote.seed),3)==0 else 1,tint,0.7*fade)
		canvas.draw_rect(Rect2(pos,Vector2.ONE),Color(1,1,0.95,fade))
