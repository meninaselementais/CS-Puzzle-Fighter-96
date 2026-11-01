extends SceneTree

const Match = preload("res://core/match_model.gd")
const Pair = preload("res://core/pair_model.gd")
const Gem = preload("res://core/gem_rules.gd")

var checks: int = 0
var check_failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		check_failures.append(label)
		push_error(label)

func configure_player(model: RefCounted, player: int, init: Dictionary) -> void:
	var cells: PackedInt32Array = PackedInt32Array()
	for code in str(init.grid).split(":"):
		cells.append(Gem.canonical(str(code).hex_to_int()))
	assert(model.boards[player].load_cells(cells))
	model.pairs[player] = Pair.new(Vector2i(int(init.x), int(init.y) - 1), int(init.pivot), int(init.satellite))
	model.pairs[player].rotation = int(init.rotation)
	model.scores[player] = int(init.score)
	model.turn_number[player] = int(init.turn)
	model.pair_age[player] = int(init.pair_age)
	model.character_ids[player] = int(init.char_id)
	var clock: RefCounted = model.motion[player]
	clock.phase = int(init.phase)
	clock.contact = int(init.contact)
	clock.offset = int(init.offset)
	clock.fall_countdown = int(init.fall_countdown)
	clock.fall_interval = int(init.fall_interval)
	clock.fall_increment = int(init.fall_increment)
	clock.fall_offset = int(init.fall_offset)
	clock.fall_start = bool(init.fall_start)
	clock.contacts = int(init.contact_count)
	clock.upkicks = int(init.upkicks)
	clock.rotation_disabled = bool(init.rotation_disabled)
	clock.down_counter = int(init.down_counter)
	clock.down_timer = int(init.down_timer)
	clock.horizontal_timer = int(init.horizontal_timer)
	clock.previous_input = int(init.previous_input)

