extends RefCounted
## V11.6 — Acabamento visual de ataques e combos (apresentação apenas).
## Lê somente a telemetria V11.5.1 do modelo (sent_event_id, last_sent_attack, sent_turn, motion[].chain_count).
## Nunca escreve no modelo, não cria pedras na simulação e não altera destino de ataque.
## Cada "salva" (volley) representa o líquido ACEITO pela fila do oponente numa onda; zero aceito = nenhuma animação.

const FLIGHT := 26            # ticks de voo do primeiro projétil
const STAGGER := 2            # ticks entre projéteis da mesma salva
const MAX_VOLLEYS := 3        # salvas simultâneas por remetente
const MAX_ITEMS := 10         # projéteis por salva (representação proporcional e limitada)
const STONES_PER_ITEM := 3    # 1 projétil ~ 3 pedras aceitas (arredonda para cima)
const MAX_BURSTS := 8
const TAG_TTL := 44
const BURST_TTL := 18
const LAUNCH_TTL := 10
## V11.6.1: the volley travels along a low lane between the logo/NEXT/HUD band and the fighters,
## from the sender's well edge to the receiver's well edge (impact stays visible beside the well).
const WELL_WIDTH := 198.0
const WELL_EDGE_GAP := 4.0
const LANE_Y := 164.0           # offset from the well origin y (origin.y + 164 = 272 in the arena)
const LANE_LIFT := 8.0          # gentle arc, keeps the stones inside the lane
const RIM_COLOR := Color(0.03, 0.04, 0.09, 0.92)
const TIER_TAGS := ["", "", "DOUBLE", "TRIPLE", "QUAD", "ACE!"]
const TIER_COLORS := [Color("87e4ff"), Color("87e4ff"), Color("ffe852"), Color("ffc838"), Color("ff9838"), Color("ff5268")]
const TIER_RIMS := [Color("0a2848"), Color("0a2848"), Color("5a4000"), Color("6a3000"), Color("701800"), Color("600818")]

var volleys: Array = [[], []]
var bursts: Array = []
var tags: Array = [{}, {}]
var tick: int = 0
var spawned_count: int = 0
var peak_active_items: int = 0
var last_accepted: Array[int] = [0, 0]
var _primed: bool = false
var _event: Array[int] = [0, 0]
var _total: Array[int] = [0, 0]
var _turn: Array[int] = [-1, -1]
var _arrivals: Array = []

func clear() -> void:
	volleys = [[], []]
	bursts = []
	tags = [{}, {}]
	tick = 0
	_primed = false
	_arrivals = []
	last_accepted = [0, 0]

static func items_for(accepted: int) -> int:
	if accepted <= 0: return 0
	return clampi((accepted + STONES_PER_ITEM - 1) / STONES_PER_ITEM, 1, MAX_ITEMS)

static func tier_for(chain: int) -> int:
	return clampi(chain, 1, 5)

static func anchor(player: int, origin: Vector2) -> Vector2:
	# Borda do poço de cada jogador voltada para o centro, na altura da faixa livre.
	var x: float = origin.x + WELL_WIDTH + WELL_EDGE_GAP if player == 0 else origin.x - WELL_EDGE_GAP
	return Vector2(x, origin.y + LANE_Y)

static func lane_control(a: Vector2, b: Vector2) -> Vector2:
	return Vector2((a.x + b.x) * 0.5, minf(a.y, b.y) - LANE_LIFT * 2.0)

