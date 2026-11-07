extends RefCounted
## V11.2: projection only. Does not generate NEXT, retain state, or emit events.
const Session = preload("res://core/match_session.gd")

static func unavailable(reason: String) -> Dictionary:
	return {"available": false, "value": null, "reason": reason}

static func available(value: Variant) -> Dictionary:
	return {"available": true, "value": value, "reason": ""}

## session_active must come from the owning scene; replay/showcase use false.
static func snapshot(model: RefCounted, session_active: bool = false) -> Dictionary:
	var players: Array[Dictionary] = []
	for player in range(2):
		var next_index: int = int(model.pair_index[player]) + 1
		var next_pair: Dictionary = unavailable("next_pair_not_generated")
		if next_index < model.stream.size():
			var colors: Array = model.stream[next_index]
			next_pair = available({"sequence_index": next_index, "pivot": int(colors[0]), "satellite": int(colors[1])})
		var result: Dictionary = model.last_results[player]
		var combo: Dictionary = unavailable("no_observed_resolution")
		var generated: Dictionary = unavailable("no_observed_resolution")
		if result.has("waves") and not result.waves.is_empty():
			combo = available({"scope": "last_observed_resolution", "result": result.duplicate(true)})
			if result.has("attack"): generated = available(int(result.attack))
		var character: Dictionary = unavailable("session_not_bound")
		var team: Dictionary = unavailable("session_not_bound")
		if session_active:
			if player < Session.characters.size(): character = available(str(Session.characters[player]))
			else: character = unavailable("character_not_selected")
			var assigned_team: String = Session.team_for(player)
			team = available(assigned_team) if not assigned_team.is_empty() else unavailable("team_not_assigned")
		players.append({
			"slot": player, "slot_label": "P%d" % (player + 1),
			"player_id": unavailable("player_profile_not_available"),
			"nickname": unavailable("player_profile_not_available"),
			"rank": unavailable("player_profile_not_available"),
			"session_victories": unavailable("session_history_not_available"),
			"character_id": character, "team": team,
			"score": int(model.scores[player]), "lost": bool(model.lost[player]),
			"turn": int(model.turn_number[player]), "motion_phase": int(model.motion[player].phase),
			"warning": warning_for(model, player),
			"pending_attack": int(model.pending[player]),
			"pending_display": clampi(int(model.pending[player]), 0, 99),
			"generated_attack": generated,
			"sent_attack": available(int(model.last_sent_attack[player])),
			"combo": combo, "next_pair": next_pair,
		})
	var session: Dictionary = unavailable("session_not_bound")
	if session_active:
		session = available({"match_id": Session.match_id, "phase": Session.phase,
			"authority": Session.authority, "round_number": Session.round_number,
			"round_wins": Session.round_wins.duplicate(), "round_recorded": Session.round_recorded,
			"match_winner": Session.winner, "last_round_result": Session.last_round_result})
	return {"schema_version": 1, "model_frame": int(model.frame),
		"model_winner": int(model.winner), "session": session, "players": players}

static func warning_for(model: RefCounted, player: int) -> bool:
	# Same presentation predicate as CsArena.is_board_in_danger; tested for parity.
	if int(model.pending[player]) >= 6: return true
	for index in range(12, 36):
		if model.boards[player].cells[index] != 0: return true
	return false
