extends RefCounted
## Numeric observations from MAME 0.289; tables $12DA0/$12D00, timer 7..0.
## Owns presentation state only. Snapshots contain values, never a model reference.
const Gem = preload("res://core/gem_rules.gd")
const OFFSETS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CW: Array = [
	[Vector2i(-14, 12), Vector2i(-12, 8), Vector2i(-10, 6), Vector2i(-8, 4), Vector2i(-6, 3), Vector2i(-4, 2), Vector2i(-2, 1), Vector2i(0, 0)],
	[Vector2i(-14, -15), Vector2i(-12, -14), Vector2i(-10, -13), Vector2i(-8, -12), Vector2i(-6, -10), Vector2i(-4, -8), Vector2i(-2, -4), Vector2i(0, 0)],
	[Vector2i(15, -14), Vector2i(14, -12), Vector2i(13, -10), Vector2i(12, -8), Vector2i(10, -6), Vector2i(8, -4), Vector2i(4, -2), Vector2i(0, 0)],
	[Vector2i(14, 15), Vector2i(12, 14), Vector2i(10, 13), Vector2i(8, 12), Vector2i(6, 10), Vector2i(4, 8), Vector2i(2, 4), Vector2i(0, 0)]
]
const CCW: Array = [
	[Vector2i(14, 12), Vector2i(12, 8), Vector2i(10, 6), Vector2i(8, 4), Vector2i(6, 3), Vector2i(4, 2), Vector2i(2, 1), Vector2i(0, 0)],
	[Vector2i(-12, 14), Vector2i(-8, 12), Vector2i(-6, 10), Vector2i(-4, 8), Vector2i(-3, 6), Vector2i(-2, 4), Vector2i(-1, 2), Vector2i(0, 0)],
	[Vector2i(-14, -12), Vector2i(-12, -8), Vector2i(-10, -6), Vector2i(-8, -4), Vector2i(-6, -3), Vector2i(-4, -2), Vector2i(-2, -1), Vector2i(0, 0)],
	[Vector2i(12, -14), Vector2i(8, -12), Vector2i(6, -10), Vector2i(4, -8), Vector2i(3, -6), Vector2i(2, -4), Vector2i(1, -2), Vector2i(0, 0)],
	[Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)]
]
var timer: int = 0
var mode: int = 0
var native_offset: Vector2i = Vector2i.ZERO
var last_frame: int = -1
var identity: String = ""

static func identity_of(model: RefCounted, player: int) -> String:
	return "%d:%d:%d" % [model.pair_index[player],model.turn_number[player],model.motion[player].get_instance_id()]

static func snapshot(model: RefCounted, player: int) -> Dictionary:
	var clock: RefCounted = model.motion[player]
	var pair: RefCounted = model.pairs[player]
	return {"frame":model.frame, "identity":identity_of(model,player),
		"phase":clock.phase, "contact":clock.contact, "disabled":clock.rotation_disabled,
		"upkicks":clock.upkicks, "previous_input":clock.previous_input, "input":model.input_masks[player],
		"pivot":pair.pivot, "rotation":pair.rotation, "colors":pair.colors.duplicate(),
		"cells":model.boards[player].cells.duplicate(), "lost":model.lost[player], "winner":model.winner}

func reset() -> void:
	timer = 0
	mode = 0
	native_offset = Vector2i.ZERO
	last_frame = -1
	identity = ""

static func occupied(cells: PackedInt32Array, point: Vector2i) -> bool:
	return point.x < 0 or point.x >= 6 or point.y < 0 or point.y >= 14 or cells[point.y*6+point.x] != 0

static func corridor(cells: PackedInt32Array, point: Vector2i, orientation: int) -> bool:
	return orientation in [0,2] and occupied(cells,point+Vector2i.LEFT) and occupied(cells,point+Vector2i.RIGHT)

static func attempt(cells: PackedInt32Array, point: Vector2i, orientation: int, direction: int) -> Dictionary:
	# Read-only classification of the native graphical branch; never supplies geometry to the model.
	var destination: int = posmod(orientation+direction,4)
	var candidate: Vector2i = point
	if occupied(cells,candidate+OFFSETS[destination]):
		if destination in [1,3]: candidate.x += -1 if destination == 1 else 1
		elif destination == 2: candidate.y -= 1
		else: return {"mode":2,"point":point,"rotation":orientation,"up":false}
		if occupied(cells,candidate) or occupied(cells,candidate+OFFSETS[destination]):
			return {"mode":2,"point":point,"rotation":orientation,"up":false}
	return {"mode":0 if direction == 1 else 1,"point":candidate,"rotation":destination,"up":candidate.y < point.y}

func step(before: Dictionary, after: Dictionary) -> void:
	if int(after.frame) == last_frame and str(after.identity) == identity: return
	if int(before.frame) != last_frame or str(before.identity) != identity: reset()
	last_frame = int(after.frame)
	identity = str(after.identity)
	if int(after.frame) != int(before.frame)+1 or str(before.identity) != identity or int(before.phase) != 0 or int(after.phase) != 0 or bool(before.lost) or bool(after.lost) or int(before.winner) != -2:
		timer = 0
		native_offset = Vector2i.ZERO
		return
	var edges: int = int(before.input) & ~int(before.previous_input) & 768
	var third_kick: bool = not bool(before.disabled) and bool(after.disabled)
	if edges != 0 and not bool(before.disabled) and (int(after.contact) not in [1,16] or third_kick):
		# Gravity precedes input; horizontal movement follows it. An upkick is the only input changing Y.
		var point: Vector2i = Vector2i(before.pivot.x,after.pivot.y + (1 if int(after.upkicks) > int(before.upkicks) else 0))
		var orientation: int = int(before.rotation)
		var kicks: int = int(before.upkicks)
		if corridor(before.cells,point,orientation):
			mode = 2
		else:
			for entry in [[512,1],[256,-1]]:
				if edges & int(entry[0]):
					var event: Dictionary = attempt(before.cells,point,orientation,int(entry[1]))
					mode = int(event.mode)
					point = event.point
					orientation = int(event.rotation)
					if bool(event.up):
						kicks += 1
						if kicks > 2: break
		timer = 8
	if timer > 0:
		timer -= 1
		var group: int = 4 if mode == 2 else int(after.rotation)
		native_offset = CCW[group][7-timer] if mode != 0 else CW[group][7-timer]

func points(pair: RefCounted, clock: RefCounted, pair_identity: String) -> Array[Vector2]:
	var logical: Array = pair.positions()
	var displacement: Vector2 = Vector2(native_offset)/16.0 if identity == pair_identity else Vector2.ZERO
	var fall: Vector2 = Vector2(0,float(clock.offset)/16.0)
	return [Vector2(logical[0])+fall,Vector2(logical[1])+fall+displacement]

func draw_pair(canvas: Node2D, arena: RefCounted, pair: RefCounted, clock: RefCounted, pair_identity: String, origin: Vector2, lost: bool) -> void:
	if lost or clock.phase != 0: return
	var positions: Array[Vector2] = points(pair,clock,pair_identity)
	for index in range(2):
		var point: Vector2 = positions[index]
		# Apply native displacement before the existing visible-row/column test.
		if point.y < 2.0 or point.y >= 14.0 or point.x < 0.0 or point.x >= 6.0: continue
		var center: Vector2 = origin + Vector2(point.x*32.0+16.0,(point.y-2.0)*32.0+16.0)
		arena.draw_gem_sprite(canvas,center,int(pair.colors[index]),Gem,90+index,Vector2.ONE)
