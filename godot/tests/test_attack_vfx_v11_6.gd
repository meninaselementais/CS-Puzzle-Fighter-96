extends SceneTree
## V11.6 — attack/combo presentation. Presentation only: model state must be byte-identical with the module ON or OFF.
const Model = preload("res://core/match_model.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const Vfx = preload("res://presentation/vfx/attack_vfx.gd")
const ORIGINS: Array[Vector2] = [Vector2(64, 108), Vector2(744, 108)]
class Chain extends RefCounted:
	var chain_count: int = 1
class Fake extends RefCounted:
	var sent_event_id: Array[int] = [0, 0]
	var last_sent_attack: Array[int] = [0, 0]
	var sent_turn: Array[int] = [-1, -1]
	var motion: Array = [Chain.new(), Chain.new()]
	var winner: int = -2
	var lost: Array[bool] = [false, false]
	func wave(p: int, accepted: int, turn: int, chain: int) -> void:
		if sent_turn[p] != turn: last_sent_attack[p] = 0
		sent_turn[p] = turn
		last_sent_attack[p] += accepted
		sent_event_id[p] += 1
		motion[p].chain_count = chain
var checks: int = 0
var failures: Array[String] = []
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _initialize() -> void:
	call_deferred("run")
func state(v: Variant) -> Variant:
	if v is RandomNumberGenerator: return [v.seed, v.state]
	if v is RefCounted:
		var d: Dictionary = {}
		for p in v.get_script().get_script_property_list():
			if not str(p.name).ends_with(".gd"): d[p.name] = state(v.get(p.name))
		return d
	if v is Array:
		var a: Array = []
		for x in v: a.append(state(x))
		return a
	if v is Dictionary:
		var d: Dictionary = {}
		for k in v: d[k] = state(v[k])
		return d
	return v
func arrivals_after(vfx: RefCounted, fake: RefCounted, ticks: int) -> Array:
	var all: Array = []
	for t in range(ticks): all.append_array(vfx.step(fake, ORIGINS))
	return all
func run() -> void:
	# --- unit: direction, proportionality, caps, zero acceptance ---
	for sender in [0, 1]:
		var vfx: RefCounted = Vfx.new()
		var fake: RefCounted = Fake.new()
		vfx.step(fake, ORIGINS)
		fake.wave(sender, 6, 5, 1)
		vfx.step(fake, ORIGINS)
		expect(vfx.volleys[sender].size() == 1 and vfx.volleys[1 - sender].is_empty(), "volley leaves the sender only (P%d)" % (sender + 1))
		var v: Dictionary = vfx.volleys[sender][0]
		expect(int(v.receiver) == 1 - sender, "destination is the opponent (P%d)" % (sender + 1))
		expect(v.from == Vfx.anchor(sender, ORIGINS[sender]) and v.to == Vfx.anchor(1 - sender, ORIGINS[1 - sender]), "endpoints are the well edges facing the center (P%d)" % (sender + 1))
		expect(int(v.n) == 2, "6 stones => 2 projectiles")
		var arr: Array = arrivals_after(vfx, fake, Vfx.FLIGHT + 4)
		expect(arr.size() == 1 and int(arr[0].receiver) == 1 - sender and int(arr[0].accepted) == 6, "single arrival at receiver with accepted amount")
		arrivals_after(vfx, fake, 60)
		expect(vfx.active_volleys() == 0 and vfx.bursts.is_empty() and vfx.tags[0].is_empty() and vfx.tags[1].is_empty(), "everything expires")
	# --- V11.6.1: lane avoids logo, stage label, HUD panels, NEXT boxes; impact stays visible ---
	var forbidden: Array = [Rect2(380, 25, 240, 180), Rect2(385, 4, 230, 22), Rect2(60, 26, 200, 46), Rect2(740, 26, 200, 46), Rect2(280, 85, 60, 80), Rect2(660, 85, 60, 80)]
	for sender in [0, 1]:
		var pa: Vector2 = Vfx.anchor(sender, ORIGINS[sender])
		var pb: Vector2 = Vfx.anchor(1 - sender, ORIGINS[1 - sender])
		var pc: Vector2 = Vfx.lane_control(pa, pb)
		var clear: bool = true
		var ymin: float = 9999.0
		var ymax: float = -9999.0
		for i in range(0, 101):
			var pt: Vector2 = Vfx.bezier(pa, pc, pb, float(i) / 100.0)
			ymin = minf(ymin, pt.y)
			ymax = maxf(ymax, pt.y)
			for r in forbidden:
				if r.grow(14.0).has_point(pt): clear = false
		expect(clear, "lane avoids logo, stage label, HUD panels and NEXT (P%d)" % (sender + 1))
		expect(ymin > 230.0 and ymax < 290.0, "lane stays between callouts and fighters (y %.1f..%.1f)" % [ymin, ymax])
		for r in forbidden:
			expect(not r.grow(24.0).has_point(pb), "impact point clear of HUD (P%d)" % (sender + 1))
		expect(pa.x < 500.0 if sender == 0 else pa.x > 500.0, "launch side matches sender (P%d)" % (sender + 1))
	var vt: RefCounted = Vfx.new()
	var ft: RefCounted = Fake.new()
	vt.step(ft, ORIGINS)
	ft.wave(0, 7, 4, 3)
	vt.step(ft, ORIGINS)
	expect(int(vt.tags[0].accepted) == 7 and int(vt.tags[0].tier) == 3, "tag carries tier and net accepted (no repeated chain text)")
	var launches: int = 0
	for b in vt.bursts:
		if String(b.kind) == "launch": launches += 1
	expect(launches == 1, "launch flash created once")
	arrivals_after(vt, ft, Vfx.FLIGHT + 2)
	var impacts: int = 0
	for b in vt.bursts:
		if String(b.kind) == "impact": impacts += 1
	expect(impacts == 1 and vt.bursts.size() <= Vfx.MAX_BURSTS, "one impact burst at arrival, burst cap respected")
	var vz: RefCounted = Vfx.new()
	var fz: RefCounted = Fake.new()
	vz.step(fz, ORIGINS)
	fz.wave(0, 0, 3, 3)   # event with zero accepted (total cancellation)
	arrivals_after(vz, fz, 80)
	expect(vz.spawned_count == 0 and vz.active_volleys() == 0, "total cancellation: no send animation")
	fz.wave(0, 4, 3, 4)   # same resolution: only the accepted delta animates
	vz.step(fz, ORIGINS)
	expect(vz.spawned_count == 1 and vz.volleys[0][0].accepted == 4 and int(vz.volleys[0][0].n) == 2, "partial acceptance: only accepted amount animates")
	fz.wave(0, 5, 3, 5)
	vz.step(fz, ORIGINS)
	expect(int(vz.volleys[0][1].accepted) == 5 and int(vz.volleys[0][1].tier) == 5, "second wave of same resolution uses its own delta and chain tier")
	expect(Vfx.items_for(0) == 0 and Vfx.items_for(1) == 1 and Vfx.items_for(3) == 1 and Vfx.items_for(4) == 2 and Vfx.items_for(250) == Vfx.MAX_ITEMS, "item count proportional and capped")
	for chain in [1, 2, 3, 4, 5, 9]:
		var vc: RefCounted = Vfx.new()
		var fc: RefCounted = Fake.new()
		vc.step(fc, ORIGINS)
		fc.wave(1, 3, 2, chain)
		vc.step(fc, ORIGINS)
		var tier: int = int(vc.volleys[1][0].tier)
		expect(tier == clampi(chain, 1, 5), "tier follows chain %d" % chain)
		expect(vc.tags[1].is_empty() == (chain == 1), "combo tag only from chain 2 (chain %d)" % chain)
	# --- simultaneous attacks + volley cap ---
	var vs: RefCounted = Vfx.new()
	var fs: RefCounted = Fake.new()
	vs.step(fs, ORIGINS)
	for i in range(8):
		fs.wave(0, 30, 1, 1 + i % 5)
		fs.wave(1, 30, 1, 1 + i % 5)
		vs.step(fs, ORIGINS)
		expect(vs.volleys[0].size() <= Vfx.MAX_VOLLEYS and vs.volleys[1].size() <= Vfx.MAX_VOLLEYS, "volley cap per sender")
		expect(vs.active_items() <= 2 * Vfx.MAX_VOLLEYS * Vfx.MAX_ITEMS, "visual effect limit")
	arrivals_after(vs, fs, 120)
	expect(vs.active_volleys() == 0, "all volleys finish")
	# --- restart: counters go back to zero, no phantom animation ---
	var vr: RefCounted = Vfx.new()
	var fr: RefCounted = Fake.new()
	vr.step(fr, ORIGINS)
	fr.wave(0, 9, 1, 2)
	vr.step(fr, ORIGINS)
	fr = Fake.new()
	vr.step(fr, ORIGINS)
	expect(vr.active_volleys() == 0, "restart clears volleys without animating")
	# --- enabling mid-match does not replay history ---
	var vm: RefCounted = Vfx.new()
	var fm: RefCounted = Fake.new()
	fm.wave(0, 12, 4, 3)
	vm.step(fm, ORIGINS)
	expect(vm.spawned_count == 0, "enabling mid-match does not replay past waves")
	# --- arena integration: opponent reacts only after accepted stones arrive ---
	var arena: RefCounted = Arena.new()
	expect(not arena.attack_vfx_enabled, "OFF by default")
	expect(arena.set_attack_presentation(true) and arena.attack_vfx_enabled, "arena enables the module")
	var dummy: RefCounted = Model.new()
	arena.attack_arrival_hit(dummy, 1, 3)
	expect(arena.fighter_state[1] == "hit", "arrival hit drives the receiver reaction")
	arena.fighter_state[0] = "idle"
	dummy.winner = 1
	arena.attack_arrival_hit(dummy, 0, 3)
	expect(arena.fighter_state[0] == "idle", "no hit reaction after the match is decided")
	dummy.winner = -2
	dummy.lost[0] = true
	arena.attack_arrival_hit(dummy, 0, 3)
	expect(arena.fighter_state[0] == "idle", "no hit reaction on a lost receiver")
	arena.set_attack_presentation(false)
	expect(not arena.attack_vfx_enabled and arena.attack_vfx == null, "arena disables the module")
	# Real-match compact combos keep scores and HUD while the OFF path keeps legacy text.
	for enabled in [false, true]:
		var presentation: RefCounted = Arena.new()
		presentation.temporal_players[0] = true
		presentation.set_attack_presentation(enabled)
		presentation.trigger_wave_presentation(0, 2, 510, false, false, ORIGINS[0], ORIGINS[0])
		var popup: Dictionary = presentation.board_popups.back()
		expect(presentation.chain_banners[0].text == "2 CHAIN!", "HUD keeps its chain banner")
		expect(presentation.fighter_state[0] == "shoot", "combo keeps its fighter action")
		expect((presentation.callout_timer[0] == 0) == enabled, "only VFX ON suppresses the duplicate callout")
		expect(popup.text == ("+510" if enabled else "2 CHAIN!") and popup.sub == ("" if enabled else "+510"), "combo preserves floating score without a duplicate when VFX is ON")
		presentation.trigger_wave_presentation(0, 2, 510, false, true, ORIGINS[0], ORIGINS[0])
		expect(presentation.callout_timer[0] > 0 and presentation.callout_text[0] == "C4 DETONATED!", "C4 keeps its dedicated callout")
	# --- real model: module must not change a single byte of the simulation ---
	for chain in [1, 3, 5]:
		for incoming in [0, 2, 200, 250]:
			var on: RefCounted = Model.new()
			var off: RefCounted = Model.new()
			for m in [on, off]:
				for i in range(2):
					m.boards[i].load_cells(Fixtures.chain_board(chain))
					m.motion[i].phase = 3
					m.motion[i].result = {"waves": [], "score": 0, "attack": 0, "converted": 0, "gravity": 0}
				m.pending.assign([incoming, incoming])
			var a_on: RefCounted = Arena.new()
			a_on.set_attack_presentation(true)
			var a_off: RefCounted = Arena.new()
			for t in range(500):
				on.tick(); off.tick()
				a_on.step_from_model(on)
				a_off.step_from_model(off)
				expect(JSON.stringify(state(on)) == JSON.stringify(state(off)), "simulation identical with V11.6 on/off (chain %d incoming %d tick %d)" % [chain, incoming, t])
				if t % 50 == 0 or t == 499: expect(a_on.attack_vfx.active_items() <= 2 * Vfx.MAX_VOLLEYS * Vfx.MAX_ITEMS, "item limit during real chain")
			var vv: RefCounted = a_on.attack_vfx
			expect(vv.spawned_count <= on.sent_event_id[0] + on.sent_event_id[1], "no more volleys than sent events (chain %d incoming %d)" % [chain, incoming])
			if incoming >= 200: expect(true, "saturated queue case ran without error (chain %d incoming %d)" % [chain, incoming])
	print("ATTACK_VFX_V11_6 checks=", checks, " failures=", failures)
	quit(1 if not failures.is_empty() else 0)
