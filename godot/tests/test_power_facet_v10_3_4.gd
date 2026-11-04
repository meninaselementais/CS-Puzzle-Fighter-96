extends SceneTree
## V10.3.4 — animação interna das Power Gems por célula.
## Verifica sequência A->B->C->D->C->B->A (blocos de 8 quadros), temporização,
## invariância do modelo lógico e independência P1/P2.

const MatchModel = preload("res://core/match_model.gd")
const Arena = preload("res://presentation/cs_arena.gd")

var checks: int = 0
var failures: Array[String] = []
var trace: Array[Dictionary] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func state(value: Variant) -> Variant:
	if value is RandomNumberGenerator: return [value.seed, value.state]
	if value is RefCounted:
		var result: Dictionary = {}
		var script: Script = value.get_script()
		for item in script.get_script_property_list():
			result[item.name] = state(value.get(item.name))
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

func expected_phase(age: int) -> int:
	if age < 0: return 0
	return mini(floori(float(age) / 8.0), 6)

func step(model: RefCounted, arena: RefCounted) -> void:
	model.tick()
	var before: String = var_to_str(state(model))
	arena.step_from_model(model)
	expect(var_to_str(state(model)) == before, "arena is read-only at frame %d" % model.frame)

func setup_result(model: RefCounted) -> void:
	model.motion[0].result = {"waves":[],"score":0,"attack":0,"converted":0,"gravity":0}
	model.motion[1].fall_countdown = 10000

func build_power(model: RefCounted, player: int, rect: Rect2i) -> void:
	model.boards[player].power_gems.clear()
	for idx in model.boards[player].indices(rect):
		model.boards[player].cells[idx] = 1
	model.Rules.form_powers(model.boards[player])

func build_power_rects(model: RefCounted, player: int, rects: Array) -> void:
	model.boards[player].power_gems.clear()
	for rect in rects:
		for idx in model.boards[player].indices(rect):
			model.boards[player].cells[idx] = 1
	model.Rules.form_powers(model.boards[player])

func formation_2x2() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power(model, 0, Rect2i(0, 12, 2, 2))
	setup_result(model)
	# Células do retângulo 2x2 em (0,12): (0..1, 12..13) -> índices 72,73,78,79.
	var idxs := [72, 73, 78, 79]
	arena.step_from_model(model)
	for idx in idxs:
		expect(arena.power_facet_age[0][idx] == 0, "formation cell idx %d starts at age 0" % idx)
	for age in range(1, 57):
		arena.step_from_model(model)
		var ph: int = arena.power_facet_phase(0, 72)
		expect(ph == expected_phase(age), "2x2 phase at age %d -> %d" % [age, ph])
		trace.append({"case":"formation_2x2","age":age,"phase":ph})
	expect(arena.power_facet_phase(0, 72) == 6, "2x2 settles at phase a")
	expect(arena.POWER_FACET_SEQUENCE[arena.power_facet_phase(0, 72)] == "a", "settled letter is a")
	for idx in [73, 78, 79]:
		expect(arena.power_facet_age[0][idx] == arena.power_facet_age[0][72], "2x2 cells share the same clock")

func logical_invariance() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power(model, 0, Rect2i(0, 12, 2, 2))
	setup_result(model)
	model.motion[0].phase = 3
	var cells_before: PackedInt32Array = model.boards[0].cells.duplicate()
	var powers_before: Array = model.boards[0].power_gems.duplicate()
	var score_before: int = model.scores[0]
	for frame in range(60):
		step(model, arena)
		expect(model.boards[0].cells == cells_before, "cells untouched over facet animation")
		expect(model.boards[0].power_gems == powers_before, "power_gems untouched")
		expect(model.scores[0] == score_before, "score untouched")
	expect(arena.power_facet_phase(0, 72) == 6, "invariance run settles to phase a")

func p1_p2_independence() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power(model, 0, Rect2i(0, 12, 2, 2))
	setup_result(model)
	arena.step_from_model(model)
	build_power(model, 1, Rect2i(3, 11, 2, 2))
	arena.step_from_model(model)
	expect(arena.power_facet_age[0][72] == 1, "P1 advanced once")
	expect(arena.power_facet_age[1][69] == 0, "P2 started later")
	for age in range(2, 20):
		arena.step_from_model(model)
		expect(arena.power_facet_age[0][72] == age, "P1 keeps advancing")
		expect(arena.power_facet_age[1][69] == age - 1, "P2 clock is independent")
		trace.append({"case":"p1_p2","age":age,"p1":arena.power_facet_age[0][72],"p2":arena.power_facet_age[1][69]})

