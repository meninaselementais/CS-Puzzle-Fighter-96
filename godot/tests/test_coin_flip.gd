extends SceneTree
const Session = preload("res://core/match_session.gd")
const Selection = preload("res://core/selection_state.gd")
const Catalog = preload("res://core/character_catalog.gd")
const Match = preload("res://core/match_model.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Session.rng.seed = 96
	var ct_count: int = 0
	var previous: int = Session.match_id
	for trial in range(20000):
		Session.begin_local_match()
		expect(Session.match_id == previous+1,"new toss for each new match")
		previous = Session.match_id
		ct_count += int(Session.team_for(0) == "CT")
		expect(Session.team_for(0) != Session.team_for(1),"opposing sides in every draw")
	expect(ct_count > 9600 and ct_count < 10400,"approximately 50/50 across 20000 draws")
	for first_ct in [true,false]:
		Session.accept_server_assignment(first_ct,[0,1])
		var toss_id: int = Session.match_id
		var source_rng: int = Session.rng.state
		Session.reveal()
		expect(Session.authority == "server" and Session.rng.state == source_rng,"server result does not draw locally")
		var selection: RefCounted = Selection.new()
		for player in range(2):
			expect(selection.available(player).size() == 4,"four legal characters per side")
			for index in range(8):
				var legal: bool = Catalog.ROSTER[index].team == Session.team_for(player)
				expect(selection.choose(player,index) == legal,"direct choose validates team")
				selection.cursors[player] = index
				expect(selection.confirm(player) == legal,"tampered cursor cannot confirm opposite team")
				selection.cancel(player)
			selection.cursors[player] = selection.available(player)[0]
			for step in range(16):
				selection.move(player,Vector2i.RIGHT)
				selection.move(player,Vector2i.DOWN)
				expect(selection.cursors[player] in selection.available(player),"navigation stays in assigned side")
			expect(not selection.choose(-1,0) and not selection.confirm(4),"invalid player rejected")
		selection.cursors[0] = 0
		selection.cursors[1] = 1
		selection.confirmed.assign([true,true,false,false])
		expect(not selection.save_selection(),"CT vs CT cannot start")
		selection.cursors[0] = 4
		selection.cursors[1] = 5
		expect(not selection.save_selection(),"TR vs TR cannot start")
		selection.cursors[0] = selection.available(0)[0]
		selection.cursors[1] = selection.available(1)[0]
		expect(selection.save_selection(),"legal opposite teams start")
		var teams: Array[String] = [Session.team_for(0),Session.team_for(1)]
		var chosen: Array[String] = Session.characters.duplicate()
		var model: RefCounted = Match.new()
		expect(Selection.apply_to_match(model),"validated characters applied to model")
		for result in [0,1,0]:
			expect(Session.record_round(result),"round counted")
			expect(not Session.record_round(result),"no double counting")
			expect(Session.team_for(0) == teams[0] and Session.team_for(1) == teams[1],"sides fixed in all three rounds")
			expect(Session.match_id == toss_id and Session.characters == chosen,"no new draw or character swap between rounds")
			if Session.phase != "finished": expect(Session.advance_round(),"advance round without draw")
		expect(Session.round_wins == [2,1] and Session.round_number == 3 and Session.winner == 0,"best of three ends 2-1")
		expect(not Session.advance_round(),"no fourth round")
		Session.begin_local_match()
		expect(Session.match_id == toss_id+1 and Session.characters.is_empty() and Session.round_wins == [0,0],"new match resets series and draws again")
	Session.accept_server_assignment(false,[0,0,1,1])
	Session.reveal()
	var duo: RefCounted = Selection.new(4)
	expect(Session.team_for(0) == Session.team_for(1) and Session.team_for(2) == Session.team_for(3) and Session.team_for(0) != Session.team_for(2),"duo draws whole teams")
	for player in range(4):
		expect(duo.available(player).size() == 4 and duo.confirm(player),"independent legal duo choices")
	expect(duo.save_selection(),"future four slots lock opposite teams")
	expect(not Selection.apply_to_match(Match.new()),"four slots do not launch unfinished 2x2")
	expect(not Session.accept_server_assignment(true,[0,0]),"invalid server grouping rejected")
	for pair in range(4): expect(is_same(Catalog.pattern_rows(Catalog.ROSTER[pair].id),Catalog.pattern_rows(Catalog.ROSTER[pair+4].id)),"A-D unchanged shared tables")
	Session.accept_server_assignment(true,[0,1])
	Session.reveal()
	Session.lock_characters(["sas","phoenix"])
	Session.record_round(-1)
	Session.advance_round()
	expect(Session.round_number == 1 and Session.round_wins == [0,0],"draw repeats round without switching sides")
	Session.record_round(0)
	Session.advance_round()
	Session.record_round(0)
	expect(Session.phase == "finished" and Session.round_number == 2,"best of three can finish 2-0")
	print("COIN_FLIP_TESTS ",checks," checks; P1 CT=",ct_count,"/20000; failures=",failures)
	quit(0 if failures.is_empty() else 1)