func verify_explicit_categories(cases_by_id: Dictionary) -> void:
	# 1. Destruição simples: gemas permanecem no tabuleiro durante os 39 primeiros quadros da fase 11 e só são removidas no 40º quadro.
	var c_red4: Dictionary = cases_by_id["crash_red4"]
	expect(int(c_red4.samples[108].score1) == 10, "simple_destruction: score antes do 40o quadro da fase 11 (f=109)")
	expect(int(c_red4.samples[109].score1) == 650, "simple_destruction: score no 40o quadro da fase 11 (f=110)")

	# 2 & 3. Combos de 2+ ondas e queda intermediária entre cadeias:
	# Em chain_3_larger, Onda 1 termina em f=88, a gema azul cai 2 linhas em f=89..90 (1 linha por quadro na fase 3),
	# Onda 2 termina em f=153 e Onda 3 termina em f=211.
	var model: RefCounted = Match.new()
	var item: Dictionary = cases_by_id["chain_3_larger"]
	configure_player(model, 0, item.p1_init)
	configure_player(model, 1, item.p2_init)
	var turn0: int = int(item.p1_init.turn)
	var p1_down: bool = true
	var blue_rows_between_waves: Array[int] = []
	var waves_seen_at_f100: int = -1
	for sample in item.samples:
		var fn: int = int(sample.frame)
		model.input_masks[0] = 4 if (p1_down and fn >= 2) else 0
		model.input_masks[1] = 0
		model.locked_residual[0] = int(sample.perm1)
		model.locked_residual[1] = int(sample.perm2)
		model.tick()
		if model.turn_number[0] != turn0:
			p1_down = false
		if fn in [88, 89, 90]:
			var lowest_empty_or_blue: int = -1
			if model.boards[0].cells[11 * 6 + 4] == 1 and model.boards[0].cells[12 * 6 + 4] == 1 and model.boards[0].cells[13 * 6 + 4] == 0:
				lowest_empty_or_blue = 11
			elif model.boards[0].cells[11 * 6 + 4] == 1 and model.boards[0].cells[12 * 6 + 4] == 0 and model.boards[0].cells[13 * 6 + 4] == 1:
				lowest_empty_or_blue = 12
			elif model.boards[0].cells[11 * 6 + 4] == 0 and model.boards[0].cells[12 * 6 + 4] == 1 and model.boards[0].cells[13 * 6 + 4] == 1:
				lowest_empty_or_blue = 13
			blue_rows_between_waves.append(lowest_empty_or_blue)
		if fn == 100:
			waves_seen_at_f100 = model.motion[0].result.get("waves", []).size()
	expect(blue_rows_between_waves == [11, 12, 13], "intermediate_gravity: par de gemas azuis desce 1 celula por quadro em f=88..90")
	expect(waves_seen_at_f100 == 1, "multi_wave_chains: em f=100 apenas a Onda 1 foi resolvida (sem pre-calculo antecipado das ondas seguintes)")
	expect(model.last_results[0].get("waves", []).size() == 3, "multi_wave_chains: 3 ondas resolvidas ao final da cadeia")

	# 4 & 5. Entrega de Counter Gems na linha 0 (fase 18) e queda quadro a quadro (fase 19):
	var model_atk: RefCounted = Match.new()
	var item_atk: Dictionary = cases_by_id["attack_red12"]
	configure_player(model_atk, 0, item_atk.p1_init)
	configure_player(model_atk, 1, item_atk.p2_init)
	turn0 = int(item_atk.p1_init.turn)
	p1_down = true
	var row0_at_f241: int = 0
	var row1_at_f242: int = 0
	var pend_at_f241: int = -1
	var pend_at_f256: int = -1
	var p2_turn_at_f280: int = -1
	var p2_turn_at_f281: int = -1
	for sample in item_atk.samples:
		var fn: int = int(sample.frame)
		model_atk.input_masks[0] = (4 if (p1_down and fn >= 2) else 0) | (512 if fn == 2 else 0)
		model_atk.input_masks[1] = 0
		model_atk.locked_residual[0] = int(sample.perm1)
		model_atk.locked_residual[1] = int(sample.perm2)
		model_atk.tick()
		if model_atk.turn_number[0] != turn0:
			p1_down = false
		if fn == 241:
			for x in range(6):
				if Gem.kind(model_atk.boards[1].cells[x]) == Gem.Kind.COUNTER:
					row0_at_f241 += 1
			pend_at_f241 = model_atk.pending[1]
		elif fn == 242:
			for x in range(6):
				if Gem.kind(model_atk.boards[1].cells[6 + x]) == Gem.Kind.COUNTER:
					row1_at_f242 += 1
		elif fn == 256:
			pend_at_f256 = model_atk.pending[1]
		elif fn == 280:
			p2_turn_at_f280 = model_atk.motion[1].phase
		elif fn == 281:
			p2_turn_at_f281 = model_atk.motion[1].phase
	expect(row0_at_f241 == 6 and pend_at_f241 == 27, "counter_delivery: 1a linha de 6 Counter Gems nasce em y=0 em f=241 reduzindo pending 33->27")
	expect(row1_at_f242 == 6, "counter_fall: 1a linha de Counter Gems desce de y=0 para y=1 em f=242 (fase 19)")
	expect(pend_at_f256 == 0, "counter_delivery: linha residual de 3 Counter Gems nasce em f=256 zerando pending")
	expect(p2_turn_at_f280 != 0 and p2_turn_at_f281 == 0, "next_pair_transition: P2 transita da fase 19 para fase 0 (proxima dupla) exatamente em f=281")