static func bezier(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
	var iu := 1.0 - u
	return a * (iu * iu) + c * (2.0 * iu * u) + b * (u * u)

func active_items() -> int:
	var total := 0
	for p in range(2):
		for v in volleys[p]:
			total += int(v.n)
	return total

func active_volleys() -> int:
	return volleys[0].size() + volleys[1].size()

## Avança 1 tick. Devolve as chegadas deste tick: [{receiver, tier, accepted}].
func step(model, origins: Array) -> Array:
	tick += 1
	_arrivals = []
	for p in range(2):
		var id: int = int(model.sent_event_id[p])
		if not _primed or id < _event[p]:
			# Primeira leitura ou reinício da partida: sincroniza sem animar.
			_event[p] = id
			_total[p] = int(model.last_sent_attack[p])
			_turn[p] = int(model.sent_turn[p])
			volleys[p] = []
			tags[p] = {}
		elif id != _event[p]:
			var total: int = int(model.last_sent_attack[p])
			var turn: int = int(model.sent_turn[p])
			var prev: int = _total[p] if turn == _turn[p] else 0
			var accepted: int = total - prev
			_event[p] = id
			_total[p] = total
			_turn[p] = turn
			if accepted > 0:
				var chain: int = 1
				if model.motion.size() > p and model.motion[p] != null:
					chain = maxi(1, int(model.motion[p].chain_count))
				_spawn(p, accepted, chain, origins)
		_advance(p)
	_primed = true
	if not tags[0].is_empty() or not tags[1].is_empty() or not bursts.is_empty():
		for p in range(2):
			if not tags[p].is_empty():
				tags[p]["age"] = int(tags[p].age) + 1
				if int(tags[p].age) >= TAG_TTL: tags[p] = {}
		var keep: Array = []
		for b in bursts:
			b["age"] = int(b.age) + 1
			if int(b.age) < BURST_TTL: keep.append(b)
		bursts = keep
	peak_active_items = maxi(peak_active_items, active_items())
	return _arrivals

func _spawn(p: int, accepted: int, chain: int, origins: Array) -> void:
	var q: Array = volleys[p]
	if q.size() >= MAX_VOLLEYS:
		var old: Dictionary = q.pop_front()
		if not bool(old.arrived): _land(old)
	var tier := tier_for(chain)
	var o_from: Vector2 = origins[p]
	q.append({
		"from": anchor(p, o_from), "to": anchor(1 - p, origins[1 - p]),
		"age": 0, "n": items_for(accepted), "tier": tier, "accepted": accepted,
		"receiver": 1 - p, "arrived": false})
	last_accepted[p] = accepted
	spawned_count += 1
	if bursts.size() >= MAX_BURSTS: bursts.pop_front()
	bursts.append({"pos": anchor(p, o_from), "tier": tier, "age": BURST_TTL - LAUNCH_TTL, "kind": "launch", "n": items_for(accepted)})
	if tier >= 2:
		tags[p] = {"tier": tier, "age": 0, "pos": o_from + Vector2(98.0, -10.0), "accepted": accepted}

func _land(v: Dictionary) -> void:
	v["arrived"] = true
	_arrivals.append({"receiver": int(v.receiver), "tier": int(v.tier), "accepted": int(v.accepted)})
	if bursts.size() >= MAX_BURSTS: bursts.pop_front()
	bursts.append({"pos": v.to, "tier": int(v.tier), "age": 0, "kind": "impact", "n": int(v.n)})

func _advance(p: int) -> void:
	var keep: Array = []
	for v in volleys[p]:
		v["age"] = int(v.age) + 1
		if int(v.age) >= FLIGHT and not bool(v.arrived): _land(v)
		if int(v.age) < FLIGHT + (int(v.n) - 1) * STAGGER + 1: keep.append(v)
	volleys[p] = keep

func draw(canvas: CanvasItem, font: Font, tex_multi: Texture2D = null, tex_single: Texture2D = null) -> void:
	for p in range(2):
		for v in volleys[p]:
			_draw_volley(canvas, v, tex_multi, tex_single)
	for b in bursts:
		_draw_burst(canvas, b)
	if font == null: return
	for p in range(2):
		if tags[p].is_empty(): continue
		var t: Dictionary = tags[p]
		var tier: int = int(t.tier)
		var age: int = int(t.age)
		var alpha: float = clampf(float(TAG_TTL - age) / 12.0, 0.0, 1.0)
		var size: int = 14 + tier * 2
		var text: String = "%s +%d" % [TIER_TAGS[tier], int(t.accepted)]
		var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos: Vector2 = t.pos + Vector2(-w * 0.5, -float(age) * 0.25)
		var fill: Color = TIER_COLORS[tier]
		var rim: Color = TIER_RIMS[tier]
		fill.a = alpha
		rim.a = alpha
		for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]:
			canvas.draw_string(font, pos + d, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, rim)
		canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, fill)

