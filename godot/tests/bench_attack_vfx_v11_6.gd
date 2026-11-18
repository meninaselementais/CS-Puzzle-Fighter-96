extends SceneTree
## V11.6 — step cost of the attack presentation under sustained saturation (headless, no drawing).
const Vfx = preload("res://presentation/vfx/attack_vfx.gd")
const ORIGINS: Array[Vector2] = [Vector2(64, 108), Vector2(744, 108)]
class Chain extends RefCounted:
	var chain_count: int = 5
class Fake extends RefCounted:
	var sent_event_id: Array[int] = [0, 0]
	var last_sent_attack: Array[int] = [0, 0]
	var sent_turn: Array[int] = [-1, -1]
	var motion: Array = [Chain.new(), Chain.new()]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var vfx: RefCounted = Vfx.new()
	var fake: RefCounted = Fake.new()
	vfx.step(fake, ORIGINS)
	var ticks := 20000
	var peak := 0
	var start := Time.get_ticks_usec()
	for t in range(ticks):
		if t % 3 == 0:
			for p in range(2):
				fake.sent_turn[p] = t / 60
				fake.last_sent_attack[p] = 30
				fake.sent_event_id[p] += 1
		vfx.step(fake, ORIGINS)
		peak = maxi(peak, vfx.active_items())
	var us := Time.get_ticks_usec() - start
	print("ATTACK_VFX_BENCH ticks=", ticks, " us_per_tick=", float(us) / ticks, " peak_items=", peak, " limit=", 2 * Vfx.MAX_VOLLEYS * Vfx.MAX_ITEMS)
	quit(0 if peak <= 2 * Vfx.MAX_VOLLEYS * Vfx.MAX_ITEMS else 1)
