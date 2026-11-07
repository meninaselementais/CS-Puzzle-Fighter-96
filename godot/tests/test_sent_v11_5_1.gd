extends SceneTree
const Model = preload("res://core/match_model.gd")
const Before = preload("res://tests/reference_sent/model.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
const Hud = preload("res://presentation/hud_presenter.gd")
const Rng = preload("res://core/arcade_rng.gd")
class View extends "res://presentation/main.gd":
	pass
var checks: int = 0
var failures: Array[String] = []
func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func state(v: Variant) -> Variant:
	if v is RandomNumberGenerator: return [v.seed,v.state]
	if v is RefCounted:
		var d: Dictionary = {}
		for p in v.get_script().get_script_property_list():
			if not str(p.name).ends_with(".gd") and p.name not in ["last_sent_attack","sent_event_id","sent_turn"]: d[p.name]=state(v.get(p.name))
		return d
	if v is Array:
		var a: Array = []
		for x in v: a.append(state(x))
		return a
	if v is Dictionary:
		var d: Dictionary = {}
		for k in v: d[k]=state(v[k])
		return d
	return v
func _initialize() -> void:
	call_deferred("run")
func setup(m: RefCounted, chain: int) -> void:
	for i in range(2):
		m.boards[i].load_cells(Fixtures.chain_board(chain))
		m.motion[i].phase=3
		m.motion[i].result={"waves":[],"score":0,"attack":0,"converted":0,"gravity":0}
func run() -> void:
	# Real temporal resolution on both players, with cancellation and queue saturation.
	for chain in [1,3,5]:
		for incoming in [0,2,200,250]:
			var a: RefCounted = Model.new()
			var b: RefCounted = Before.new()
			setup(a,chain); setup(b,chain)
			a.pending.assign([incoming,incoming]); b.pending.assign([incoming,incoming])
			# Raw production is observed by the test itself, per player and per turn. MatchModel.spawn() replaces the Motion
			# object (empty result) before the next deposit, so motion.result cannot be used as the resolution record.
			var seen_obj: Array = [null,null]
			var seen_waves: Array = [0,0]
			var raw_by_turn: Array = [{},{}]
			for tick in range(500):
				a.tick(); b.tick()
				for i in range(2):
					var mo: RefCounted = a.motion[i]
					var waves: Array = mo.result.get("waves",[])
					var first: int = int(seen_waves[i]) if seen_obj[i]==mo else 0
					for w in range(first,waves.size()):
						var turn_key: int = a.turn_number[i]
						raw_by_turn[i][turn_key] = int(raw_by_turn[i].get(turn_key,0)) + int(waves[w].attack)
					seen_obj[i] = mo
					seen_waves[i] = waves.size()
				expect(JSON.stringify(state(a))==JSON.stringify(state(b)),"all preexisting state, RNG and results identical")
				for i in range(2):
					var owner_turn: int = a.sent_turn[i]
					var raw_same_resolution: int = int(raw_by_turn[i].get(owner_turn,0))
					expect(a.last_sent_attack[i]>=0 and (owner_turn<0 or a.last_sent_attack[i]<=raw_same_resolution),"net total never exceeds raw production of the same resolution (chain %d incoming %d tick %d P%d total %d raw %d turn %d)" % [chain,incoming,tick,i+1,a.last_sent_attack[i],raw_same_resolution,owner_turn])
			expect(a.sent_event_id[0]>0 and a.sent_event_id[1]>0,"both players observed actual waves")
	# Independently known single-wave board: two normal gems plus Crash, attack=3.
	for test in [[0,0,3],[20,0,0],[1,0,2],[0,249,1],[0,250,0]]:
		var m: RefCounted = Model.new()
		for i in range(2): m.boards[i].cells.fill(0)
		m.boards[0].cells[78]=9; m.boards[0].cells[79]=1; m.boards[0].cells[80]=1
		m.motion[0].phase=11; m.motion[0].clear_timer=1; m.motion[0].result={"waves":[],"score":0,"attack":0}
		m.pending.assign([test[0],test[1]])
		m.motion[0].step(m,0,0)
		var raw: int = int(m.motion[0].result.attack)
		expect(raw==3,"independent raw fixture")
		expect(m.last_sent_attack[0]==test[2],"actual accepted dispatch after cancellation/cap")
	for incoming in [0,1,20]:
		var current: RefCounted = Model.new()
		var previous: RefCounted = Before.new()
		for item in [current,previous]:
			for i in range(2): item.boards[i].cells.fill(0)
			item.boards[0].cells[78]=9; item.boards[0].cells[79]=1; item.boards[0].cells[80]=1
			item.pending[0]=incoming
			item.resolve_turn(0)
		expect(JSON.stringify(state(current))==JSON.stringify(state(previous)),"synchronous resolution parity")
		expect(current.last_sent_attack[0]==maxi(0,3-incoming),"synchronous actual outgoing")
	# Real chains (fixture of 3 and 5 waves): manual stepping of P1 only, same per-tick order as MatchModel.tick().
	# Expected accepted amount per wave is computed here, independently of record_sent_attack().
	for chain in [3,5]:
		for incoming in [0,2,200,250]:
			var r: RefCounted = Model.new()
			setup(r,chain)
			r.pending.assign([incoming,0])
			var first_motion: RefCounted = r.motion[0]
			var expected_total: int = 0
			var raw_total: int = 0
			var last_net: int = 0
			var wave_count: int = 0
			var resolved: bool = false
			for guard in range(3000):
				r.frame += 1
				r.global_seed = Rng.advance(r.global_seed)
				r.residual_index[0] = r.locked_residual[0] if r.locked_residual[0] >= 0 else (r.global_seed & 7)
				var before_obj: RefCounted = r.motion[0]
				var own_queue: int = r.pending[0]
				var their_queue: int = r.pending[1]
				var waves_before: int = before_obj.result.waves.size()
				before_obj.step(r,0,0)
				if before_obj.result.waves.size() > waves_before:
					var raw: int = int(before_obj.result.waves[-1].attack)
					var net: int = mini(250,their_queue+maxi(0,raw-own_queue))-their_queue
					expected_total += net
					raw_total += raw
					last_net = net
					wave_count += 1
					expect(r.last_sent_attack[0]==expected_total,"real chain running total (chain %d incoming %d wave %d)" % [chain,incoming,wave_count])
				# A resolution legitimately ends in one of two ways (gem_motion.gd phase 19): the next pair is spawned,
				# or the entry cell is blocked, the player is marked lost and no pair is spawned.
				if r.motion[0] != before_obj or r.lost[0]:
					resolved = true
					break
			var spawned: bool = r.motion[0] != first_motion
			expect(resolved,"real chain resolution ended by spawn or defeat (chain %d incoming %d lost %s phase %d pending %d waves %d)" % [chain,incoming,str(r.lost[0]),r.motion[0].phase,r.pending[0],wave_count])
			expect(spawned != r.lost[0],"exactly one ending: next pair spawned xor player defeated (chain %d incoming %d)" % [chain,incoming])
			if r.lost[0]:
				expect(r.boards[0].cells[15]!=0 and r.winner==1 and r.motion[0].phase==0,"defeat is legitimate: entry cell blocked, P2 wins, motion idle (chain %d incoming %d)" % [chain,incoming])
			else:
				expect(r.winner==-2 and r.pairs[0]!=null and r.boards[0].cells[15]==0,"no defeat: pair spawned and entry cell free (chain %d incoming %d)" % [chain,incoming])
			expect(incoming>2 or not r.lost[0],"small queues never cause defeat (chain %d incoming %d)" % [chain,incoming])
			expect(wave_count>=2,"real chain produced several waves (chain %d incoming %d waves %d)" % [chain,incoming,wave_count])
			expect(r.last_sent_attack[0]==expected_total and expected_total<=raw_total,"real chain total persists after spawn and never exceeds raw (chain %d incoming %d total %d expected %d raw %d)" % [chain,incoming,r.last_sent_attack[0],expected_total,raw_total])
			expect(incoming!=0 or raw_total>250 or expected_total==raw_total,"without incoming queue the total equals the whole chain production")
			expect(wave_count<2 or expected_total>=last_net,"total is not just the last wave")
			expect(r.last_sent_attack[1]==0 and r.sent_event_id[1]==0,"real chain P2 untouched")
	# V11.5.1 total: waves of one resolution add only what the opposing queue accepted.
	for start in [0,1,2,200]:
		var t: RefCounted = Model.new()
		for i in range(2): t.boards[i].cells.fill(0)
		t.pending.assign([start,0])
		t.motion[0].result={"waves":[],"score":0,"attack":0}
		var total: int = 0
		for wave_index in range(3):
			t.boards[0].cells.fill(0)
			t.boards[0].cells[78]=9; t.boards[0].cells[79]=1; t.boards[0].cells[80]=1
			t.motion[0].phase=11; t.motion[0].clear_timer=1
			var waves_before: int = t.motion[0].result.waves.size()
			var own_queue: int = t.pending[0]
			var their_queue: int = t.pending[1]
			t.motion[0].step(t,0,0)
			if t.motion[0].result.waves.size()==waves_before: continue
			var raw_wave: int = int(t.motion[0].result.waves[-1].attack)
			var net_wave: int = maxi(0,raw_wave-own_queue)
			total += mini(250,their_queue+net_wave)-their_queue
			expect(t.last_sent_attack[0]==total,"accumulated accepted total, start "+str(start)+" wave "+str(wave_index))
			expect(t.last_sent_attack[1]==0 and t.sent_event_id[1]==0,"P2 accumulator independent")
		t.motion[0].phase=12
		t.motion[0].step(t,0,0)
		expect(t.last_sent_attack[0]==total,"total persists after the resolution")
		t.turn_number[0]+=1
		t.motion[0].result={"waves":[],"score":0,"attack":0}
		t.boards[0].cells.fill(0)
		t.boards[0].cells[78]=9; t.boards[0].cells[79]=1; t.boards[0].cells[80]=1
		t.motion[0].phase=11; t.motion[0].clear_timer=1
		var own_next: int = t.pending[0]
		var their_next: int = t.pending[1]
		t.motion[0].step(t,0,0)
		var net_next: int = maxi(0,int(t.motion[0].result.waves[-1].attack)-own_next)
		expect(t.last_sent_attack[0]==mini(250,their_next+net_next)-their_next,"next resolution resets accumulator")
	# Mirror case: P2 accumulates independently of P1.
	var mirror: RefCounted = Model.new()
	for i in range(2): mirror.boards[i].cells.fill(0)
	mirror.boards[1].cells[78]=9; mirror.boards[1].cells[79]=1; mirror.boards[1].cells[80]=1
	mirror.motion[1].phase=11; mirror.motion[1].clear_timer=1; mirror.motion[1].result={"waves":[],"score":0,"attack":0}
	mirror.motion[1].step(mirror,1,0)
	expect(mirror.last_sent_attack[1]==3 and mirror.last_sent_attack[0]==0 and mirror.sent_event_id[0]==0,"P2 net total with independent P1")
	var m: RefCounted = Model.new()
	m.last_sent_attack.assign([125,6])
	expect(Hud.snapshot(m).players[0].sent_attack.value==125,"raw telemetry retains >99")
	var view: Node2D = View.new()
	root.size=Vector2i(1000,700)
	root.add_child(view); view.set_process(false); view.set_physics_process(false)
	view.model=m
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PF_REPORT").path_join("sent_99_06.png"))
	m.restart()
	expect(m.last_sent_attack==[0,0] and m.sent_event_id==[0,0] and m.sent_turn==[-1,-1],"new match zero")
	var file: FileAccess = FileAccess.open(OS.get_environment("PF_REPORT").path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("SENT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
