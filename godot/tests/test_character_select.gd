extends SceneTree
const Catalog = preload("res://core/character_catalog.gd")
const Session = preload("res://core/match_session.gd")
const Selection = preload("res://core/selection_state.gd")
const Match = preload("res://core/match_model.gd")
const Gem = preload("res://core/gem_rules.gd")
const Arena = preload("res://presentation/cs_arena.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	expect(Catalog.ROSTER.size() == 8,"eight characters")
	var unique_ids := {}
	for character in Catalog.ROSTER:
		unique_ids[character.id] = true
		expect(not character.has("nickname") and not character.has("rank") and not character.has("xp"),"account data separate")
		Session.accept_server_assignment(character.team == "CT",[0,1])
		Session.reveal()
		var state = Selection.new()
		state.cursors[0] = Catalog.ROSTER.find(character)
		state.confirm(0)
		state.confirm(1)
		expect(state.save_selection(),"validated team selection")
		var model = Match.new()
		Selection.apply_to_match(model)
		expect(model.character_ids[0] == Catalog.pattern_index(character.id),"selected pattern " + character.id)
		expect(model.scores == [0,0] and model.pending == [0,0] and model.GRAVITY_TICKS == 32,"no economic or speed modifiers")
		var arena = Arena.new()
		for player in range(2):
			var ids: Array[String] = [character.id,character.id]
			arena.configure_characters(ids)
			expect(arena.selected_characters[player].id == character.id,"fighter identity at either side")
			for action in ["idle","shoot","grenade","hit","victory","defeat"]:
				arena.set_fighter_state(player,action,0,true)
				for tick in range(80): arena.advance_fighter_anim(player,model)
				var rect: Rect2 = arena.fighter_draw_rect(player)
				expect(rect.has_area(),"animation reference " + character.id + action)
				if character.temporary:
					for frame in arena.fighter_anims[player][action]: expect(frame.tex == character.sprite,"never borrow another face")
	expect(unique_ids.size() == 8,"unique IDs")
	for index in range(4):
		var ct: Dictionary = Catalog.ROSTER[index]
		var tr: Dictionary = Catalog.ROSTER[index+4]
		expect(is_same(Catalog.pattern_rows(ct.id),Catalog.pattern_rows(tr.id)),"shared table " + ct.pattern)
		for permutation in range(8):
			for amount in [1,5,6,7,12,19,36,72]:
				var left = Match.new()
				var right = Match.new()
				left.character_ids[0] = Catalog.pattern_index(ct.id)
				right.character_ids[0] = Catalog.pattern_index(tr.id)
				left.residual_index[1] = permutation
				right.residual_index[1] = permutation
				expect(left.receive_attack(1,amount,0) == amount,"attack amount unchanged")
				right.receive_attack(1,amount,0)
				expect(left.boards[1].cells == right.boards[1].cells,"equivalent deliveries including partial rows")
				if amount == 72:
					for row in range(12):
						for col in range(6):
							expect(Gem.color(left.boards[1].cells[(13-row)*6+col]) == int(Catalog.pattern_rows(ct.id)[row][col]),"preview equals actual delivery")
	Session.accept_server_assignment(true,[0,0,1,1])
	Session.reveal()
	var state = Selection.new(4)
	state.cursors.assign([0,0,4,4])
	state.move(0,Vector2i.LEFT)
	expect(state.cursors == [3,0,4,4],"horizontal wrap; four independent slots")
	state.move(2,Vector2i.DOWN)
	expect(state.cursors == [3,0,4,4],"independent duo slot")
	state.move(0,Vector2i.DOWN)
	expect(state.cursors[0] == 3,"vertical cannot change team")
	state.confirm(0)
	state.move(0,Vector2i.RIGHT)
	expect(state.cursors[0] == 3,"confirmed cursor locked")
	expect(not state.ready_to_start(),"all players required")
	for player in range(4): state.confirm(player)
	expect(state.ready_to_start(),"four ready slots")
	state.cancel(0)
	expect(not state.ready_to_start(),"cancel confirmation")
	Session.close_match()
	print("CHARACTER_SELECT_TESTS ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
