extends RefCounted

const Pair = preload("res://core/pair_model.gd")
const Gem = preload("res://core/gem_rules.gd")
const COLUMNS: int = 6
const ROWS: int = 14
const HIDDEN_ROWS: int = 2
var cells := PackedInt32Array()
var power_gems: Array[Rect2i] = []

func _init() -> void:
	cells.resize(COLUMNS * ROWS)
	cells.fill(0)

func load_cells(values: PackedInt32Array) -> bool:
	if values.size() != COLUMNS * ROWS:
		return false
	for value in values:
		if value < 0 or value > 65535:
			return false
	cells = values.duplicate()
	for i in range(cells.size()):
		cells[i] = Gem.canonical(cells[i])
	power_gems.clear()
	# Importa retângulos já consolidados; as regras preservam essa identidade nas quedas.
	var visited := {}
	for i in range(cells.size()):
		if visited.has(i) or Gem.kind(cells[i]) != Gem.Kind.POWER:
			continue
		var members: Array[int] = [i]
		visited[i] = true
		var k := 0
		var left: int = i % COLUMNS
		var right: int = left
		var top: int = i / COLUMNS
		var bottom: int = top
		while k < members.size():
			var current: int = members[k]
			var point := Vector2i(current % COLUMNS, current / COLUMNS)
			left = mini(left, point.x)
			right = maxi(right, point.x)
			top = mini(top, point.y)
			bottom = maxi(bottom, point.y)
			for next in neighbors(current):
				if not visited.has(next) and Gem.kind(cells[next]) == Gem.Kind.POWER and Gem.color(cells[next]) == Gem.color(cells[i]):
					visited[next] = true
					members.append(next)
			k += 1
		var bounds := Rect2i(left, top, right - left + 1, bottom - top + 1)
		if bounds.size.x >= 2 and bounds.size.y >= 2 and bounds.get_area() == members.size():
			power_gems.append(bounds)
	return true

func neighbors(index: int) -> Array[int]:
	var result: Array[int] = []
	var x := index % COLUMNS
	var y := index / COLUMNS
	if x > 0: result.append(index - 1)
	if x < COLUMNS - 1: result.append(index + 1)
	if y > 0: result.append(index - COLUMNS)
	if y < ROWS - 1: result.append(index + COLUMNS)
	return result

func indices(rect: Rect2i) -> Array[int]:
	var result: Array[int] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			result.append(y * COLUMNS + x)
	return result

func can_place(pair: Pair) -> bool:
	for point in pair.positions():
		if point.x < 0 or point.x >= COLUMNS or point.y < 0 or point.y >= ROWS:
			return false
		if cells[point.y * COLUMNS + point.x] != 0:
			return false
	return true

func commit(pair: Pair) -> bool:
	if not can_place(pair):
		return false
	var points = pair.positions()
	for i in range(2):
		cells[points[i].y * COLUMNS + points[i].x] = pair.colors[i]
	return true