func _draw_burst(canvas: CanvasItem, b: Dictionary) -> void:
	var k: float = float(b.age) / float(BURST_TTL)
	var tier: int = int(b.tier)
	var col: Color = TIER_COLORS[tier]
	var strength: float = 0.8 + 0.3 * float(int(b.n)) / float(MAX_ITEMS)
	var fade: float = 1.0 - k
	var pos: Vector2 = b.pos
	if String(b.kind) == "launch":
		canvas.draw_circle(pos, (6.0 + 8.0 * k) * strength, Color(col.r, col.g, col.b, 0.35 * fade))
		canvas.draw_arc(pos, 5.0 + 14.0 * k, 0.0, TAU, 20, Color(1, 1, 1, 0.7 * fade), 2.0)
		return
	var reach: float = (14.0 + 26.0 * k) * (0.8 + 0.1 * tier) * strength
	canvas.draw_circle(pos, reach * 0.8, Color(col.r, col.g, col.b, 0.28 * fade))
	canvas.draw_arc(pos, reach, 0.0, TAU, 28, Color(RIM_COLOR.r, RIM_COLOR.g, RIM_COLOR.b, 0.9 * fade), 5.0)
	canvas.draw_arc(pos, reach, 0.0, TAU, 28, Color(col.r, col.g, col.b, 0.95 * fade), 3.0)
	canvas.draw_arc(pos, reach * 0.6, 0.0, TAU, 20, Color(1, 1, 1, 0.8 * fade), 2.0)
	var span: float = (26.0 + 22.0 * strength) * (1.0 - 0.4 * k)
	canvas.draw_line(pos + Vector2(0, -span), pos + Vector2(0, span), Color(col.r, col.g, col.b, 0.75 * fade), 3.0)
	canvas.draw_circle(pos, maxf(0.0, 8.0 * (1.0 - k * 1.6)) * strength, Color(1, 1, 1, 0.9 * fade))
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0 + 0.4
		var dir := Vector2(cos(ang), sin(ang))
		canvas.draw_line(pos + dir * reach * 0.7, pos + dir * (reach * 1.25), Color(1, 1, 1, 0.8 * fade), 2.0)

func _draw_volley(canvas: CanvasItem, v: Dictionary, tex_multi: Texture2D, tex_single: Texture2D) -> void:
	var a: Vector2 = v.from
	var b: Vector2 = v.to
	var ctrl: Vector2 = lane_control(a, b)
	var tier: int = int(v.tier)
	var col: Color = TIER_COLORS[tier]
	var small: bool = int(v.n) <= 2
	var size: float = 16.0 + 1.6 * tier + (4.0 if small else 0.0)
	var tex: Texture2D = tex_multi if (tier >= 3 and tex_multi != null) else tex_single
	var trail_n: int = 6 if small else 4
	for i in range(int(v.n)):
		var local: int = int(v.age) - i * STAGGER
		if local <= 0 or local > FLIGHT: continue
		var u: float = float(local) / float(FLIGHT)
		var e: float = u * u * (3.0 - 2.0 * u)
		var pos: Vector2 = bezier(a, ctrl, b, e)
		for j in range(trail_n, 0, -1):
			var tu: float = maxf(0.0, e - 0.035 * float(j))
			var fade: float = 1.0 - float(j) / float(trail_n + 1)
			canvas.draw_circle(bezier(a, ctrl, b, tu), size * 0.42 * fade + 1.5, Color(col.r, col.g, col.b, 0.42 * fade))
		canvas.draw_circle(pos, size * (1.15 if small else 0.95), Color(col.r, col.g, col.b, 0.34))
		canvas.draw_circle(pos, size * 0.64, RIM_COLOR)
		canvas.draw_arc(pos, size * 0.64, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 1.5)
		if tex != null:
			canvas.draw_texture_rect(tex, Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), false)
		else:
			canvas.draw_circle(pos, size * 0.4, col)