func _initialize() -> void:
	var out_path: String = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_path = argument.trim_prefix("--out=")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chain_counter_timeline_fixtures.json"))
	var total_cases: int = 0
	var passed_cases: int = 0
	var total_samples: int = 0
	var matched_samples: int = 0
	var failures: Array = []
	var cases_by_id: Dictionary = {}
	var categories_covered: Dictionary = {}

	for item in data.cases:
		cases_by_id[str(item.id)] = item
		categories_covered[str(item.category)] = int(categories_covered.get(str(item.category), 0)) + 1
		total_cases += 1
		var ram_path: String = ProjectSettings.globalize_path("res://../laboratorio/") + str(item.source_session) + "/captures/" + str(item.id) + "_seed.bin"
		if FileAccess.file_exists(ram_path):
			var ram: PackedByteArray = FileAccess.get_file_as_bytes(ram_path)
			expect(ram.size() == 65536, "seed_ram_size:%s" % item.id)
			var hash_ctx: HashingContext = HashingContext.new()
			hash_ctx.start(HashingContext.HASH_SHA256)
			hash_ctx.update(ram)
			expect(hash_ctx.finish().hex_encode() == str(item.seed_ram_sha256), "seed_ram_sha256:%s" % item.id)

		var model: RefCounted = Match.new()
		configure_player(model, 0, item.p1_init)
		configure_player(model, 1, item.p2_init)
		model.stream = [
			[int(item.p1_init.pivot), int(item.p1_init.satellite)],
			[int(item.p1_init.next_pivot), int(item.p1_init.next_satellite)],
			[1, 1],
			[1, 1],
		]
		var turn0: int = int(item.p1_init.turn)
		var turn2: int = int(item.p2_init.turn)
		var p1_down: bool = true
		var p2_down: bool = bool(item.both) and int(item.delay2) == 0
		var case_ok: bool = true

		for sample in item.samples:
			var fn: int = int(sample.frame)
			total_samples += 1
			var mask1: int = (4 if (p1_down and fn >= 2) else 0) | (512 if (fn == 2 and bool(item.rotate1)) else 0)
			var mask2: int = (4 if (p2_down and fn >= 2) else 0) | (512 if (fn == 2 and bool(item.rotate2)) else 0)
			model.input_masks[0] = mask1
			model.input_masks[1] = mask2
			model.locked_residual[0] = int(sample.perm1)
			model.locked_residual[1] = int(sample.perm2)
			model.tick()

			if int(item.delay2) > 0 and fn == int(item.delay2) + 1:
				p2_down = true
			if model.turn_number[0] != turn0:
				p1_down = false
			if model.turn_number[1] != turn2:
				p2_down = false

			var diff: Dictionary = {}
			if model.turn_number[0] != int(sample.turn1):
				diff["turn1"] = [model.turn_number[0], int(sample.turn1)]
			if model.turn_number[1] != int(sample.turn2):
				diff["turn2"] = [model.turn2, int(sample.turn2)]
			if model.scores[0] != int(sample.score1):
				diff["score1"] = [model.scores[0], int(sample.score1)]
			if model.scores[1] != int(sample.score2):
				diff["score2"] = [model.scores[1], int(sample.score2)]
			if sample.has("phase1") and model.motion[0].phase != int(sample.phase1):
				diff["phase1"] = [model.motion[0].phase, int(sample.phase1)]
			if sample.has("phase2") and model.motion[1].phase != int(sample.phase2):
				diff["phase2"] = [model.motion[1].phase, int(sample.phase2)]
			if sample.has("pending1_raw") and model.pending[0] != int(sample.pending1_raw):
				diff["pending1"] = [model.pending[0], int(sample.pending1_raw)]
			if sample.has("pending2_raw") and model.pending[1] != int(sample.pending2_raw):
				diff["pending2"] = [model.pending[1], int(sample.pending2_raw)]

			var exp_grid1: PackedInt32Array = PackedInt32Array()
			for code in str(sample.grid1).split(":"):
				exp_grid1.append(Gem.canonical(str(code).hex_to_int()))
			if model.boards[0].cells != exp_grid1:
				diff["grid1"] = true

			var exp_grid2: PackedInt32Array = PackedInt32Array()
			for code in str(sample.grid2).split(":"):
				exp_grid2.append(Gem.canonical(str(code).hex_to_int()))
			if model.boards[1].cells != exp_grid2:
				diff["grid2"] = true

			if diff.is_empty():
				matched_samples += 1
			else:
				if case_ok:
					failures.append({"case": item.id, "frame": fn, "diff": diff})
				case_ok = false
		if case_ok:
			passed_cases += 1

	verify_explicit_categories(cases_by_id)
	expect(passed_cases == total_cases and matched_samples == total_samples, "all_mame_timeline_samples_match")

	if not out_path.is_empty():
		var summary: Dictionary = {
			"cases": total_cases,
			"cases_passed": passed_cases,
			"samples": total_samples,
			"samples_matched": matched_samples,
			"checks": checks,
			"categories": categories_covered,
			"failures": failures,
			"check_failures": check_failures,
		}
		var out_file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
		out_file.store_string(JSON.stringify(summary, "\t"))
		out_file.close()

	print("CHAIN_COUNTER_TIMELINE cases=%d/%d samples=%d/%d checks=%d categories=%s failures=%s check_failures=%s" % [
		passed_cases, total_cases, matched_samples, total_samples, checks,
		JSON.stringify(categories_covered), JSON.stringify(failures), JSON.stringify(check_failures)
	])
	quit(0 if (failures.is_empty() and check_failures.is_empty()) else 1)