func growth_2x3() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power(model, 0, Rect2i(0, 12, 2, 2))
	setup_result(model)
	model.motion[0].phase = 3
	for _f in range(49):
		arena.step_from_model(model)
	expect(arena.power_facet_phase(0, 72) == 6, "existing 2x2 settled before growth")
	model.boards[0].cells[11 * 6 + 0] = 1
	model.boards[0].cells[11 * 6 + 1] = 1
	model.Rules.form_powers(model.boards[0])
	arena.step_from_model(model)
	expect(arena.power_facet_age[0][66] == 0, "new top cell restarts at age 0")
	expect(arena.power_facet_age[0][67] == 0, "new top-right cell restarts at age 0")
	expect(arena.power_facet_age[0][72] == 0, "MAME growth: existing cell restarts with changed region")
	expect(arena.power_facet_age[0][78] == 0, "MAME growth: bottom cell restarts with changed dimensions")
	trace.append({"case":"growth_2x3","top_age":arena.power_facet_age[0][66],"old_age":arena.power_facet_age[0][72]})

func union_5x2() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power_rects(model, 0, [Rect2i(0, 12, 2, 2), Rect2i(3, 12, 2, 2)])
	setup_result(model)
	model.motion[0].phase = 3
	for _f in range(49):
		arena.step_from_model(model)
	expect(arena.power_facet_phase(0, 72) == 6, "left 2x2 settled before union")
	expect(arena.power_facet_phase(0, 75) == 6, "right 2x2 settled before union")
	# Adiciona a ponte: células (2,12) e (2,13) -> índices 74 e 80.
	model.boards[0].cells[74] = 1
	model.boards[0].cells[80] = 1
	model.Rules.form_powers(model.boards[0])
	arena.step_from_model(model)
	expect(arena.power_facet_age[0][74] == 0, "MAME intermediate bridge starts at A")
	expect(arena.power_facet_age[0][80] == 0, "MAME intermediate bottom bridge starts at A")
	expect(arena.power_facet_age[0][72] == 0, "MAME final merge restarts left region")
	expect(arena.power_facet_age[0][75] == 48, "intermediate merge preserves untouched right region")
	# O retângulo lógico é um único 5x2; as células da ponte avançam em sincronia com o relógio compartilhado.
	for age in range(1, 10):
		arena.step_from_model(model)
		expect(arena.power_facet_age[0][74] == age, "intermediate bridge advances from A")
		expect(arena.power_facet_age[0][80] == age, "intermediate bridge cells share clock")
	arena.step_from_model(model)
	for idx in [72, 73, 74, 75, 76, 78, 79, 80, 81, 82]:
		expect(arena.power_facet_age[0][idx] == 0, "MAME final 5x2 resets changed cell %d" % idx)
	trace.append({"case":"union_5x2","bridge_age":arena.power_facet_age[0][74],"left_age":arena.power_facet_age[0][72]})

func union_visual_intermediate() -> void:
	# Exercita o caminho temporal (union_view 3x2+2x2 por dez quadros) e confere
	# que a ponte anima enquanto a geometria lógica final é 5x2.
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power_rects(model, 0, [Rect2i(0, 12, 2, 2), Rect2i(3, 12, 2, 2)])
	model.frame = 1
	setup_result(model)
	arena.step_from_model(model)
	# Estabiliza as duas 2x2 antes da ponte (sem tick, apenas avanço visual).
	for _f in range(49):
		arena.step_from_model(model)
	expect(arena.power_facet_phase(0, 72) == 6, "intermediate: left settled")
	model.boards[0].cells[74] = 1
	model.boards[0].cells[80] = 1
	model.motion[0].phase = 3
	step(model, arena)
	step(model, arena)
	expect(model.boards[0].power_gems == [Rect2i(0, 12, 5, 2)], "logical 5x2 formed")
	expect(arena.power_facet_age[0][74] >= 0, "bridge animates in visual intermediate")
	expect(arena.power_facet_age[0][72] == 0, "MAME intermediate merge restarts changed left region")

func lifecycle() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	build_power(model, 0, Rect2i(0, 12, 2, 2))
	build_power(model, 0, Rect2i(3, 12, 2, 2))
	arena.step_from_model(model)
	for _frame in range(20): arena.step_from_model(model)
	model.boards[0].cells[66] = 1
	model.boards[0].cells[67] = 1
	model.Rules.form_powers(model.boards[0])
	arena.step_from_model(model)
	expect(arena.power_facet_age[0][66] == 0, "changed region starts")
	expect(arena.power_facet_age[0][75] == 21, "unrelated region does not restart")
	model.boards[0].power_gems.clear()
	arena.step_from_model(model)
	expect(arena.power_facet_age[0][66] == -1, "removed region clears age")
	arena.reset_state()
	expect(arena.power_facet_age[0][75] == -1, "restart clears ages")
	expect(arena.prev_power_facet_regions == [{}, {}], "restart clears region identity")

func _initialize() -> void:
	lifecycle()
	formation_2x2()
	logical_invariance()
	p1_p2_independence()
	growth_2x3()
	union_5x2()
	union_visual_intermediate()
	var output: String = OS.get_environment("PF_REPORT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		var file: FileAccess = FileAccess.open(output.path_join("power_facet_v10_3_4.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"trace":trace},"  "))
	print("POWER_FACET_V10_3_4 ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
