extends SceneTree
## Integração de cenas reais; fixtures de top-out passam pelo resolvedor original.
const Session = preload("res://core/match_session.gd")
const Catalog = preload("res://core/character_catalog.gd")
var visual: bool = false
var total: int = 1000
var out: String = ""
var checks: int = 0
var completed: int = 0
var rounds_played: int = 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var screenshots: Array[String] = []
var journal: FileAccess
var started_ms: int = 0
var ct_first_count: int = 0
var checkpoints: Array[Dictionary] = []
const CASES: Array[Dictionary] = [
	{"id":"ct_2_0","winners":["CT","CT"],"score":[2,0]},
	{"id":"tr_0_2","winners":["TR","TR"],"score":[0,2]},
	{"id":"ct_2_1","winners":["CT","TR","CT"],"score":[2,1]},
	{"id":"tr_1_2","winners":["CT","TR","TR"],"score":[1,2]}
]

func _initialize() -> void:
	call_deferred("run")

func require(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append("match %d: %s" % [completed+1,message])
		push_error(failures[-1])
		write_report()
		quit(1)
	return ok

func score_ct_tr() -> Array[int]:
	return [Session.round_wins[0],Session.round_wins[1]] if Session.team_for(0) == "CT" else [Session.round_wins[1],Session.round_wins[0]]

func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	await send(event)
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	await send(event)

func pad(device: int, button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	await send(event)
	event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = false
	await send(event)

func capture(file_name: String) -> void:
	if not visual: return
	if current_scene is CanvasItem: (current_scene as CanvasItem).queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if not require(image.get_size() == Vector2i(1000,700),"framebuffer dimensions"): return
	if not require(image.save_png(out.path_join(file_name+".png")) == OK,"save capture"): return
	screenshots.append(file_name+".png")

func settled() -> void:
	await process_frame
	await process_frame

func require_scene(script_path: String) -> bool:
	return require(current_scene != null and current_scene.get_script().resource_path == script_path,"scene " + script_path)

func enter_selection(sequence: int) -> void:
	if not require_scene("res://presentation/coin_flip.gd"): return
	var coin: Node = current_scene
	var draw_id: int = Session.match_id
	var teams: Array[String] = [Session.team_for(0),Session.team_for(1)]
	require(teams[0] != teams[1],"coin assigns opposite sides")
	require(Session.phase == "coin" and Session.round_wins == [0,0] and Session.characters.is_empty(),"new match clears session")
	ct_first_count += int(teams[0] == "CT")
	if visual:
		await create_timer(0.4).timeout
		await capture("%02d_%s_coin" % [sequence,CASES[sequence].id])
		await create_timer(1.2).timeout
		await capture("%02d_%s_coin_result" % [sequence,CASES[sequence].id])
	else:
		coin.set_process(false)
		coin._process(1.5)
		coin._process(0.25)
	await key(KEY_ENTER)
	if not require_scene("res://presentation/player_select.gd"): return
	require(Session.match_id == draw_id and [Session.team_for(0),Session.team_for(1)] == teams,"animation/skip does not reroll")
	var select: Node = current_scene
	if not visual: select.set_process(false)
	require(select.selection.available(0).size() == 4 and select.selection.available(1).size() == 4,"four choices per side")
	# Even direct cursor changes cannot get CT/CT or TR/TR through confirmation.
	var original: Array = select.selection.cursors.duplicate()
	for invalid_pair in [[0,1],[4,5]]:
		select.selection.cursors[0] = invalid_pair[0]
		select.selection.cursors[1] = invalid_pair[1]
		await key(KEY_Z)
		await key(KEY_Q)
		require(select.launch_time < 0 and Session.phase == "select","same-side pair cannot start")
		await key(KEY_ESCAPE)
	select.selection.cursors[0] = original[0]
	select.selection.cursors[1] = original[1]
	await key(KEY_DOWN)
	await key(KEY_W)
	require(select.selection.cursors[0] == original[0] and select.selection.cursors[1] == original[1],"vertical navigation cannot change teams")
	# Cycle all four patterns, both sides, keyboard and controller event routes.
	var offset: int = sequence % 4 if not visual else 0
	for step in range(offset):
		if sequence % 2 == 0:
			await key(KEY_RIGHT)
			await key(KEY_D)
		else:
			await pad(0,JOY_BUTTON_DPAD_RIGHT)
			await pad(1,JOY_BUTTON_DPAD_RIGHT)
	for player in range(2): require(Catalog.find(select.selection.ids()[player]).team == teams[player],"legal character for assigned team")
	await capture("%02d_%s_selection" % [sequence,CASES[sequence].id] if visual else "unused")
	if sequence % 2 == 0:
		await key(KEY_Z)
		require(select.launch_time < 0,"one player cannot start alone")
		await key(KEY_Q)
	else:
		await pad(0,JOY_BUTTON_A)
		require(select.launch_time < 0,"controller also requires both players")
		await pad(1,JOY_BUTTON_A)
	require(select.launch_time >= 0,"both confirmations start transition")
	if visual:
		await create_timer(0.72).timeout
	else:
		select._process(0.7)
		await settled()
	if not require_scene("res://presentation/main.gd"): return
	var game: Node = current_scene
	game.set_physics_process(false)
	require(Session.match_id == draw_id and Session.phase == "playing","match starts without another coin")
	require(game.model.character_ids[0] == Catalog.pattern_index(Session.characters[0]) and game.model.character_ids[1] == Catalog.pattern_index(Session.characters[1]),"selected patterns applied")
	require(game.model.winner == -2 and Session.round_number == 1,"round one starts")

func cause_topout(game: Node, losing_player: int) -> void:
	# Coluna de entrada sem buracos e sem Crash Orbs; o resolvedor detecta top-out.
	for row in range(14): game.model.boards[losing_player].cells[row*6+3] = 1 + row % 4
	game.model.resolve_turn(losing_player)
	require(game.model.lost[losing_player],"existing resolver detects top-out")
	require(game.model.winner == 1-losing_player,"existing model chooses round winner")
	game._physics_process(1.0/game.Controls.FRAMES_PER_SECOND)
	var counted: Array = Session.round_wins.duplicate()
	game._physics_process(1.0/game.Controls.FRAMES_PER_SECOND)
	require(Session.round_wins == counted,"round counted exactly once")

func visual_hold(game: Node, duration: float) -> void:
	# Mostra as animações normais sem deixar o tabuleiro-fixture jogar sozinho.
	var elapsed: float = 0.0
	var ticks: float = 0.0
	while elapsed < duration:
		await process_frame
		var delta: float = game.get_process_delta_time()
		elapsed += delta
		ticks += delta * game.Controls.FRAMES_PER_SECOND
		while ticks >= 1.0:
			game.arena.step_from_model(game.model,game.BOARD_ORIGINS)
			ticks -= 1.0
		game.queue_redraw()

func run_match(sequence: int) -> void:
	var test_case: Dictionary = CASES[sequence % 4]
	await enter_selection(sequence)
	if not failures.is_empty(): return
	var game: Node = current_scene
	var draw_id: int = Session.match_id
	var teams: Array[String] = [Session.team_for(0),Session.team_for(1)]
	var characters: Array[String] = Session.characters.duplicate()
	var patterns: Array = game.model.character_ids.duplicate()
	var expected: Array[int] = [0,0]
	var round_trace: Array[Dictionary] = []
	for round_index in range(test_case.winners.size()):
		require(Session.round_number == round_index+1,"correct active round number")
		if visual and round_index == 2:
			await capture("%02d_%s_third_round_started" % [sequence,test_case.id])
			await create_timer(0.8).timeout
		var winning_team: String = test_case.winners[round_index]
		var winning_player: int = 0 if teams[0] == winning_team else 1
		cause_topout(game,1-winning_player)
		rounds_played += 1
		expected[0 if winning_team == "CT" else 1] += 1
		require(score_ct_tr() == expected,"correct score CT/TR")
		require(Session.match_id == draw_id and [Session.team_for(0),Session.team_for(1)] == teams,"same draw and teams across rounds")
		require(Session.characters == characters and game.model.character_ids == patterns,"same characters and patterns across rounds")
		require(game.arena.wins == Session.round_wins,"visible trophies match series score")
		round_trace.append({"round":Session.round_number,"winning_team":winning_team,"score_ct_tr":expected.duplicate(),"phase":Session.phase,"draw_id":Session.match_id})
		if visual:
			await visual_hold(game,0.65)
			await capture("%02d_%s_score_%d_%d" % [sequence,test_case.id,expected[0],expected[1]])
			await visual_hold(game,0.65)
			require(score_ct_tr() == expected and game.arena.wins == Session.round_wins,"presentation hold does not alter score")
		if round_index < test_case.winners.size()-1:
			require(Session.phase == "between_rounds","next round available before two wins")
			await key(KEY_R)
			require(Session.phase == "playing" and game.model.winner == -2,"R begins next round")
			require(game.model.pending == [0,0] and game.model.scores == [0,0] and game.model.lost == [false,false],"round model reset")
			require(game.model.boards[0].cells.count(0) == 84 and game.model.boards[1].cells.count(0) == 84,"boards cleared")
			require(game.arena.projectiles.is_empty() and game.arena.gem_sparks.is_empty(),"round effects cleared")
			if expected == [1,1]: require(Session.round_number == 3,"1-1 starts the third round")
	if not require(Session.phase == "finished" and score_ct_tr() == test_case.score,"final score " + str(test_case.score)): return
	require(Session.winner == (0 if teams[0] == test_case.winners[-1] else 1),"correct match winner")
	# Holding end-state through further ticks cannot award an extra round.
	for tick in range(3): game._physics_process(1.0/game.Controls.FRAMES_PER_SECOND)
	require(score_ct_tr() == test_case.score and Session.match_id == draw_id,"finished match stays finished")
	var record: Dictionary = {"index":completed+1,"case":test_case.id,"draw_id":draw_id,"teams":teams,"characters":characters,"patterns":patterns,"rounds":round_trace,"final_score_ct_tr":score_ct_tr(),"passed":failures.is_empty()}
	await key(KEY_R)
	if not require_scene("res://presentation/coin_flip.gd"): return
	require(Session.match_id == draw_id+1 and Session.phase == "coin" and Session.authority == "local","new complete match requests a fresh local toss")
	require(Session.round_wins == [0,0] and Session.characters.is_empty() and Session.round_number == 1,"new match fully resets series")
	if visual:
		await create_timer(0.3).timeout
		await capture("%02d_%s_new_toss" % [sequence,test_case.id])
	record["next_draw_id"] = Session.match_id
	records.append(record)
	journal.store_line(JSON.stringify(record))
	completed += 1
	if completed % 25 == 0 or visual:
		journal.flush()
		checkpoints.append({"completed":completed,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"elapsed_s":float(Time.get_ticks_msec()-started_ms)/1000.0})
		write_report()
		print("MATCH_FLOW_PROGRESS ",completed,"/",total," rounds=",rounds_played," checks=",checks," failures=",failures.size())

func write_report() -> void:
	if out.is_empty(): return
	var result: Dictionary = {"visual":visual,"renderer":RenderingServer.get_current_rendering_method(),"requested":total,"completed":completed,"rounds":rounds_played,"checks":checks,"failures":failures,"ct_player_one":ct_first_count,"elapsed_s":float(Time.get_ticks_msec()-started_ms)/1000.0,"screenshots":screenshots,"checkpoints":checkpoints,"cases":records}
	var file: FileAccess = FileAccess.open(out.path_join("integration_summary.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()

func run() -> void:
	started_ms = Time.get_ticks_msec()
	visual = "--visual" in OS.get_cmdline_user_args()
	if visual: total = 4
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--matches="): total = int(argument.get_slice("=",1))
	out = OS.get_environment("PF_REPORT")
	if out.is_empty(): out = ProjectSettings.globalize_path("res://../relatorios/rounds_integration") # lint:ignore res_path — saída gerada
	DirAccess.make_dir_recursive_absolute(out)
	journal = FileAccess.open(out.path_join("matches.ndjson"),FileAccess.WRITE)
	root.size = Vector2i(1000,700)
	Session.close_match()
	if visual: Session.accept_server_assignment(true,[0,1])
	change_scene_to_file("res://coin_flip.tscn")
	await settled()
	for sequence in range(total):
		if visual and sequence > 0:
			# Every named scenario uses P1=CT, so the visible P1/P2 score is CT/TR.
			Session.accept_server_assignment(true,[0,1])
			change_scene_to_file("res://coin_flip.tscn")
			await settled()
		await run_match(sequence)
		if not failures.is_empty(): break
	if visual and failures.is_empty():
		# Complete the new local toss started by R, and return to a fresh selection.
		var local_draw_id: int = Session.match_id
		await create_timer(1.5).timeout
		await capture("04_local_new_draw_result")
		await key(KEY_ENTER)
		require_scene("res://presentation/player_select.gd")
		require(Session.match_id == local_draw_id and Session.phase == "select" and Session.round_wins == [0,0],"return to selection after the fresh local draw")
		await capture("04_return_selection_new_draw")
	write_report()
	journal.close()
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
		await process_frame
	print("MATCH_FLOW_RESULT completed=",completed,"/",total," rounds=",rounds_played," checks=",checks," failures=",failures)
	quit(0 if completed == total and failures.is_empty() else 1)
