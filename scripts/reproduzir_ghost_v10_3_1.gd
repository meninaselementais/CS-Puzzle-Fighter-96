extends SceneTree
## Diagnóstico externo; não modifica arquivos nem regras do jogo.
const MatchModel = preload("res://core/match_model.gd")
const Arena = preload("res://presentation/cs_arena.gd")

func _initialize() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	model.boards[0].cells.fill(0)
	for x in range(1, 4):
		model.boards[0].cells[78 + x] = 2
	model.boards[0].cells[78] = 10
	model.motion[0].phase = 3
	model.motion[0].result = {"waves": [], "score": 0, "attack": 0, "converted": 0, "gravity": 0}
	var path: String = OS.get_cmdline_user_args()[0]
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	output.store_line("frame,phase,clear_timer,wave_phase,wave_timer,override,logical,visual,hidden")
	var vanished: bool = false
	var resurrected: Array[int] = []
	for frame in range(1, 100):
		model.motion[0].resolve_frame(model, 0)
		arena.step_from_model(model)
		var logical: int = model.boards[0].cells[79]
		var visual: int = arena.get_visual_cells(0, model.boards[0].cells)[79]
		if visual == 0: vanished = true
		if vanished and visual != 0 and logical != 0:
			resurrected.append(frame)
		output.store_line("%d,%d,%d,%s,%d,%s,%d,%d,%s" % [frame, model.motion[0].phase, model.motion[0].clear_timer, arena.active_wave[0].get("phase", "none"), arena.active_wave[0].get("timer", 0), arena.has_visual_override(0), logical, visual, arena.is_cell_hidden_by_flash(0, 79)])
	output.close()
	assert(not resurrected.is_empty(), "O cenário deve reproduzir a reaparição antes da remoção lógica")
	print("GHOST_REPRODUCED frames=", resurrected)
	quit()
