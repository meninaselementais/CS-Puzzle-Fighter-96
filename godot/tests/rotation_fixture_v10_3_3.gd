extends RefCounted
const MatchModel = preload("res://core/match_model.gd")
const PairModel = preload("res://core/pair_model.gd")

static func prepare(item: Dictionary, primary: bool) -> RefCounted:
	var model: RefCounted = MatchModel.new()
	model.motion[1].fall_countdown = 10000
	if primary:
		var first: Dictionary = item.samples[0]
		model.pairs[0] = PairModel.new(Vector2i(first.x,first.y),1,2)
		model.pairs[0].rotation = int(first.rotation)
		model.motion[0].fall_countdown = 100
		model.pair_age[0] = 32
		if str(item.id).begins_with("corridor_"):
			for y in range(4,14):
				model.boards[0].cells[y*6+1] = 3
				model.boards[0].cells[y*6+3] = 4
	else:
		var initial: Dictionary = item.initial
		model.boards[0].load_cells(PackedInt32Array(initial.cells))
		model.pairs[0] = PairModel.new(Vector2i(initial.x,initial.y),int(initial.colors[0]),int(initial.colors[1]))
		model.pairs[0].rotation = int(initial.rotation)
		for key in initial.clock: model.motion[0].set(key,initial.clock[key])
		model.stream = [initial.colors.duplicate(),initial.next_colors.duplicate()]
		model.pair_age[0] = int(initial.pair_age)
		model.scores[0] = int(initial.score)
		model.turn_number[0] = int(initial.turn)
		model.global_seed = int(initial.global_seed)
	while model.stream.size() < 8: model.stream.append([2,4])
	return model

static func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed,value.state]
	if value is RefCounted:
		var result: Dictionary = {}
		for item in value.get_script().get_script_property_list(): result[item.name] = state(value.get(item.name))
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
