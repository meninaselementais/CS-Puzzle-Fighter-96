extends SceneTree
const MatchModel = preload("res://core/match_model.gd")
const Hud = preload("res://presentation/hud_presenter.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const Session = preload("res://core/match_session.gd")
var checks: int = 0
var failures: Array[String] = []
var suites: Array[String] = []

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
		for property in script.get_script_property_list(): result[property.name] = state(value.get(property.name))
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

func session_state() -> String:
	return JSON.stringify([Session.rng.seed, Session.rng.state, Session.match_id, Session.phase,
		Session.authority, Session.team_zero_ct, Session.player_groups, Session.characters,
		Session.round_wins, Session.round_number, Session.round_recorded, Session.winner, Session.last_round_result])

func assert_unknown(field: Dictionary, reason: String, label: String) -> void:
	expect(not field.available and field.value == null and field.reason == reason, label)

func test_missing_data() -> void:
	var model: RefCounted = MatchModel.new()
	var view: Dictionary = Hud.snapshot(model)
	assert_unknown(view.session, "session_not_bound", "unbound model has no guessed session")
	for player in range(2):
		var p: Dictionary = view.players[player]
		expect(p.slot == player and p.slot_label == "P%d" % (player + 1), "actual local slot")
		for key in ["nickname", "rank", "player_id"]: assert_unknown(p[key], "player_profile_not_available", key)
		assert_unknown(p.session_victories, "session_history_not_available", "round wins are not session victories")
		assert_unknown(p.sent_attack, "net_sent_attack_not_exposed", "sent attack unknown, never fabricated zero")
		assert_unknown(p.generated_attack, "no_observed_resolution", "no invented generated attack")
		assert_unknown(p.combo, "no_observed_resolution", "no invented combo")
		assert_unknown(p.next_pair, "next_pair_not_generated", "missing NEXT does not spawn")
	suites.append("missing_data")

func test_repeated_reads() -> void:
	var model: RefCounted = MatchModel.new()
	model.pending.assign([33, 132])
	model.scores.assign([1200, 900])
	var before: String = JSON.stringify(state(model))
	var session_before: String = session_state()
	var first: Dictionary = Hud.snapshot(model, true)
	for repeat in range(1000): expect(Hud.snapshot(model, true) == first, "repeat deterministic %d" % repeat)
	expect(JSON.stringify(state(model)) == before, "all model properties unchanged after 1000 reads")
	expect(session_state() == session_before, "session state and session RNG unchanged")
	var control: RefCounted = MatchModel.new()
	for draw in range(128): expect(model.rng.randi() == control.rng.randi(), "next RNG outputs identical %d" % draw)
	suites.append("repeated_reads_rng")

func test_next_independence_and_copies() -> void:
	var model: RefCounted = MatchModel.new()
	# Unit-test fixture only: existing cached values, not production defaults.
	model.stream.append([2, 12])
	model.stream.append([4, 1])
	model.pair_index.assign([0, 1])
	var before: String = JSON.stringify(state(model))
	var view: Dictionary = Hud.snapshot(model)
	expect(view.players[0].next_pair.value == {"sequence_index": 1, "pivot": 2, "satellite": 12}, "P1 cached NEXT includes original code flags")
	expect(view.players[1].next_pair.value == {"sequence_index": 2, "pivot": 4, "satellite": 1}, "P2 own sequence index")
	view.players[0].next_pair.value.pivot = 99
	view.players[1].pending_attack = 999
	expect(JSON.stringify(state(model)) == before, "consumer cannot mutate model through snapshot")
	expect(Hud.snapshot(model).players[0].next_pair.value.pivot == 2, "next read detached from changed snapshot")
	model.pair_index[0] = 2
	view = Hud.snapshot(model)
	assert_unknown(view.players[0].next_pair, "next_pair_not_generated", "advanced P1 has uncached NEXT")
	expect(view.players[1].next_pair.available, "P1 unavailable does not erase P2 cache")
	suites.append("next_independence_copies")

func test_warning_and_pending() -> void:
	var model: RefCounted = MatchModel.new()
	var arena: RefCounted = Arena.new()
	for amount in [0, 1, 5, 6, 17, 18, 98, 99, 100, 250]:
		model.pending.assign([amount, 0])
		var view: Dictionary = Hud.snapshot(model)
		expect(view.players[0].pending_attack == amount and view.players[0].pending_display == mini(amount, 99), "pending preserves real amount %d" % amount)
		expect(view.players[0].warning == arena.is_board_in_danger(model, 0), "danger parity pending %d" % amount)
		expect(view.players[1].pending_attack == 0 and not view.players[1].warning, "pending does not leak to P2")
	model.pending.assign([0,0])
	for index in [0, 11, 12, 35, 36, 83]:
		model.boards[1].cells.fill(0)
		model.boards[1].cells[index] = 1
		var view: Dictionary = Hud.snapshot(model)
		expect(view.players[1].warning == arena.is_board_in_danger(model, 1), "danger parity cell %d" % index)
		expect(not view.players[0].warning, "board danger does not leak to P1")
	suites.append("warning_pending_parity")

func test_combo_and_attack_meaning() -> void:
	var model: RefCounted = MatchModel.new()
	# Synthetic input tests raw-vs-net semantics; real resolutions tested below.
	model.last_results[0] = {"waves": [{"chain": 1, "combo": 2, "attack": 20, "groups": [{"count": 8}]}], "attack": 20, "score": 800}
	model.pending.assign([0, 250])
	var before: String = JSON.stringify(state(model))
	var view: Dictionary = Hud.snapshot(model)
	expect(view.players[0].generated_attack.value == 20, "raw attack accurately labelled")
	expect(view.players[0].combo.value.scope == "last_observed_resolution", "combo is last result, not new event")
	assert_unknown(view.players[0].sent_attack, "net_sent_attack_not_exposed", "saturation does not justify guessing net sent")
	assert_unknown(view.players[1].generated_attack, "no_observed_resolution", "opponent pending is not own generated attack")
	view.players[0].combo.value.result.waves[0].groups[0].count = 999
	expect(JSON.stringify(state(model)) == before, "nested combo groups deeply copied")
	suites.append("attack_semantics_deep_copy")

func test_session_rounds() -> void:
	expect(Session.accept_server_assignment(false, [0,1]), "bind real session")
	Session.reveal()
	expect(Session.lock_characters(["phoenix","sas"]), "real selection")
	var model: RefCounted = MatchModel.new()
	var before: String = session_state()
	var view: Dictionary = Hud.snapshot(model, true)
	expect(session_state() == before, "session projection does not reroll or record round")
	expect(view.players[0].team.value == "TR" and view.players[1].team.value == "CT", "real reversed sides")
	expect(view.players[0].character_id.value == "phoenix" and view.players[1].character_id.value == "sas", "agent ID distinct from nickname")
	expect(view.session.value.phase == "playing" and view.session.value.round_number == 1, "real round state")
	expect(Session.record_round(0), "record round outside projection")
	view = Hud.snapshot(model, true)
	expect(view.session.value.round_wins == [1,0] and view.session.value.phase == "between_rounds", "round score is exposed")
	assert_unknown(view.players[0].session_victories, "session_history_not_available", "one round does not invent session history")
	view.session.value.round_wins[0] = 99
	expect(Session.round_wins == [1,0], "round wins detached")
	expect(Session.advance_round(), "advance outside projection")
	expect(Session.record_round(0), "finish outside projection")
	view = Hud.snapshot(model, true)
	expect(view.session.value.phase == "finished" and view.session.value.match_winner == 0, "finished match available")
	assert_unknown(Hud.snapshot(model).session, "session_not_bound", "showcase must not inherit stale session")
	Session.close_match()
	view = Hud.snapshot(model, true)
	assert_unknown(view.players[0].character_id, "character_not_selected", "closed selection unavailable")
	assert_unknown(view.players[0].team, "team_not_assigned", "closed side unavailable")
	suites.append("session_lifecycle")

func test_trajectory_and_real_resolution() -> void:
	var observed: RefCounted = MatchModel.new()
	var control: RefCounted = MatchModel.new()
	# A controlled board drives the real temporal resolver in both models.
	for model in [observed, control]:
		for index in [66,67,68,69,72,73,74,75,78,79,80,81]: model.boards[0].cells[index] = 1
		model.boards[0].cells[82] = 9
		model.motion[0].phase = 3
		model.motion[0].result = {"waves": [], "attack": 0, "score": 0, "converted": 0, "gravity": 0}
		model.pending.assign([5, 245])
	var saw_wave: bool = false
	for frame in range(720):
		observed.input_masks.assign([4 if frame % 80 < 40 else 0, 4])
		control.input_masks.assign(observed.input_masks.duplicate())
		var before: String = JSON.stringify(state(observed))
		var view: Dictionary = Hud.snapshot(observed)
		if view.players[0].combo.available:
			saw_wave = true
			expect(view.players[0].generated_attack.value == int(observed.last_results[0].attack), "real temporal raw attack")
			assert_unknown(view.players[0].sent_attack, "net_sent_attack_not_exposed", "real net remains unavailable")
		expect(JSON.stringify(state(observed)) == before, "frame %d read pure" % frame)
		observed.tick()
		control.tick()
		expect(JSON.stringify(state(observed)) == JSON.stringify(state(control)), "trajectory identical frame %d" % frame)
	expect(saw_wave, "real temporal wave was exercised")
	suites.append("real_resolution_720_ticks")

func _initialize() -> void:
	test_missing_data()
	test_repeated_reads()
	test_next_independence_and_copies()
	test_warning_and_pending()
	test_combo_and_attack_meaning()
	test_session_rounds()
	test_trajectory_and_real_resolution()
	var folder: String = OS.get_environment("PF_REPORT")
	if not folder.is_empty():
		var file: FileAccess = FileAccess.open(folder.path_join("hud_presenter.json"), FileAccess.WRITE)
		if file == null:
			push_error("Cannot write hud_presenter.json")
			quit(1)
			return
		file.store_string(JSON.stringify({"checks": checks, "suites": suites, "failures": failures}, "  "))
	print("HUD_PRESENTER checks=", checks, " suites=", suites.size(), " failures=", failures)
	quit(0 if failures.is_empty() and suites.size() == 7 else 1)
