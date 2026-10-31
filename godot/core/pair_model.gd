extends RefCounted

const OFFSETS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
var pivot := Vector2i(3, 1)
var rotation: int = 0
var colors := PackedInt32Array([2, 4])

func _init(position := Vector2i(3, 1), first: int = 2, second: int = 4) -> void:
	pivot = position
	colors = PackedInt32Array([first, second])

func positions() -> Array[Vector2i]:
	return [pivot, pivot + OFFSETS[posmod(rotation, 4)]]

func copy() -> RefCounted:
	var result = get_script().new(pivot, colors[0], colors[1])
	result.rotation = rotation
	return result
