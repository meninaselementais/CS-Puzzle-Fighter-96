extends RefCounted
## Camada Visual CPS-2 Arcade ('96) — Sprites Reais, Iluminação e Partículas
## Apresentação isolada: não escreve no modelo da partida.

const Board = preload("res://core/board_model.gd")
const Rules = preload("res://core/resolution.gd")
const GemRules = preload("res://core/gem_rules.gd")
const SPRITE_DIR := "res://assets/sprites/"

const STAGES := [
	{"id": "dust2", "name": "DE_DUST2 — BOMBSITE A", "tex": "stage_dust2.png", "accent": Color("ff9d3b"), "well_tint": Color(0.07, 0.05, 0.04, 0.78)},
	{"id": "mirage", "name": "DE_MIRAGE — PALACE COURTYARD", "tex": "stage_mirage.png", "accent": Color("48b2ff"), "well_tint": Color(0.05, 0.06, 0.11, 0.78)},
	{"id": "inferno", "name": "DE_INFERNO — FOUNTAIN & A-SITE", "tex": "stage_inferno.png", "accent": Color("ff6438"), "well_tint": Color(0.06, 0.05, 0.07, 0.78)}
]

var textures: Dictionary = {}
var boot_anchors: Dictionary = {}
var boot_floors: Dictionary = {}
var imported_frames: Dictionary = {}
var fighter_anims: Dictionary = FIGHTER_ANIMS.duplicate(true)
var selected_characters: Array[Dictionary] = []
var fighter_native_side: Array[int] = [0, 1]
var fighter_mirrored: Array[bool] = [false, false]
var stage_index: int = 0
var anim_tick: int = 0

var fighter_state: Array[String] = ["idle", "idle"]
var fighter_timer: Array[int] = [0, 0]
var pending_hit: Array[int] = [0, 0]
var fighter_recoil: Array[float] = [0.0, 0.0]
var fighter_attack_level: Array[int] = [3, 3]
var fighter_flash_ticks: Array[int] = [0, 0]
var fighter_anim_frame: Array[int] = [0, 0]
var fighter_frame_tick: Array[int] = [0, 0]
var fighter_pos_offset: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var fighter_scale_mod: Array[Vector2] = [Vector2.ONE, Vector2.ONE]
var fighter_flash: Array[int] = [0, 0]
var prev_pair_idx: Array[int] = [-1, -1]
var shell_casings: Array[Dictionary] = []

const FIGHTER_ANIMS := {
	0: {
		"idle": [
			{"tex":"sas_idle_0.png","ticks":22,"ofs":Vector2.ZERO,"scale":Vector2.ONE},
			{"tex":"sas_idle_3.png","ticks":8,"ofs":Vector2.ZERO,"scale":Vector2.ONE},
			{"tex":"sas_idle_0.png","ticks":22,"ofs":Vector2.ZERO,"scale":Vector2.ONE}
		],
		"danger": [
			{"tex": "sas_idle_1.png", "ticks": 8, "ofs": Vector2(2, 1), "scale": Vector2(1.03, 0.97)},
			{"tex": "sas_idle_0.png", "ticks": 7, "ofs": Vector2(0, 0), "scale": Vector2(1.0, 1.0)},
			{"tex": "sas_idle_1.png", "ticks": 8, "ofs": Vector2(3, 1), "scale": Vector2(1.03, 0.97)},
			{"tex": "sas_shoot.png", "ticks": 6, "ofs": Vector2(4, 0), "scale": Vector2(1.01, 0.99)}
		],
		"shoot": [
			{"tex": "sas_idle_2.png", "ticks": 4, "ofs": Vector2(1, 1), "scale": Vector2.ONE},
			{"tex": "sas_shoot_0.png", "ticks": 2, "ofs": Vector2(0, 0), "scale": Vector2.ONE, "shell": true, "shot": 1, "muzzle": Vector2(0.78,0.50)},
			{"tex": "sas_idle_2.png", "ticks": 3, "ofs": Vector2(-1, 0), "scale": Vector2.ONE},
			{"tex": "sas_shoot_1.png", "ticks": 2, "ofs": Vector2(0, 0), "scale": Vector2.ONE, "shell": true, "shot": 2, "muzzle": Vector2(0.73,0.49)},
			{"tex": "sas_idle_2.png", "ticks": 3, "ofs": Vector2(-1, 0), "scale": Vector2.ONE},
			{"tex": "sas_shoot.png", "ticks": 2, "ofs": Vector2(0, 0), "scale": Vector2.ONE, "shell": true, "shot": 3, "muzzle": Vector2(0.78,0.50)},
			{"tex": "sas_idle_2.png", "ticks": 4, "ofs": Vector2(-1, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_0.png", "ticks": 8, "ofs": Vector2(0, 0), "scale": Vector2.ONE}
		],
		"grenade": [
			{"tex": "sas_idle_1.png", "ticks": 4, "ofs": Vector2(-3, 1), "scale": Vector2.ONE},
			{"tex": "sas_grenade.png", "ticks": 6, "ofs": Vector2(-4, 0), "scale": Vector2.ONE},
			{"tex": "sas_grenade.png", "ticks": 2, "ofs": Vector2(3, -1), "scale": Vector2.ONE, "release": true, "hand": Vector2(0.11,0.24)},
			{"tex": "sas_idle_1.png", "ticks": 6, "ofs": Vector2(4, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_0.png", "ticks": 12, "ofs": Vector2(0, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_0.png", "ticks": 4, "ofs": Vector2(0, 0), "scale": Vector2.ONE}
		],
		"hit": [
			{"tex": "sas_hit.png", "ticks": 4, "ofs": Vector2(-3, -1), "scale": Vector2.ONE, "flash": 1},
			{"tex": "sas_hit.png", "ticks": 5, "ofs": Vector2(-10, -2), "scale": Vector2.ONE, "flash": 2},
			{"tex": "sas_hit.png", "ticks": 5, "ofs": Vector2(-7, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_1.png", "ticks": 6, "ofs": Vector2(-2, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_0.png", "ticks": 8, "ofs": Vector2(0, 0), "scale": Vector2.ONE}
		],
		"victory": [
			{"tex": "sas_idle_0.png", "ticks": 8, "ofs": Vector2(0, 0), "scale": Vector2.ONE},
			{"tex": "sas_idle_1.png", "ticks": 6, "ofs": Vector2(0, 1), "scale": Vector2.ONE},
			{"tex": "sas_win_0.png", "ticks": 12, "ofs": Vector2(0, -2), "scale": Vector2.ONE},
			{"tex": "sas_win_0.png", "ticks": 20, "ofs": Vector2(0, 0), "scale": Vector2.ONE}
		],
		"defeat": [
			{"tex": "sas_hit.png", "ticks": 4, "ofs": Vector2(-6, 0), "scale": Vector2.ONE, "flash": 1},
			{"tex": "sas_hit.png", "ticks": 10, "ofs": Vector2(-10, 2), "scale": Vector2.ONE, "flash": 2},
			{"tex": "sas_hit.png", "ticks": 22, "ofs": Vector2(-8, 4), "scale": Vector2.ONE}
		]
	},
	1: {
		"idle": [
			{"tex": "phoenix_v9_idle.png", "ticks": 16, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_settle.png", "ticks": 12, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 16, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_blink.png", "ticks": 4, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 12, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"danger": [
			{"tex": "phoenix_v9_ready.png", "ticks": 9, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_aim.png", "ticks": 7, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_ready.png", "ticks": 9, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 7, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"shoot": [
			{"tex": "phoenix_v9_ready.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_aim.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_recoil_a.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "shell": true, "shot": 1, "muzzle": Vector2(0.05,0.44)},
			{"tex": "phoenix_v9_aim.png", "ticks": 3, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_recoil_b.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "shell": true, "shot": 2, "muzzle": Vector2(0.05,0.49)},
			{"tex": "phoenix_v9_aim.png", "ticks": 3, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_recoil_a.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "shell": true, "shot": 3, "muzzle": Vector2(0.05,0.44)},
			{"tex": "phoenix_v9_recover.png", "ticks": 5, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_settle.png", "ticks": 5, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 6, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"grenade": [
			{"tex": "phoenix_v9_ready.png", "ticks": 4, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_windup.png", "ticks": 6, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_release.png", "ticks": 2, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "release": true, "hand": Vector2(0.08,0.34)},
			{"tex": "phoenix_v9_follow.png", "ticks": 6, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_recover.png", "ticks": 8, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_settle.png", "ticks": 8, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 4, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"hit": [
			{"tex": "phoenix_v9_hit.png", "ticks": 4, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "flash": 1},
			{"tex": "phoenix_v9_hurt.png", "ticks": 5, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "flash": 2},
			{"tex": "phoenix_v9_hurt.png", "ticks": 5, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_recover.png", "ticks": 6, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_idle.png", "ticks": 8, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"victory": [
			{"tex": "phoenix_v9_settle.png", "ticks": 8, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_ready.png", "ticks": 6, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_win.png", "ticks": 12, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_win.png", "ticks": 20, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		],
		"defeat": [
			{"tex": "phoenix_v9_hit.png", "ticks": 4, "ofs": Vector2.ZERO, "scale": Vector2.ONE, "flash": 1},
			{"tex": "phoenix_v9_stagger.png", "ticks": 10, "ofs": Vector2.ZERO, "scale": Vector2.ONE},
			{"tex": "phoenix_v9_defeat.png", "ticks": 22, "ofs": Vector2.ZERO, "scale": Vector2.ONE}
		]
	}
}
# Only the baked muzzle flare beyond the barrel is omitted; the authored character stays intact.
const BAKED_FLARES := {
	"sas_shoot_0.png": Rect2i(319, 207, 93, 77),
	"sas_shoot_1.png": Rect2i(249, 192, 95, 100),
	"sas_shoot.png": Rect2i(314, 207, 92, 77),
	"phoenix_shoot.png": Rect2i(0, 127, 111, 82)
}

var callout_text: Array[String] = ["", ""]
var callout_sub: Array[String] = ["", ""]
var callout_timer: Array[int] = [0, 0]

var projectiles: Array[Dictionary] = []
var vfx_sprites: Array[Dictionary] = []
var gem_sparks: Array[Dictionary] = []
var board_popups: Array[Dictionary] = []
var combo_flashes: Array[Dictionary] = []
var impact_flashes: Array[Dictionary] = []
var chain_banners: Array[Dictionary] = [{}, {}]
var wave_queues: Array = [[], []]
var active_wave: Array = [{}, {}]
var visual_cells_override: Array = [PackedInt32Array(), PackedInt32Array()]
var visual_powers_override: Array = [[], []]
var prev_pair_snapshot: Array = [null, null]

var cell_drop_y: Array = [PackedFloat32Array(), PackedFloat32Array()]
var cell_squash: Array = [PackedFloat32Array(), PackedFloat32Array()]
var prev_powers: Array = [[], []]
var power_flash_ticks: Array[int] = [0, 0]
var screen_shake_timer: int = 0
var screen_shake_duration: int = 0
var screen_shake_mag: float = 0.0

var prev_scores: Array[int] = [0, 0]
var prev_pending: Array[int] = [0, 0]
var prev_cells: Array = [PackedInt32Array(), PackedInt32Array()]
var wins: Array[int] = [0, 0]
var last_winner_recorded: int = -2
# Partida temporal lê a simulação; o showcase explícito mantém seu replay independente.
var temporal_players: Array[bool] = [false, false]
var temporal_origins: Array[Vector2] = [Vector2(64,108), Vector2(744,108)]
var connection_age: Array = [PackedInt32Array(), PackedInt32Array()]
var active_halo: Array[bool] = [false, false]
var union_view: Array = [[], []]
var union_age: Array[int] = [10, 10]
var contour_textures: Dictionary = {}
# V10.3.4 — animação interna das Power Gems por célula (A -> B -> C -> D -> C -> B -> A).
const POWER_FACET_SEQUENCE := ["a", "b", "c", "d", "c", "b", "a"]
const POWER_FACET_TICKS := 8
var power_facet_age: Array = [PackedInt32Array(), PackedInt32Array()]
var prev_power_facet_cells: Array = [PackedInt32Array(), PackedInt32Array()]
var prev_power_facet_regions: Array = [{}, {}]

func _init() -> void:
	init_cell_arrays()
	load_all_textures()

func init_cell_arrays() -> void:
	for i in range(2):
		var dy := PackedFloat32Array()
		dy.resize(84)
		dy.fill(0.0)
		cell_drop_y[i] = dy
		var sq := PackedFloat32Array()
		sq.resize(84)
		sq.fill(0.0)
		cell_squash[i] = sq
		prev_powers[i] = []
		power_flash_ticks[i] = 0
		var ages: PackedInt32Array = PackedInt32Array()
		ages.resize(84)
		ages.fill(-1)
		connection_age[i] = ages
		var fa := PackedInt32Array()
		fa.resize(84)
		fa.fill(-1)
		power_facet_age[i] = fa
		prev_power_facet_cells[i] = PackedInt32Array()
		prev_power_facet_regions[i] = {}

func load_tex(file_name: String) -> Texture2D:
	if textures.has(file_name):
		return textures[file_name]
	var global_path := ProjectSettings.globalize_path(SPRITE_DIR + file_name)
	var img: Image
	if file_name.ends_with(".svg"):
		img = Image.new()
		if img.load_svg_from_string(FileAccess.get_file_as_string(global_path)) != OK: return null
	else:
		img = Image.load_from_file(global_path)
	if img == null or img.is_empty():
		return null
	if file_name.begins_with("sas_") or file_name.begins_with("phoenix_"):
		var w := img.get_width()
		var h := img.get_height()
		var min_bx := w
		var max_bx := 0
		for y in range(maxi(0, h - 42), h):
			for x in range(w):
				if img.get_pixel(x, y).a > 0.25:
					if x < min_bx: min_bx = x
					if x > max_bx: max_bx = x
		boot_anchors[file_name] = float(min_bx + max_bx) * 0.5 if min_bx <= max_bx else float(w) * 0.5
		boot_floors[file_name] = float(img.get_used_rect().end.y)
		if imported_frames.has(file_name):
			boot_anchors[file_name] = float(imported_frames[file_name].anchor[0])
			boot_floors[file_name] = float(imported_frames[file_name].anchor[1])
	var tex := ImageTexture.create_from_image(img)
	textures[file_name] = tex
	return tex

func configure_characters(ids: Array[String]) -> void:
	var catalog = load("res://core/character_catalog.gd")
	selected_characters.clear()
	for player in range(2):
		var character: Dictionary = catalog.find(ids[player])
		selected_characters.append(character)
		var native_side := 0 if character.team == "CT" else 1
		fighter_native_side[player] = native_side
		fighter_mirrored[player] = player != native_side
		fighter_anims[player] = FIGHTER_ANIMS[native_side].duplicate(true)
		if character.temporary:
			for state in fighter_anims[player]:
				for keyframe in fighter_anims[player][state]:
					keyframe.tex = character.sprite
					if keyframe.has("muzzle"): keyframe.muzzle = Vector2(0.87 if native_side == 0 else 0.13,0.56)
					if keyframe.has("hand"): keyframe.hand = Vector2(0.55 if native_side == 0 else 0.45,0.6)
			load_tex(character.sprite)
			boot_anchors[character.sprite] = 256.0
			boot_floors[character.sprite] = 496.0
	reset_state()

func load_all_textures() -> void:
	imported_frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/phoenix_v9_frames.json"))
	for name in imported_frames: load_tex(name)
	var files := [
		"stage_dust2.png", "stage_mirage.png", "stage_inferno.png",
		"sas_idle.png", "sas_shoot.png", "sas_grenade.png", "sas_hit.png",
		"sas_idle_0.png", "sas_idle_1.png", "sas_idle_2.png", "sas_idle_3.png",
		"sas_shoot_0.png", "sas_shoot_1.png", "sas_win_0.png",
		"phoenix_idle.png", "phoenix_shoot.png", "phoenix_grenade.png", "phoenix_hit.png",
		"phoenix_idle_0.png", "phoenix_idle_1.png", "phoenix_idle_2.png", "phoenix_idle_3.png",
		"hud_logo.png", "hud_vs.png", "hud_v.png",
		"gem_diamond.png", "gem_c4_0.png", "gem_c4_1.png",
		"vfx_muzzle_sas.png", "vfx_muzzle_phoenix.png", "vfx_grenade.png",
		"vfx_explosion.png", "vfx_shatter.png", "vfx_shockwave.png", "vfx_lightning.png"
	]
	for f_idx in range(6):
		files.append("vfx_explosion_%d.png" % f_idx)
		files.append("vfx_shatter_%d.png" % f_idx)
	for c in range(1, 6):
		for v in range(3):
			files.append("vfx_shard_%d_%d.png" % [c, v])
	for c in range(1, 5):
		files.append("gem_normal_%d.png" % c)
		files.append("gem_crash_%d.png" % c)
		files.append("power_crystal_%d.png" % c)
		for cnt in range(1, 6):
			files.append("gem_counter_%d_%d.png" % [c, cnt])
	for f in files:
		load_tex(f)

func cycle_stage(step: int = 1) -> void:
	stage_index = posmod(stage_index + step, STAGES.size())

func set_stage(index: int) -> void:
	stage_index = clampi(index, 0, STAGES.size() - 1)

func reset_state() -> void:
	fighter_state = ["idle", "idle"]
	fighter_timer = [0, 0]
	pending_hit = [0, 0]
	fighter_recoil = [0.0, 0.0]
	fighter_attack_level = [3, 3]
	fighter_flash_ticks = [0, 0]
	fighter_anim_frame = [0, 0]
	fighter_frame_tick = [0, 0]
	fighter_pos_offset = [Vector2.ZERO, Vector2.ZERO]
	fighter_scale_mod = [Vector2.ONE, Vector2.ONE]
	fighter_flash = [0, 0]
	prev_pair_idx = [-1, -1]
	shell_casings.clear()
	gem_sparks.clear()
	board_popups.clear()
	combo_flashes.clear()
	impact_flashes.clear()
	chain_banners = [{}, {}]
	wave_queues = [[], []]
	active_wave = [{}, {}]
	visual_cells_override = [PackedInt32Array(), PackedInt32Array()]
	visual_powers_override = [[], []]
	prev_pair_snapshot = [null, null]
	init_cell_arrays()
	screen_shake_timer = 0
	screen_shake_mag = 0.0
	callout_text = ["", ""]
	callout_sub = ["", ""]
	callout_timer = [0, 0]
	projectiles.clear()
	vfx_sprites.clear()
	prev_scores = [0, 0]
	prev_pending = [0, 0]
	prev_cells = [PackedInt32Array(), PackedInt32Array()]
	last_winner_recorded = -2
	temporal_players = [false, false]
	active_halo = [false, false]
	union_view = [[], []]
	union_age = [10, 10]

func has_visual_override(player: int) -> bool:
	var arr: PackedInt32Array = visual_cells_override[player]
	return arr.size() == 84

func get_visual_cells(player: int, fallback: PackedInt32Array) -> PackedInt32Array:
	var arr: PackedInt32Array = visual_cells_override[player]
	return arr if arr.size() == 84 else fallback

func get_visual_powers(player: int, fallback: Array) -> Array:
	if temporal_players[player] and union_age[player] < 10:
		return union_view[player]
	var arr: PackedInt32Array = visual_cells_override[player]
	return visual_powers_override[player] if arr.size() == 84 else fallback

# V10.3.4 — fase de facetas internas de uma célula de Power Gem.
# age<0 -> fase 0 (a, arte base); 0..7->a, 8..15->b, 16..23->c, 24..31->d,
# 32..39->c, 40..47->b, 48+->a (assentado). Blocos de 8 quadros, 7 fases.
func power_facet_phase(player: int, idx: int) -> int:
	if power_facet_age[player].size() != 84:
		return 0
	var age: int = power_facet_age[player][idx]
	if age < 0:
		return 0
	return mini(floori(float(age) / float(POWER_FACET_TICKS)), POWER_FACET_SEQUENCE.size() - 1)

# O descritor MAME reinicia células cuja região muda, inclusive células antigas.
# O estágio 3x2 da união e o estágio final 5x2 têm identidades distintas.
func update_power_facets_for(model: RefCounted, player: int) -> void:
	var rects: Array = get_visual_powers(player, model.boards[player].power_gems)
	var cur: PackedInt32Array = PackedInt32Array()
	var regions: Dictionary = {}
	for rect in rects:
		for idx in model.boards[player].indices(rect):
			cur.append(idx)
			regions[idx] = [rect, model.boards[player].cells[idx] & 7]
	cur.sort()
	var prev: PackedInt32Array = prev_power_facet_cells[player]
	var ages: PackedInt32Array = power_facet_age[player]
	for idx in range(84):
		if cur.has(idx):
			if prev.has(idx) and prev_power_facet_regions[player].get(idx) == regions[idx]:
				ages[idx] = mini(ages[idx] + 1, POWER_FACET_TICKS * 6)
			else:
				ages[idx] = 0
		else:
			ages[idx] = -1
	prev_power_facet_cells[player] = cur
	prev_power_facet_regions[player] = regions

func is_cell_hidden_by_flash(player: int, idx: int) -> bool:
	var cx := idx % 6
	var cy := idx / 6
	for cf in combo_flashes:
		if int(cf["player"]) == player and int(cf["x"]) == cx and int(cf["y"]) == cy:
			return true
	return false

func trigger_screen_shake(ticks: int, mag: float) -> void:
	screen_shake_timer = maxi(screen_shake_timer, ticks)
	screen_shake_duration = screen_shake_timer
	screen_shake_mag = maxf(screen_shake_mag, mag)

func get_screen_shake_offset() -> Vector2:
	if screen_shake_timer <= 0:
		return Vector2.ZERO
	var envelope := float(screen_shake_timer) / float(maxi(1, screen_shake_duration))
	var sx := sin(float(anim_tick) * 2.3) * screen_shake_mag * envelope
	var sy := cos(float(anim_tick) * 3.1) * screen_shake_mag * envelope * 0.75
	return Vector2(roundf(sx), roundf(sy))

func get_cell_visual_offset(player: int, idx: int) -> float:
	if temporal_players[player]: return 0.0
	var arr: PackedFloat32Array = cell_drop_y[player]
	return -arr[idx] if idx >= 0 and idx < arr.size() else 0.0

func get_cell_squash_scale(player: int, idx: int) -> Vector2:
	if temporal_players[player]: return Vector2.ONE
	var arr: PackedFloat32Array = cell_squash[player]
	if idx < 0 or idx >= arr.size() or arr[idx] <= 0.001:
		return Vector2.ONE
	var s := arr[idx]
	var wave := sin(s * PI)
	return Vector2(1.0 + 0.17 * wave, 1.0 - 0.14 * wave)

func set_fighter_state(player: int, new_state: String, duration: int = 0, restart: bool = false) -> void:
	if fighter_state[player] != new_state or restart:
		fighter_state[player] = new_state
		fighter_anim_frame[player] = 0
		fighter_frame_tick[player] = 0
		fighter_timer[player] = duration
		fighter_flash[player] = 0
		fighter_flash_ticks[player] = 0
		vfx_sprites = vfx_sprites.filter(func(f): return int(f.get("muzzle_owner", -1)) != player)
		if new_state in ["victory", "defeat"]: pending_hit[player] = 0
		if new_state in ["shoot", "grenade", "hit"]:
			var length := 0
			for keyframe in fighter_anims[player][new_state]: length += int(keyframe.ticks)
			fighter_timer[player] = maxi(duration, length)
		enter_fighter_frame(player)

func enter_fighter_frame(player: int) -> void:
	var kf: Dictionary = fighter_anims[player][fighter_state[player]][fighter_anim_frame[player]]
	var flash := int(kf.get("flash", 0))
	if flash > 0:
		fighter_flash[player] = flash
		fighter_flash_ticks[player] = 3
	if bool(kf.get("shell", false)) and int(kf.get("shot", 1)) <= mini(fighter_attack_level[player], 3):
		fighter_recoil[player] = 2.0 + float(mini(fighter_attack_level[player], 3))
		spawn_shell_casing(player)
		spawn_fighter_projectile(player, false, kf.get("muzzle", Vector2(0.84,0.5)))
	if bool(kf.get("release", false)):
		spawn_fighter_projectile(player, true, kf["hand"])

func attachment_position(player: int, attachment: Vector2) -> Vector2:
	var rect := fighter_draw_rect(player)
	if fighter_mirrored[player]: attachment.x = 1.0 - attachment.x
	return rect.position + rect.size * attachment

func spawn_fighter_projectile(player: int, grenade: bool, attachment: Vector2) -> void:
	var start_pos := attachment_position(player, attachment)
	var target_pos := Vector2(586, 396) if player == 0 else Vector2(414, 396)
	if not grenade:
		vfx_sprites = vfx_sprites.filter(func(f): return int(f.get("muzzle_owner", -1)) != player)
		var muzzle_tex := "vfx_muzzle_sas.png" if fighter_native_side[player] == 0 else "vfx_muzzle_phoenix.png"
		var strength := 0.17 + float(mini(fighter_attack_level[player],3)) * 0.025
		spawn_vfx(muzzle_tex, start_pos, strength, strength * 0.55, 2)
		vfx_sprites[-1]["muzzle_owner"] = player
		vfx_sprites[-1]["attachment"] = attachment
	projectiles.append({
		"kind": "he" if grenade else "tracer", "owner": player,
		"x": start_pos.x, "y": start_pos.y,
		"tx": target_pos.x, "ty": target_pos.y + (8.0 if grenade else 0.0),
		"t": 0.0, "speed": 1.0 / 26.0 if grenade else 0.20,
		"born_tick": anim_tick, "level": fighter_attack_level[player],
		"source_frame": fighter_anim_frame[player]
	})

static func projectile_position(proj: Dictionary) -> Vector2:
	var t := clampf(float(proj["t"]), 0.0, 1.0)
	var position := Vector2(lerpf(float(proj.x),float(proj.tx),t), lerpf(float(proj.y),float(proj.ty),t))
	if proj.kind == "he": position.y -= 4.0 * t * (1.0 - t) * 72.0
	return position

func grenade_impact(proj: Dictionary) -> void:
	var pos := Vector2(float(proj.tx),float(proj.ty))
	var level := int(proj.get("level",1))
	var size := 0.37 + float(mini(level,5)) * 0.025
	spawn_vfx("vfx_explosion.png",pos,0.18,size,20)
	spawn_vfx("vfx_shockwave.png",pos,0.12,size,12,Color("ffe052"))
	if level >= 5:
		spawn_vfx("vfx_lightning.png",pos,0.16,0.34,10,Color("ffbd68"))
		trigger_screen_shake(6,1.5)
	for i in range(6 + mini(level,5)):
		var angle := float(i) * TAU / float(6 + mini(level,5))
		gem_sparks.append({"x":pos.x,"y":pos.y,"vx":cos(angle)*3.6,"vy":sin(angle)*3.6-2.0,
			"color":Color("ffc060"),"color_idx":5,"variant":i%3,"size":3.0,
			"ttl":20+i%4,"max_ttl":20+i%4,"rotation":angle,"spin":0.17})

func spawn_shell_casing(player: int) -> void:
	var port := attachment_position(player,Vector2(0.52,0.53) if player==0 else Vector2(0.58,0.46))
	var sx := port.x
	var sy := port.y
	var vx := -2.6 - float(anim_tick % 3) * 0.55 if player == 0 else 2.6 + float(anim_tick % 3) * 0.55
	var vy := -4.2 - float(anim_tick % 2) * 0.8
	shell_casings.append({
		"x": sx,
		"y": sy,
		"vx": vx,
		"vy": vy,
		"rot": 0.0,
		"vrot": 0.35 if player == 0 else -0.35,
		"ttl": 34
	})

func spawn_vfx(tex_name: String, pos: Vector2, start_scale: float, end_scale: float, ttl: int, modulate_col: Color = Color.WHITE, rot_speed: float = 0.0) -> void:
	vfx_sprites.append({
		"tex": tex_name,
		"pos": pos,
		"vel": Vector2.ZERO,
		"start_scale": start_scale,
		"end_scale": end_scale,
		"ttl": ttl,
		"max_ttl": ttl,
		"color": modulate_col,
		"rot": 0.0,
		"rot_speed": rot_speed,
		"born_tick": anim_tick
	})

func spawn_board_popup(pos: Vector2, text: String, subtext: String, col: Color) -> void:
	board_popups.append({
		"pos": pos,
		"vel": Vector2(0.0, -1.35),
		"text": text,
		"sub": subtext,
		"color": col,
		"ttl": 38,
		"max_ttl": 38
	})

func set_chain_banner(player: int, board_origin: Vector2, chain_num: int, is_c4: bool = false) -> void:
	var label := "C4 BLAST!" if is_c4 else ("%d CHAIN!" % chain_num)
	chain_banners[player] = {
		"origin": board_origin,
		"chain": chain_num,
		"text": label,
		"is_c4": is_c4,
		"ttl": 44,
		"max_ttl": 44
	}

func spawn_board_explosion(board_origin: Vector2, cell_x: int, cell_y: int, color_code: int, is_power: bool = false, chain_num: int = 1, is_c4: bool = false, large_effect: bool = true) -> void:
	if cell_y < 2:
		return
	var center := board_origin + Vector2(cell_x * 32 + 16, (cell_y - 2) * 32 + 16)
	var palette := {
		1: Color("68c0ff"),
		2: Color("ffe868"),
		3: Color("68ff9c"),
		4: Color("ff687c"),
		5: Color("ff8c42")
	}
	var c_idx := clampi(color_code, 1, 5)
	if is_c4 and color_code == 5:
		c_idx = 5
	var tint: Color = palette.get(c_idx, Color.WHITE)
	var chain_boost := clampf(float(chain_num - 1) * 0.06, 0.0, 0.28)
	# ESTÁGIO 2: Flash luminoso rápido de impacto + iluminação localizada na grade
	impact_flashes.append({
		"pos": center,
		"color": tint,
		"radius": 24.0 + (8.0 if is_power else 0.0) + float(chain_num) * 3.0,
		"ttl": 5,
		"max_ttl": 5
	})
	# ESTÁGIO 3: Animação quadro a quadro de explosão e despedaçamento cristalino (6 quadros reais)
	spawn_vfx("vfx_shatter.png", center, 0.15, (0.32 if is_power and large_effect else 0.24) + chain_boost*0.25, 16 + mini(chain_num * 2, 8), tint, 0.0)
	if large_effect and (chain_num >= 2 or is_power or is_c4):
		spawn_vfx("vfx_shockwave.png", center, 0.12, (0.34 if not is_power else 0.52) + chain_boost, 14, tint.lightened(0.38), 0.0)
	if large_effect and (is_power or chain_num >= 3 or is_c4):
		var exp_col := Color("ffae52") if is_c4 else tint.lightened(0.45)
		spawn_vfx("vfx_explosion.png", center, 0.20 + chain_boost * 0.4, (0.42 if not is_power else 0.56) + chain_boost, 18 + mini(chain_num * 2, 8), exp_col, 0.0)
	if is_c4 and color_code == 5:
		spawn_vfx("vfx_shockwave.png", center, 0.18, 0.82, 18, Color("ff4838"), 0.0)
		spawn_vfx("vfx_lightning.png", center, 0.20, 0.55, 16, Color("ffe868"), 0.05)
	# ESTÁGIO 4 & 5: Fragmentação em cristais pixel art (vfx_shard) com gravidade e dissipação cintilante
	var shard_count := 3 + mini(chain_num, 3) + (2 if is_power and large_effect else 0)
	for s_idx in range(shard_count):
		var ang := float(s_idx) * TAU / float(shard_count) + float((cell_x * 7 + cell_y * 13 + chain_num * 5) % 11) * 0.14
		var spd := 2.2 + float((s_idx + cell_x) % 3) * 1.15 + (1.1 if is_power else 0.0) + float(mini(chain_num, 5)) * 0.22
		var max_t := 22 + (s_idx % 6) + mini(chain_num * 2, 8)
		var variant := 0 if (is_power and s_idx % 2 == 0) else (s_idx % 3)
		gem_sparks.append({
			"x": center.x,
			"y": center.y,
			"vx": cos(ang) * spd,
			"vy": sin(ang) * spd - 2.1,
			"size": 5.5 if variant == 0 else (4.5 if variant == 1 else 3.5),
			"color": tint,
			"color_idx": c_idx,
			"variant": variant,
			"ttl": max_t,
			"max_ttl": max_t,
			"rotation": ang, "spin": (-0.13 if s_idx % 2 == 0 else 0.17),
			"base_scale": (0.72 if is_power and large_effect and s_idx<2 else 0.42)+float(mini(chain_num,5))*0.025,
			"delay": s_idx%3,
			"bounds": Rect2(board_origin-Vector2(8,12),Vector2(208,412))
		})

func trigger_wave_presentation(player: int, chain_num: int, wave_score: int, has_power: bool, is_c4: bool, board_origin: Vector2, popup_pos: Vector2, prepared: bool = false) -> void:
	fighter_attack_level[player] = 5 if is_c4 else clampi(chain_num,1,5)
	# FASE 3 & FASE 4: Progressão clara de 1X a 5X+ CHAIN e sincronização com SAS e Phoenix
	if is_c4:
		set_chain_banner(player, board_origin, chain_num, true)
		trigger_action(player, "grenade", 38, "C4 DETONATED!", "+%d PTS" % wave_score, prepared)
		trigger_action(1 - player, "hit", 30)
		trigger_screen_shake(12, 3.0)
		spawn_board_popup(popup_pos, "C4 CLEAR!", "+%d" % wave_score, Color("ff6852"))
	elif chain_num <= 1:
		var title := "POWER GEM BLAST!" if has_power else ("M4A1-S BURST!" if player == 0 else "AK-47 BARRAGE!")
		trigger_action(player, "shoot", 24, title, "+%d PTS" % wave_score, prepared)
		trigger_action(1 - player, "hit", 18)
		if has_power:
			trigger_screen_shake(5, 1.0)
		spawn_board_popup(popup_pos, "+%d" % wave_score, "POWER!" if has_power else "", Color("68ff9c"))
	elif chain_num == 2:
		set_chain_banner(player, board_origin, 2, false)
		trigger_action(player, "shoot", 28, "2X CHAIN COMBO!", "+%d PTS" % wave_score, prepared)
		trigger_action(1 - player, "hit", 22)
		trigger_screen_shake(4, 0.8)
		spawn_board_popup(popup_pos, "2 CHAIN!", "+%d" % wave_score, Color("ffe852"))
	elif chain_num == 3:
		set_chain_banner(player, board_origin, 3, false)
		var sub := "SUPPRESSED BARRAGE" if player == 0 else "KALASHNIKOV STORM"
		trigger_action(player, "shoot", 32, "3X CHAIN COMBO!", sub + " +%d" % wave_score, prepared)
		trigger_action(1 - player, "hit", 26)
		trigger_screen_shake(6, 1.3)
		spawn_board_popup(popup_pos, "3 CHAIN!", "+%d" % wave_score, Color("ffc838"))
	elif chain_num == 4:
		set_chain_banner(player, board_origin, 4, false)
		trigger_action(player, "grenade", 36, "4X CHAIN COMBO!", "HE GRENADE STRIKE +%d" % wave_score, prepared)
		trigger_action(1 - player, "hit", 32)
		trigger_screen_shake(8, 1.8)
		spawn_board_popup(popup_pos, "4 CHAIN!", "+%d" % wave_score, Color("ff9838"))
	else:
		set_chain_banner(player, board_origin, chain_num, false)
		trigger_action(player, "grenade", 42, "%dX CHAIN FINALE!" % chain_num, "MAXIMUM DAMAGE +%d" % wave_score, prepared)
		trigger_action(1 - player, "hit", 38)
		trigger_screen_shake(10, 2.5)
		spawn_board_popup(popup_pos, "%d CHAIN!!" % chain_num, "+%d" % wave_score, Color("ff5268"))

func enqueue_visual_waves(player: int, pre_resolve_cells: PackedInt32Array, board_origin: Vector2, decrement_counters: bool = true) -> int:
	# shortcut: reconstrução visual em cópia; a cronologia completa da CPS-2 continua fora desta camada.
	# FASE 5: Reconstrói cada onda da cadeia em um tabuleiro-sombra sem alterar o núcleo lógico!
	var sim := Board.new()
	sim.load_cells(pre_resolve_cells)
	if decrement_counters:
		Rules.advance_counters(sim)
	Rules.form_powers(sim)
	Rules.gravity(sim)
	var scored := Board.new()
	scored.load_cells(pre_resolve_cells)
	var events: Array = Rules.resolve(scored, decrement_counters).waves
	var steps: Array[Dictionary] = []
	for chain in range(1, 85):
		Rules.form_powers(sim)
		var cells_before: PackedInt32Array = sim.cells.duplicate()
		var powers_before: Array = sim.power_gems.duplicate()
		var has_diamond := false
		for idx in range(84):
			if GemRules.is_diamond(sim.cells[idx]):
				has_diamond = true
				break
		if has_diamond:
			var dwave: Dictionary = Rules.diamond_wave(sim, chain)
			if dwave.is_empty():
				break
			var removed_list: Array[Dictionary] = []
			for idx in range(12, 84):
				if cells_before[idx] != 0 and sim.cells[idx] == 0:
					var code_b: int = cells_before[idx]
					removed_list.append({
						"idx": idx,
						"x": idx % 6,
						"y": idx / 6,
						"code": code_b,
						"color": 5 if GemRules.is_diamond(code_b) else GemRules.color(code_b),
						"is_power": GemRules.kind(code_b) == GemRules.Kind.POWER,
						"is_c4": true
					})
			var cells_mid: PackedInt32Array = sim.cells.duplicate()
			Rules.gravity(sim)
			Rules.form_powers(sim)
			var cells_after: PackedInt32Array = sim.cells.duplicate()
			var powers_after: Array = sim.power_gems.duplicate()
			steps.append({
				"chain": chain,
				"origin": board_origin,
				"cells_before": cells_before,
				"powers_before": powers_before,
				"cells_after": cells_after,
				"powers_after": powers_after,
				"removed": removed_list,
				"drops": gravity_offsets(cells_mid, cells_after),
			"cells_mid": cells_mid,
			"powers_mid": remaining_powers(powers_before, removed_list),
				"score": int(dwave.get("score", 1000)),
				"has_power": not powers_before.is_empty() and removed_list.any(func(r): return r.is_power),
				"is_c4": true
			})
			continue
		var groups: Array = Rules.crash_groups(sim)
		if groups.is_empty():
			break
		var removed := {}
		var collateral := {}
		var has_power := false
		for group in groups:
			for i in group:
				removed[i] = true
				for next in sim.neighbors(i):
					if GemRules.kind(sim.cells[next]) == GemRules.Kind.COUNTER:
						collateral[next] = true
			for rect in sim.power_gems:
				if group.has(rect.position.y * 6 + rect.position.x):
					has_power = true
		for i in collateral:
			removed[i] = true
		var removed_list: Array[Dictionary] = []
		for idx in removed.keys():
			if int(idx) >= 12:
				var code_b: int = cells_before[int(idx)]
				removed_list.append({
					"idx": int(idx),
					"x": int(idx) % 6,
					"y": int(idx) / 6,
					"code": code_b,
					"color": GemRules.color(code_b),
					"is_power": GemRules.kind(code_b) == GemRules.Kind.POWER,
					"is_c4": false
				})
		for idx in removed.keys():
			sim.cells[int(idx)] = 0
		var kept: Array[Rect2i] = []
		for rect in sim.power_gems:
			if not removed.has(rect.position.y * 6 + rect.position.x):
				kept.append(rect)
		sim.power_gems = kept
		var cells_mid: PackedInt32Array = sim.cells.duplicate()
		Rules.gravity(sim)
		Rules.form_powers(sim)
		var cells_after: PackedInt32Array = sim.cells.duplicate()
		var powers_after: Array = sim.power_gems.duplicate()
		steps.append({
			"chain": chain,
			"origin": board_origin,
			"cells_before": cells_before,
			"powers_before": powers_before,
			"cells_after": cells_after,
			"powers_after": powers_after,
			"removed": removed_list,
			"drops": gravity_offsets(cells_mid, cells_after),
			"cells_mid": cells_mid,
			"powers_mid": remaining_powers(powers_before, removed_list),
			"score": int(events[chain - 1].score),
			"has_power": has_power,
			"is_c4": false
		})
	if steps.is_empty():
		return 0
	var total_waves := steps.size()
	wave_queues[player] = steps
	start_next_wave(player)
	return total_waves

func remaining_powers(before: Array, removed: Array) -> Array:
	return before.filter(func(r): return not removed.any(func(c): return r.has_point(Vector2i(c.x, c.y))))

func gravity_offsets(before: PackedInt32Array, after: PackedInt32Array) -> Dictionary:
	var offsets := {}
	for x in range(6):
		var sources: Array[int] = []
		var targets: Array[int] = []
		for y in range(14):
			if before[y * 6 + x] != 0: sources.append(y)
			if after[y * 6 + x] != 0: targets.append(y)
		assert(sources.size() == targets.size())
		for n in range(sources.size()):
			if targets[n] > sources[n]: offsets[targets[n] * 6 + x] = float(targets[n] - sources[n]) * 32.0
	return offsets

func clear_wave_flashes(player: int) -> void:
	combo_flashes = combo_flashes.filter(func(f): return int(f.player) != player)

func begin_wave_fall(player: int) -> void:
	var w: Dictionary = active_wave[player]
	visual_cells_override[player] = w.cells_after
	visual_powers_override[player] = w.powers_after
	var max_distance := 0.0
	for idx in w.drops:
		cell_drop_y[player][int(idx)] = float(w.drops[idx])
		cell_squash[player][int(idx)] = 0.0
		max_distance = maxf(max_distance, float(w.drops[idx]))
	w.phase = "drop"
	w.timer = maxi(8, int(ceil(max_distance / 14.0)) + 7)

func start_next_wave(player: int) -> void:
	var q: Array = wave_queues[player]
	if q.is_empty():
		active_wave[player] = {}
		visual_cells_override[player] = PackedInt32Array()
		visual_powers_override[player] = []
		return
	var w: Dictionary = q.pop_front()
	w["phase"] = "pre"
	w["timer"] = 10
	active_wave[player] = w
	visual_cells_override[player] = w["cells_before"]
	visual_powers_override[player] = w["powers_before"]
	# Limpa flashes antigos deste jogador e inicia o Estágio 1 (Pré-explosão: gemas piscam e vibram)
	var kept_flashes: Array[Dictionary] = []
	for cf in combo_flashes:
		if int(cf["player"]) != player:
			kept_flashes.append(cf)
	combo_flashes = kept_flashes
	for rem in w["removed"]:
		combo_flashes.append({
			"player": player,
			"origin": w["origin"],
			"x": int(rem["x"]),
			"y": int(rem["y"]),
			"code": int(rem["code"]),
			"color": int(rem["color"]),
			"is_power": bool(rem["is_power"]),
			"is_c4": bool(rem["is_c4"]),
			"chain": int(w["chain"]),
			"ttl": 10,
			"max_ttl": 10
		})

func prepare_wave_fighter(player: int) -> void:
	var w: Dictionary = active_wave[player]
	fighter_attack_level[player] = 5 if bool(w.is_c4) else clampi(int(w.chain),1,5)
	var action := "grenade" if bool(w.is_c4) or int(w.chain)>=4 else "shoot"
	trigger_action(player,action)
	w["prepared"] = true

func detonate_active_wave(player: int) -> void:
	var w: Dictionary = active_wave[player]
	if w.is_empty():
		return
	var chain_num := int(w["chain"])
	var orig: Vector2 = w["origin"]
	var is_c4 := bool(w["is_c4"])
	var has_power := bool(w["has_power"])
	var sum_pos := Vector2.ZERO
	var cnt := 0
	var power_impacts := {}
	for rem in w["removed"]:
		var rx := int(rem["x"])
		var ry := int(rem["y"])
		var large_effect := not is_c4 or int(rem["color"]) == 5
		if bool(rem["is_power"]):
			for rect in w.powers_before:
				if rect.has_point(Vector2i(rx, ry)):
					large_effect = not power_impacts.has(rect)
					power_impacts[rect] = true
					break
		spawn_board_explosion(orig, rx, ry, int(rem["color"]), bool(rem["is_power"]), chain_num, is_c4, large_effect)
		sum_pos += orig + Vector2(rx * 32 + 16, (ry - 2) * 32 + 16)
		cnt += 1
	var popup_pos := (sum_pos / float(cnt)) if cnt > 0 else (orig + Vector2(96, 190))
	trigger_wave_presentation(player, chain_num, int(w["score"]), has_power, is_c4, orig, popup_pos, bool(w.get("prepared",false)))
	clear_wave_flashes(player)
	visual_cells_override[player] = w.cells_mid
	visual_powers_override[player] = w.powers_mid
	w.phase = "burst"
	w.timer = 14


func trigger_action(player: int, action: String, duration: int = 28, title: String = "", subtitle: String = "", continue_action: bool = false) -> void:
	# A simultaneous hit must not erase the other player's attack pose or release event.
	if continue_action and fighter_state[player] == action and fighter_timer[player] > 0:
		pass
	elif action == "hit" and fighter_state[player] in ["shoot", "grenade"] and fighter_timer[player] > 0:
		pending_hit[player] = maxi(pending_hit[player], duration)
		fighter_flash[player] = 2
		fighter_flash_ticks[player] = 3
	else:
		set_fighter_state(player, action, duration, true)
	if title != "":
		callout_text[player] = title
		callout_sub[player] = subtitle
		callout_timer[player] = 52

func trigger_demo_combo(board_origins: Array[Vector2]) -> void:
	# Configura uma demonstração dramática de combo/ataque especial com explosões nas grades e na arena
	trigger_action(0, "shoot", 35, "3X CHAIN COMBO!", "M4A1-S SUPPRESSED BARRAGE")
	fighter_anim_frame[0] = 1
	fighter_pos_offset[0] = Vector2(8, 0)
	spawn_shell_casing(0)
	trigger_action(1, "hit", 35, "COUNTER BREAK!", "+1040 PTS")
	fighter_anim_frame[1] = 1
	fighter_pos_offset[1] = Vector2(14, -6)
	# Explosão de granada e relâmpago no centro da arena
	spawn_vfx("vfx_explosion.png", Vector2(568, 392), 0.35, 0.62, 28, Color.WHITE, 0.03)
	spawn_vfx("vfx_shockwave.png", Vector2(568, 392), 0.25, 0.68, 24, Color("ffe868"), 0.0)
	spawn_vfx("vfx_lightning.png", Vector2(436, 368), 0.32, 0.54, 24, Color("84f0ff"), -0.04)
	# Projétil de granada no ar
	projectiles.append({
		"kind": "he",
		"owner": 0,
		"x": 430.0,
		"y": 350.0,
		"tx": 575.0,
		"ty": 395.0,
		"t": 0.52,
		"speed": 0.04
	})
	# Explosões cristalinas nos tabuleiros e popups de cadeia na demonstração
	spawn_board_explosion(board_origins[0], 2, 10, 3, true, 3, false)
	spawn_board_explosion(board_origins[0], 3, 11, 1, false, 3, false)
	spawn_board_explosion(board_origins[0], 4, 12, 4, true, 3, false)
	spawn_board_explosion(board_origins[1], 3, 8, 4, false, 1, false)
	combo_flashes.append({
		"player": 0,
		"origin": board_origins[0],
		"x": 2,
		"y": 9,
		"code": 11,
		"color": 3,
		"is_power": false,
		"is_c4": false,
		"chain": 3,
		"ttl": 9,
		"max_ttl": 10
	})
	set_chain_banner(0, board_origins[0], 3, false)
	spawn_board_popup(board_origins[0] + Vector2(64, 196), "3 CHAIN!", "+1040 PTS", Color("ffe852"))
	power_flash_ticks[0] = 10

func is_board_in_danger(model, player: int) -> bool:
	if int(model.pending[player]) >= 6:
		return true
	var cells: PackedInt32Array = model.boards[player].cells
	for idx in range(12, 36):
		if cells[idx] != 0:
			return true
	return false

func advance_fighter_anim(player: int, model) -> void:
	fighter_recoil[player] *= 0.55
	if fighter_flash_ticks[player] > 0:
		fighter_flash_ticks[player] -= 1
		if fighter_flash_ticks[player] == 0: fighter_flash[player] = 0
	var entered := false
	if fighter_timer[player] > 0:
		fighter_timer[player] -= 1
		if fighter_timer[player] == 0 and model.winner == -2:
			if pending_hit[player] > 0:
				set_fighter_state(player, "hit", pending_hit[player], true)
				pending_hit[player] = 0
			else:
				var next_st := "danger" if is_board_in_danger(model, player) else "idle"
				set_fighter_state(player, next_st, 0)
	elif model.winner == -2 and fighter_state[player] in ["idle", "danger"]:
		var desired := "danger" if is_board_in_danger(model, player) else "idle"
		if fighter_state[player] != desired:
			set_fighter_state(player, desired, 0)
	var p_anims: Dictionary = fighter_anims.get(player, fighter_anims[0])
	var seq: Array = p_anims.get(fighter_state[player], p_anims["idle"])
	if seq.is_empty():
		return
	var frame_idx := clampi(fighter_anim_frame[player], 0, seq.size() - 1)
	var kf: Dictionary = seq[frame_idx]
	fighter_frame_tick[player] += 1
	if fighter_frame_tick[player] >= int(kf.get("ticks", 12)):
		fighter_frame_tick[player] = 0
		var looped := fighter_state[player] in ["idle", "danger"]
		var next_frame := (frame_idx + 1) % seq.size() if looped else mini(frame_idx + 1, seq.size() - 1)
		if next_frame != frame_idx:
			fighter_anim_frame[player] = next_frame
			entered = true
		kf = seq[next_frame]
	var target_ofs: Vector2 = kf.get("ofs", Vector2.ZERO)
	var target_sc: Vector2 = kf.get("scale", Vector2.ONE)
	fighter_pos_offset[player] = fighter_pos_offset[player].lerp(target_ofs, 0.42)
	fighter_scale_mod[player] = fighter_scale_mod[player].lerp(target_sc, 0.38)
	if entered: enter_fighter_frame(player)

func temporal_connection_stage(player: int, idx: int) -> int:
	var ages: PackedInt32Array = connection_age[player]
	if idx < 0 or idx >= ages.size() or ages[idx] < 0: return 0
	return 0 if ages[idx] < 4 else (1 if ages[idx] < 8 else 2)

func normal_contour_texture(color_idx: int, stage: int) -> Texture2D:
	var key: Vector2i = Vector2i(color_idx, stage)
	if contour_textures.has(key): return contour_textures[key]
	var source: Image = load_tex("gem_normal_%d.png" % color_idx).get_image()
	source.resize(32, 32, Image.INTERPOLATE_NEAREST)
	var image: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var width: int = 16 if stage == 2 else 14
	var height: int = 14 if stage == 0 else 16
	var left: int = (16 - width) / 2
	var top: int = (16 - height) / 2
	var colors: Array[Color] = [Color("58c8ff"),Color("ffe858"),Color("58ff98"),Color("ff5878")]
	for y in range(32):
		for x in range(32):
			var nx: int = x / 2
			var ny: int = y / 2
			var edge: int = mini(ny - top, top + height - 1 - ny)
			var cut: int = maxi(0, 2 - edge)
			if ny < top or ny >= top + height or nx < left + cut or nx >= left + width - cut: continue
			var pixel: Color = source.get_pixel(x,y)
			if pixel.a < 0.1: pixel = colors[color_idx - 1]
			pixel.a = 1.0
			image.set_pixel(x,y,pixel)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	contour_textures[key] = texture
	return texture

func temporal_halo_texture() -> Texture2D:
	if contour_textures.has("halo"): return contour_textures["halo"]
	var body: Image = normal_contour_texture(1,0).get_image()
	var outer: Image = normal_contour_texture(1,2).get_image()
	var image: Image = Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			if outer.get_pixel(x,y).a > 0.5 and body.get_pixel(x,y).a < 0.5:
				image.set_pixel(x,y,Color(1.0,187.0/255.0,187.0/255.0,1.0))
	var texture: Texture2D = ImageTexture.create_from_image(image)
	contour_textures["halo"] = texture
	return texture

func temporal_player_at(center: Vector2) -> int:
	for player in range(2):
		var origin: Vector2 = temporal_origins[player]
		if temporal_players[player] and center.x >= origin.x and center.x < origin.x + 192.0:
			return player
	return -1

func sync_temporal_board(model: RefCounted, player: int, origin: Vector2) -> void:
	var motion: RefCounted = model.motion[player]
	var board: RefCounted = model.boards[player]
	var cells: PackedInt32Array = board.cells
	cell_drop_y[player].fill(0.0)
	cell_squash[player].fill(0.0)
	power_flash_ticks[player] = 0
	# A ligação vertical azul é o contorno medido; outras geometrias ficam sem extrapolação.
	for idx in range(84):
		var adjacent: Array[int] = []
		if cells[idx] == 1:
			for neighbor in board.neighbors(idx):
				if cells[neighbor] == 1: adjacent.append(neighbor)
		var linked: bool = adjacent.size() == 1 and absi(int(adjacent[0]) - idx) == 6
		if linked:
			var partner_neighbors: int = 0
			for neighbor in board.neighbors(adjacent[0]):
				if cells[neighbor] == 1: partner_neighbors += 1
			linked = partner_neighbors == 1
		for below in range(idx + 6, 84, 6):
			if cells[below] == 0: linked = false; break
		if not linked: connection_age[player][idx] = -1
		elif prev_cells[player].size() == 84 and prev_cells[player][idx] != cells[idx]: connection_age[player][idx] = 0
		else: connection_age[player][idx] = maxi(0, connection_age[player][idx] + 1)
	# O halo foi aferido apenas para P1 vertical azul/verde; não extrapolar paleta/rotação.
	var pair: RefCounted = model.pairs[player]
	active_halo[player] = player == 0 and motion.phase == 0 and pair.rotation == 0 and pair.colors == PackedInt32Array([1,3]) and model.pair_age[player] % 2 == 0
	union_age[player] += 1
	# União medida: duas 2x2 separadas por uma coluna -> 3x2 + 2x2 por dez quadros -> 5x2.
	for rect in board.power_gems:
		if rect.size != Vector2i(5,2) or rect in prev_powers[player]: continue
		var left: Rect2i = Rect2i(rect.position, Vector2i(2,2))
		var right: Rect2i = Rect2i(rect.position + Vector2i(3,0), Vector2i(2,2))
		if left in prev_powers[player] and right in prev_powers[player]:
			union_view[player] = [Rect2i(rect.position,Vector2i(3,2)),right]
			union_age[player] = 0
	if union_age[player] < 10:
		var union_rect: Rect2i = Rect2i(union_view[player][0].position, Vector2i(5,2))
		if union_rect not in board.power_gems: union_age[player] = 10
	# Uma onda por vez, sem gravidade nem próximas ondas previstas no tabuleiro de desenho.
	if not active_wave[player].is_empty() and bool(active_wave[player].get("temporal",false)):
		var current: Dictionary = active_wave[player]
		if motion.chain_count >= int(current.chain):
			var actual: Array = motion.result.get("waves", [])
			if not actual.is_empty(): current.score = int(actual[-1].score)
			detonate_active_wave(player)
			active_wave[player] = {}
			visual_cells_override[player] = PackedInt32Array()
			visual_powers_override[player] = []
		else:
			current.timer = motion.clear_timer
			if motion.phase == 9 and not bool(current.get("prepared",false)): prepare_wave_fighter(player)
	if motion.clear_timer > 0 and active_wave[player].is_empty():
		var copy: RefCounted = Board.new()
		copy.load_cells(cells)
		copy.power_gems.assign(board.power_gems)
		var event: Dictionary = Rules.resolve_single_wave(copy, motion.chain_count + 1)
		if not event.is_empty():
			var removed: Array[Dictionary] = []
			var diamond: bool = bool(event.get("diamond",false))
			for idx in range(12,84):
				if cells[idx] == 0 or copy.cells[idx] != 0: continue
				removed.append({"idx":idx,"x":idx%6,"y":idx/6,"code":cells[idx],"color":GemRules.color(cells[idx]),"is_power":GemRules.kind(cells[idx])==GemRules.Kind.POWER,"is_c4":diamond})
			active_wave[player] = {"temporal":true,"phase":"pre","timer":motion.clear_timer,"chain":motion.chain_count+1,"origin":origin,"score":int(event.score),"removed":removed,"is_c4":diamond,"has_power":removed.any(func(r): return r.is_power),"powers_before":board.power_gems.duplicate(),"cells_mid":copy.cells.duplicate(),"powers_mid":copy.power_gems.duplicate()}

func step_from_model(model, board_origins: Array[Vector2] = [Vector2(64, 108), Vector2(744, 108)]) -> void:
	anim_tick += 1
	if screen_shake_timer > 0:
		screen_shake_timer -= 1
		if screen_shake_timer == 0:
			screen_shake_mag = 0.0
	for i in range(2):
		if callout_timer[i] > 0:
			callout_timer[i] -= 1
		if power_flash_ticks[i] > 0:
			power_flash_ticks[i] -= 1
		if not chain_banners[i].is_empty():
			chain_banners[i]["ttl"] = int(chain_banners[i]["ttl"]) - 1
			if int(chain_banners[i]["ttl"]) <= 0:
				chain_banners[i] = {}
		temporal_origins[i] = board_origins[i]
		if model.frame > 0 or model.motion[i].phase != 0: temporal_players[i] = true
		if temporal_players[i]: sync_temporal_board(model, i, board_origins[i])
		# Replay explícito do showcase; a partida temporal não usa esse relógio.
		if not active_wave[i].is_empty() and not bool(active_wave[i].get("temporal",false)):
			active_wave[i]["timer"] = int(active_wave[i]["timer"]) - 1
			if str(active_wave[i].phase) == "pre":
				var prepare_at := 9 if bool(active_wave[i].is_c4) or int(active_wave[i].chain)>=4 else 3
				if int(active_wave[i].timer)==prepare_at: prepare_wave_fighter(i)
			if int(active_wave[i]["timer"]) <= 0:
				if str(active_wave[i]["phase"]) == "pre":
					detonate_active_wave(i)
				elif str(active_wave[i]["phase"]) == "burst":
					begin_wave_fall(i)
				else:
					start_next_wave(i)
		var cur_cells: PackedInt32Array = model.boards[i].cells
		var old_cells: PackedInt32Array = prev_cells[i]
		if not temporal_players[i]:
			# Atualiza animações de queda e squash & stretch das células do tabuleiro
			var dy_arr: PackedFloat32Array = cell_drop_y[i]
			var sq_arr: PackedFloat32Array = cell_squash[i]
			for idx in range(84):
				if dy_arr[idx] > 0.0:
					dy_arr[idx] = maxf(0.0, dy_arr[idx] - 14.0)
					if dy_arr[idx] == 0.0:
						sq_arr[idx] = 1.0
				elif sq_arr[idx] > 0.0:
					sq_arr[idx] = maxf(0.0, sq_arr[idx] - 0.14)
			if old_cells.size() == 84 and active_wave[i].is_empty() and model.motion[i].phase == 0:
				for idx in range(12, 84):
					if cur_cells[idx] != 0 and old_cells[idx] == 0:
						# Nova pedra pousou ou caiu nesta célula
						dy_arr[idx] = 22.0
						sq_arr[idx] = 0.85
			if model.motion[i].phase == 1:
				dy_arr.fill(0.0)
				sq_arr.fill(0.0)
			cell_drop_y[i] = dy_arr
			cell_squash[i] = sq_arr
			# Detecta formação ou expansão de Power Gems para disparar flash de cristalização
			var cur_powers: Array = model.boards[i].power_gems
			if cur_powers.size() > prev_powers[i].size():
				power_flash_ticks[i] = 14
			else:
				for r_idx in range(mini(cur_powers.size(), prev_powers[i].size())):
					if cur_powers[r_idx].get_area() > prev_powers[i][r_idx].get_area():
						power_flash_ticks[i] = 14
						break
		prev_powers[i] = model.boards[i].power_gems.duplicate()
		update_power_facets_for(model, i)
		# Micro-reação tática ao assentar uma peça mesmo sem combo
		if prev_pair_idx[i] != -1 and prev_pair_idx[i] != int(model.pair_index[i]) and fighter_state[i] in ["idle", "danger"]:
			fighter_scale_mod[i] = Vector2(1.04, 0.96)
			fighter_pos_offset[i] += Vector2(0, 2.5)
		if not temporal_players[i] and model.motion[i].phase == 9 and (model.motion[i].clear_timer > 0 or not model.motion[i].result.get("waves", []).is_empty()) and model.motion[i].chain_count == 0 and active_wave[i].is_empty() and model.motion[i].pre_resolve_cells.size() == 84:
			enqueue_visual_waves(i, model.motion[i].pre_resolve_cells, board_origins[i], false)
		var score_delta: int = model.scores[i] - prev_scores[i]
		if not temporal_players[i] and score_delta >= 200 and active_wave[i].is_empty() and model.motion[i].phase == 0:
			var enqueued := 0
			if old_cells.size() == 84 and prev_pair_snapshot[i] != null:
				var sim_pre := Board.new()
				sim_pre.load_cells(old_cells)
				var snap_p = prev_pair_snapshot[i].copy()
				for _step in range(14):
					var down_p = snap_p.copy()
					down_p.pivot += Vector2i(0, 1)
					if sim_pre.can_place(down_p):
						snap_p = down_p
					else:
						break
				if sim_pre.commit(snap_p):
					enqueued = enqueue_visual_waves(i, sim_pre.cells, board_origins[i], true)
			if enqueued == 0:
				# Fallback caso o tabuleiro tenha sido carregado diretamente sem par ativo
				var res: Dictionary = model.last_results[i]
				var waves: Array = res.get("waves", [])
				var has_diamond := false
				var has_power := false
				var wave_color := 1
				for w in waves:
					if bool(w.get("diamond", false)):
						has_diamond = true
					for g in w.get("groups", []):
						wave_color = int(g.get("color", 1))
						if not g.get("powers", []).is_empty():
							has_power = true
				var sum_pos := Vector2.ZERO
				var destroyed_cnt := 0
				if old_cells.size() == 84:
					for idx in range(12, 84):
						if old_cells[idx] != 0 and cur_cells[idx] == 0:
							var cx := idx % 6
							var cy := idx / 6
							var c_code: int = old_cells[idx]
							var c_num := maxi(1, waves.size())
							combo_flashes.append({
								"player": i,
								"origin": board_origins[i],
								"x": cx,
								"y": cy,
								"code": c_code,
								"color": (c_code & 7) if (c_code & 7) != 0 else wave_color,
								"is_power": has_power or (c_code & 128) != 0,
								"is_c4": has_diamond,
								"chain": c_num,
								"ttl": 10,
								"max_ttl": 10
							})
							sum_pos += board_origins[i] + Vector2(cx * 32 + 16, (cy - 2) * 32 + 16)
							destroyed_cnt += 1
				var popup_pos := (sum_pos / float(destroyed_cnt)) if destroyed_cnt > 0 else (board_origins[i] + Vector2(96, 180))
				trigger_wave_presentation(i, maxi(1, waves.size()), score_delta, has_power, has_diamond, board_origins[i], popup_pos)
		elif prev_pending[i] > 0 and int(model.pending[i]) == 0 and fighter_state[i] in ["idle", "danger"]:
			# Recebeu queda de Counter Gems no tabuleiro
			trigger_action(i, "hit", 18, "COUNTER DROP!", "")
			trigger_screen_shake(8, 3.0)
		prev_pair_idx[i] = int(model.pair_index[i])
		if model.pairs[i] != null:
			prev_pair_snapshot[i] = model.pairs[i].copy()
		prev_scores[i] = model.scores[i]
		prev_pending[i] = model.pending[i]
		prev_cells[i] = cur_cells.duplicate()
		advance_fighter_anim(i, model)
	# Atualiza células em fase de flash de combo (quando não gerenciadas por active_wave)
	var next_flashes: Array[Dictionary] = []
	for cf in combo_flashes:
		var p_idx := int(cf["player"])
		if not active_wave[p_idx].is_empty():
			cf["ttl"] = maxi(1, int(cf["ttl"]) - 1)
			next_flashes.append(cf)
		else:
			cf["ttl"] = int(cf["ttl"]) - 1
			if int(cf["ttl"]) <= 0:
				spawn_board_explosion(
					Vector2(cf["origin"]),
					int(cf["x"]),
					int(cf["y"]),
					int(cf["color"]),
					bool(cf["is_power"]),
					int(cf.get("chain", 1)),
					bool(cf.get("is_c4", false))
				)
			else:
				next_flashes.append(cf)
	combo_flashes = next_flashes
	# Atualiza flashes rápidos de impacto (Estágio 2)
	var next_impacts: Array[Dictionary] = []
	for imp in impact_flashes:
		imp["ttl"] = int(imp["ttl"]) - 1
		if int(imp["ttl"]) > 0:
			next_impacts.append(imp)
	impact_flashes = next_impacts
	# Atualiza partículas físicas de estilhaços cristalinos (gem_sparks — Estágios 4 & 5)
	var next_sparks: Array[Dictionary] = []
	for sp in gem_sparks:
		if int(sp.get("delay",0))>0:
			sp["delay"] = int(sp["delay"])-1
			next_sparks.append(sp)
			continue
		sp["ttl"] = int(sp["ttl"]) - 1
		sp["x"] = float(sp["x"]) + float(sp["vx"])
		sp["y"] = float(sp["y"]) + float(sp["vy"])
		sp["vy"] = float(sp["vy"]) + 0.28
		sp["vx"] = float(sp["vx"]) * 0.985
		sp["rotation"] = float(sp.get("rotation", 0.0)) + float(sp.get("spin", 0.0))
		if int(sp["ttl"]) > 0:
			next_sparks.append(sp)
	gem_sparks = next_sparks
	# Atualiza popups flutuantes de pontuação e cadeia nos tabuleiros
	var next_popups: Array[Dictionary] = []
	for pop in board_popups:
		pop["ttl"] = int(pop["ttl"]) - 1
		pop["pos"] = Vector2(pop["pos"]) + Vector2(pop["vel"])
		if int(pop["ttl"]) > 0:
			next_popups.append(pop)
	board_popups = next_popups
	if model.winner >= 0 and last_winner_recorded != model.winner:
		last_winner_recorded = model.winner
		wins[model.winner] = mini(9, wins[model.winner] + 1)
	if model.winner == 0:
		set_fighter_state(0, "victory", 0)
		set_fighter_state(1, "defeat", 0)
	elif model.winner == 1:
		set_fighter_state(1, "victory", 0)
		set_fighter_state(0, "defeat", 0)
	elif model.winner == -1:
		set_fighter_state(0, "defeat", 0)
		set_fighter_state(1, "defeat", 0)
	# Atualiza cápsulas deflagradas com gravidade e quique no chão
	var next_shells: Array[Dictionary] = []
	for sh in shell_casings:
		sh["ttl"] = int(sh["ttl"]) - 1
		sh["x"] = float(sh["x"]) + float(sh["vx"])
		sh["y"] = float(sh["y"]) + float(sh["vy"])
		sh["vy"] = float(sh["vy"]) + 0.44
		sh["rot"] = float(sh["rot"]) + float(sh["vrot"])
		if float(sh["y"]) >= 488.0:
			sh["y"] = 488.0
			sh["vy"] = -absf(float(sh["vy"])) * 0.45
			sh["vx"] = float(sh["vx"]) * 0.72
		if int(sh["ttl"]) > 0:
			next_shells.append(sh)
	shell_casings = next_shells
	# Atualiza projéteis
	var next_proj: Array[Dictionary] = []
	for proj in projectiles:
		if int(proj.get("born_tick",-1)) != anim_tick:
			proj["t"] = float(proj["t"]) + float(proj["speed"])
		if float(proj["t"]) >= 1.0:
			var hit_pos := Vector2(float(proj["tx"]), float(proj["ty"]))
			if proj["kind"] == "he":
				grenade_impact(proj)
			else:
				spawn_vfx("vfx_shatter.png", hit_pos, 0.14, 0.34, 12, Color("84f0ff") if int(proj["owner"]) == 0 else Color("ffe052"), 0.1)
				spawn_vfx("vfx_shockwave.png", hit_pos, 0.10, 0.28, 10, Color.WHITE)
		else:
			next_proj.append(proj)
	projectiles = next_proj
	# Atualiza sprites de efeitos especiais (VFX)
	var next_vfx: Array[Dictionary] = []
	for fx in vfx_sprites:
		if int(fx.get("born_tick",-1)) != anim_tick: fx["ttl"] = int(fx["ttl"]) - 1
		fx["pos"] = Vector2(fx["pos"]) + Vector2(fx["vel"])
		fx["rot"] = float(fx["rot"]) + float(fx["rot_speed"])
		if int(fx["ttl"]) > 0:
			next_vfx.append(fx)
	vfx_sprites = next_vfx

static func draw_outlined_text(canvas: CanvasItem, font: Font, pos: Vector2, text: String, size: int, fill: Color, outline: Color = Color("080a12"), thickness: int = 2) -> void:
	for dy in range(-thickness, thickness + 1):
		for dx in range(-thickness, thickness + 1):
			if dx == 0 and dy == 0:
				continue
			canvas.draw_string(font, pos + Vector2(dx, dy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, fill)

func draw_backdrop(canvas: CanvasItem) -> void:
	var stage: Dictionary = STAGES[stage_index]
	var bg_tex := load_tex(stage["tex"])
	if bg_tex != null:
		canvas.draw_texture_rect(bg_tex, Rect2(0, 0, 1000, 700), false)
	else:
		canvas.draw_rect(Rect2(0, 0, 1000, 700), Color("1a1412"))
	# Vinheta superior e inferior sutil para destacar o HUD estilo CPS-2
	canvas.draw_rect(Rect2(0, 0, 1000, 26), Color(0.03, 0.04, 0.08, 0.72))
	canvas.draw_rect(Rect2(0, 636, 1000, 64), Color(0.03, 0.04, 0.08, 0.86))
	canvas.draw_line(Vector2(0, 636), Vector2(1000, 636), stage["accent"], 2.0)

func draw_board_well_frame(canvas: CanvasItem, font: Font, player: int, origin: Vector2, pending_amount: int) -> void:
	var stage: Dictionary = STAGES[stage_index]
	var well_rect := Rect2(origin, Vector2(192, 384))
	var team_col := Color("48a8ff") if player == 0 else Color("ff7848")
	# Sombra projetada da moldura do tabuleiro sobre o cenário
	var shadow_r := well_rect.grow(10)
	shadow_r.position += Vector2(4, 6)
	canvas.draw_rect(shadow_r, Color(0, 0, 0, 0.58))
	# Moldura metálica chanfrada CPS-2 (bevel duplo em aço/ouro)
	canvas.draw_rect(well_rect.grow(8), Color("121724"))
	canvas.draw_rect(well_rect.grow(6), team_col.darkened(0.35))
	canvas.draw_rect(well_rect.grow(6), team_col.lightened(0.35), false, 2.0)
	canvas.draw_rect(well_rect.grow(2), Color("d8e6ff"), false, 2.0)
	# Fundo semitransparente do poço (deixa a parede de tijolos/pedra do cenário visível atrás das gemas!)
	canvas.draw_rect(well_rect, stage["well_tint"])
	# Grade interna sutil estilo CPS-2
	for y in range(12):
		for x in range(6):
			var cell_r := Rect2(origin + Vector2(x * 32, y * 32), Vector2(32, 32))
			canvas.draw_rect(cell_r, Color(0.75, 0.85, 1.0, 0.07), false, 1.0)
	# Barra superior chanfrada com abertura na coluna 3 (x = 3) igual ao Super Puzzle Fighter II Turbo!
	var left_bar := Rect2(origin.x - 4, origin.y - 26, 3 * 32 + 4, 22)
	var right_bar := Rect2(origin.x + 4 * 32, origin.y - 26, 2 * 32 + 4, 22)
	for bar in [left_bar, right_bar]:
		canvas.draw_rect(bar, Color("2b231d"))
		canvas.draw_rect(bar.grow(-2), Color("524134"))
		canvas.draw_rect(bar, Color("e8edf7"), false, 2.0)
	# Marcador luminoso de entrada na coluna 3 (spawn)
	var notch_center := origin + Vector2(3 * 32 + 16, 16)
	canvas.draw_line(notch_center - Vector2(9, 9), notch_center + Vector2(9, 9), Color(1.0, 0.32, 0.36, 0.72), 2.5)
	canvas.draw_line(notch_center - Vector2(9, -9), notch_center + Vector2(9, -9), Color(1.0, 0.32, 0.36, 0.72), 2.5)
	# Indicadores de Counter Gems pendentes usando os próprios sprites das gemas no topo!
	draw_warning_gems(canvas, font, origin, pending_amount)

func draw_warning_gems(canvas: CanvasItem, font: Font, origin: Vector2, pending_amount: int) -> void:
	if pending_amount <= 0:
		return
	var rem := pending_amount
	var x_off := 0.0
	var red_gem := load_tex("gem_crash_4.png")
	var yel_gem := load_tex("gem_normal_2.png")
	while rem > 0 and x_off < 156.0:
		if rem >= 6 and red_gem != null:
			canvas.draw_texture_rect(red_gem, Rect2(origin + Vector2(x_off, -50), Vector2(22, 22)), false)
			rem -= 6
			x_off += 23.0
		elif yel_gem != null:
			canvas.draw_texture_rect(yel_gem, Rect2(origin + Vector2(x_off, -47), Vector2(17, 17)), false)
			rem -= 1
			x_off += 18.0
		else:
			break
	draw_outlined_text(canvas, font, origin + Vector2(x_off + 4, -32), "x%d" % pending_amount, 15, Color("ffe868"))

func draw_gem_sprite(canvas: CanvasItem, center: Vector2, code: int, KindEnum, phase_seed: int = 0, scale_mod: Vector2 = Vector2.ONE) -> void:
	var k: int = KindEnum.kind(code)
	var temporal_player: int = temporal_player_at(center)
	if temporal_player >= 0 and k == KindEnum.Kind.NORMAL:
		var stage: int = temporal_connection_stage(temporal_player,phase_seed) if phase_seed < 84 else 0
		var contour: Texture2D = normal_contour_texture(clampi(KindEnum.color(code),1,4),stage)
		canvas.draw_texture_rect(contour,Rect2(center-Vector2(16,16),Vector2(32,32)),false)
		if phase_seed == 90 and active_halo[temporal_player]:
			canvas.draw_texture_rect(temporal_halo_texture(),Rect2(center-Vector2(16,16),Vector2(32,32)),false)
		return
	var c: int = clampi(KindEnum.color(code), 1, 4)
	var tex: Texture2D = null
	var draw_center := center
	var is_falling_pair := (phase_seed >= 90)
	var c4_blink := false
	if k == KindEnum.Kind.DIAMOND:
		# C4 explosiva do Counter-Strike: pisca o LED vermelho mais rápido durante a queda!
		var period := 8 if is_falling_pair else 14
		c4_blink = posmod(anim_tick + phase_seed, period) < (period / 2)
		tex = load_tex("gem_c4_1.png" if c4_blink else "gem_c4_0.png")
		if tex == null:
			tex = load_tex("gem_diamond.png")
	elif k == KindEnum.Kind.CRASH:
		tex = load_tex("gem_crash_%d.png" % c)
	elif k == KindEnum.Kind.COUNTER:
		var cnt: int = clampi(KindEnum.countdown(code), 1, 5)
		tex = load_tex("gem_counter_%d_%d.png" % [c, cnt])
		if cnt == 1:
			draw_center.x += sin(float(anim_tick) * 1.4 + float(phase_seed)) * 1.2
	else:
		tex = load_tex("gem_normal_%d.png" % c)
	var sw := 31.0 * scale_mod.x
	var sh := 31.0 * scale_mod.y
	# Sombra suave no fundo do poço (circular para Crash Orbs, retangular chanfrada para gemas/C4)
	if k == KindEnum.Kind.CRASH:
		var orb_cols := {1: Color("2898ff"), 2: Color("ffc824"), 3: Color("24e068"), 4: Color("ff3252")}
		var oc: Color = orb_cols.get(c, Color.WHITE)
		var pulse_halo := 0.5 + 0.5 * sin(float(anim_tick) * 0.22 + float(phase_seed) * 0.7)
		canvas.draw_circle(draw_center + Vector2(1.0, 2.0), sw * 0.48, Color(0, 0, 0, 0.42))
		canvas.draw_circle(draw_center, sw * (0.46 + 0.05 * pulse_halo), Color(oc.r, oc.g, oc.b, 0.18 + 0.14 * pulse_halo))
	else:
		canvas.draw_rect(Rect2(draw_center - Vector2(sw * 0.45, sh * 0.42), Vector2(sw * 0.94, sh * 0.94)), Color(0, 0, 0, 0.38))
	if tex != null:
		var dst := Rect2(draw_center - Vector2(sw * 0.5, sh * 0.5), Vector2(sw, sh))
		var mod := Color.WHITE
		if k == KindEnum.Kind.CRASH:
			var pulse := 0.96 + 0.08 * sin(float(anim_tick) * 0.22 + float(phase_seed))
			mod = Color(pulse, pulse, pulse, 0.96)
		elif k == KindEnum.Kind.COUNTER and KindEnum.countdown(code) == 1:
			var warn := 0.5 + 0.5 * sin(float(anim_tick) * 0.35)
			mod = Color(1.0 + 0.30 * warn, 0.85 - 0.15 * warn, 0.85 - 0.15 * warn, 1.0)
		canvas.draw_texture_rect(tex, dst, false, mod)
		if k == KindEnum.Kind.CRASH:
			# Luz interna pulsante no centro transparente da Crash Orb + brilho especular branco na borda
			var orb_cols := {1: Color("58c8ff"), 2: Color("ffe858"), 3: Color("58ff98"), 4: Color("ff5878")}
			var ic: Color = orb_cols.get(c, Color.WHITE)
			var core_pulse := 0.5 + 0.5 * sin(float(anim_tick) * 0.26 + float(phase_seed) * 0.9)
			var core_r := lerpf(3.2, 5.4, core_pulse) * scale_mod.x
			canvas.draw_circle(draw_center, core_r + 1.8, Color(ic.r, ic.g, ic.b, 0.32 + 0.25 * core_pulse))
			canvas.draw_circle(draw_center, core_r * 0.55, Color(1.0, 1.0, 1.0, 0.32 + 0.26 * core_pulse))
			# Reflexo branco especular nítido no topo esquerdo da esfera de vidro
			canvas.draw_rect(Rect2(draw_center + Vector2(-8.0, -8.0), Vector2(3.0, 2.0)), Color(1, 1, 1, 0.88))
		elif k == KindEnum.Kind.DIAMOND:
			# Sinalizador LED vermelho pulsante + onda de bip tático da C4
			var led_pos := draw_center + Vector2(7.0 * scale_mod.x, -7.0 * scale_mod.y)
			if c4_blink:
				canvas.draw_circle(led_pos, 5.5, Color(1.0, 0.15, 0.22, 0.42))
				canvas.draw_circle(led_pos, 2.4, Color.WHITE)
			var beep_t := fposmod(float(anim_tick) * (0.08 if is_falling_pair else 0.05) + float(phase_seed) * 0.2, 1.0)
			if beep_t < 0.75:
				var ring_r := lerpf(3.0, 12.0, beep_t / 0.75)
				var ring_a := (1.0 - beep_t / 0.75) * 0.55
				canvas.draw_arc(led_pos, ring_r, 0.0, TAU, 16, Color(1.0, 0.22, 0.28, ring_a), 1.5)
		else:
			# Reflexo diagonal cristalino nas gemas facetadas normais/counter
			var glint_cycle := posmod(anim_tick + phase_seed * 19, 84)
			if glint_cycle < 16:
				var prog := float(glint_cycle) / 16.0
				var alpha := sin(prog * PI)
				var sheen_ofs := lerpf(-8.0, 8.0, prog)
				canvas.draw_line(draw_center + Vector2(sheen_ofs - 5.0, -7.0), draw_center + Vector2(sheen_ofs + 3.0, 5.0), Color(1, 1, 1, alpha * 0.65), 2.0)
				var gp := draw_center + Vector2(-6.0, -6.0)
				canvas.draw_line(gp - Vector2(5.0, 0), gp + Vector2(5.0, 0), Color(1, 1, 1, alpha), 2.0)
				canvas.draw_line(gp - Vector2(0, 5.0), gp + Vector2(0, 5.0), Color(1, 1, 1, alpha), 2.0)

func draw_combo_flashes(canvas: CanvasItem, player: int, KindEnum) -> void:
	# ESTÁGIO 1 DA DESTRUIÇÃO: Pré-explosão (gemas/orbes/C4 brilham, piscam e expandem energia antes do impacto)
	var pal := {1: Color("58c8ff"), 2: Color("ffe858"), 3: Color("58ff98"), 4: Color("ff5878"), 5: Color("ff6838")}
	for cf in combo_flashes:
		if int(cf["player"]) != player:
			continue
		var cx := int(cf["x"])
		var cy := int(cf["y"])
		if cy < 2:
			continue
		var orig := Vector2(cf["origin"])
		var ttl := int(cf["ttl"])
		var max_t := maxi(1, int(cf.get("max_ttl", 10)))
		var prog := 1.0 - float(ttl) / float(max_t)
		var code := int(cf["code"])
		var k: int = KindEnum.kind(code)
		if k == KindEnum.Kind.POWER: continue
		var col_c: Color = pal.get(int(cf.get("color", 1)), Color.WHITE)
		var stress := maxf(0.0,(prog-0.45)/0.55)
		var jitter := Vector2(sin(float(anim_tick * 4 + cx * 3)),cos(float(anim_tick * 5 + cy * 3))) * stress * 1.2
		var center := orig + Vector2(cx * 32 + 16, (cy - 2) * 32 + 16) + jitter
		# Iluminação localizada na célula antes de estourar
		canvas.draw_circle(center, 19.0 + prog * 6.0, Color(col_c.r, col_c.g, col_c.b, 0.28 + prog * 0.32))
		var sc_pulse := 1.0 + 0.06 * sin(prog * PI)
		draw_gem_sprite(canvas, center, code, KindEnum, cx + cy * 6, Vector2(sc_pulse, sc_pulse))
		if k == KindEnum.Kind.CRASH:
			# Animação de ativação da Crash Orb: núcleo expande e emite anel de vidro luminoso
			canvas.draw_circle(center, lerpf(3.0,8.0,prog), Color(1.0,1.0,1.0,0.24+0.28*prog))
			canvas.draw_arc(center, lerpf(8.0, 18.0, prog), 0.0, TAU, 20, Color(col_c.r, col_c.g, col_c.b, 0.95), 2.5)
		elif k == KindEnum.Kind.DIAMOND or bool(cf.get("is_c4", false)):
			# Animação de ativação da C4: luz vermelha pulsante intensa e mira tática nas gemas atingidas
			var strobe := (ttl % 2 == 0)
			if k == KindEnum.Kind.DIAMOND:
				canvas.draw_circle(center, lerpf(6.0, 18.0, prog), Color(1.0, 0.20, 0.25, 0.75 if strobe else 0.40))
				canvas.draw_arc(center, lerpf(10.0, 22.0, prog), 0.0, TAU, 20, Color("ff3848"), 2.5)
			else:
				canvas.draw_rect(Rect2(center - Vector2(15, 15), Vector2(30, 30)), Color(1.0, 0.25, 0.30, 0.65 if strobe else 0.25))
				canvas.draw_rect(Rect2(center - Vector2(16, 16), Vector2(32, 32)), Color("ff4858"), false, 2.0)
		else:
			var shine := sin(prog*PI)*0.30
			canvas.draw_line(center+Vector2(-9,-10),center+Vector2(7,5),Color(1,1,1,shine),3.0)
			if prog>0.45:
				var fracture := clampf((prog-0.45)/0.55,0.0,1.0)
				canvas.draw_line(center+Vector2(-10,-7),center.lerp(center+Vector2(11,9),fracture),Color(0.04,0.10,0.20,0.85),2.0)
				canvas.draw_line(center,center.lerp(center+Vector2(9,-10),fracture),Color(1,1,1,0.8),1.0)
			if ttl<=2: canvas.draw_rect(Rect2(center-Vector2(15,15),Vector2(30,30)),Color(1,1,1,0.45))

func draw_power_gem_crystal(canvas: CanvasItem, rect: Rect2i, origin: Vector2, code: int, color_idx: int, player: int = 0) -> void:
	var top := maxi(rect.position.y, 2)
	if rect.end.y <= 2:
		return
	var area_rect := Rect2(
		origin + Vector2(rect.position.x * 32 + 1, (top - 2) * 32 + 1),
		Vector2(rect.size.x * 32 - 2, (rect.end.y - top) * 32 - 2)
	)
	var tex := load_tex("power_crystal_%d.png" % clampi(color_idx, 1, 4))
	var cell_area: int = rect.size.x * rect.size.y
	var intensity := clampf(float(cell_area) / 12.0, 0.25, 1.0)
	var pulse := 0.5 + 0.5 * sin(float(anim_tick) * 0.15)
	var glow_colors := {1: Color("48a8ff"), 2: Color("ffe052"), 3: Color("55eb86"), 4: Color("ff5c70")}
	var glow_col: Color = glow_colors.get(color_idx, Color.WHITE)
	if not temporal_players[player]: canvas.draw_rect(area_rect.grow(2.0 + intensity * 3.0), Color(glow_col.r, glow_col.g, glow_col.b, 0.24 + 0.22 * pulse))
	if tex != null:
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var sc := 20.0
		var dc := 16.0
		var x0 := area_rect.position.x
		var y0 := area_rect.position.y
		var w := area_rect.size.x
		var h := area_rect.size.y
		var xs: Array[float] = [x0, x0 + dc, x0 + w - dc, x0 + w]
		var ys: Array[float] = [y0, y0 + dc, y0 + h - dc, y0 + h]
		var uvs_x: Array[float] = [0.0, sc, tw - sc, tw]
		var uvs_y: Array[float] = [0.0, sc, th - sc, th]
		for ry in range(3):
			for rx in range(3):
				var dst := Rect2(Vector2(xs[rx], ys[ry]), Vector2(xs[rx + 1] - xs[rx], ys[ry + 1] - ys[ry]))
				var src := Rect2(Vector2(uvs_x[rx], uvs_y[ry]), Vector2(uvs_x[rx + 1] - uvs_x[rx], uvs_y[ry + 1] - uvs_y[ry]))
				canvas.draw_texture_rect_region(tex, dst, src)
	# V10.3.4 — facetas por célula; preserva o perímetro da arte base.
	# A arte base (fase "a") preserva a identidade; b/c/d são overlays translúcidos.
	if power_facet_age[player].size() == 84:
		var color_tex := clampi(color_idx, 1, 4)
		for cy in range(rect.size.y):
			for cx in range(rect.size.x):
				var gx: int = rect.position.x + cx
				var gy: int = rect.position.y + cy
				if gy < 2 or gx < 0 or gx >= 6:
					continue
				var phase: int = power_facet_phase(player, gy * 6 + gx)
				if phase <= 0 or phase >= POWER_FACET_SEQUENCE.size() - 1:
					continue
				var overlay := load_tex("power_facet_%d_%s.png" % [color_tex, POWER_FACET_SEQUENCE[phase]])
				if overlay == null:
					continue
				var cell_rect := Rect2(origin + Vector2(gx * 32.0, (gy - 2) * 32.0), Vector2(32.0, 32.0))
				var interior: Rect2 = cell_rect.intersection(area_rect.grow(-4.0))
				if interior.has_area():
					canvas.draw_texture_rect_region(overlay, interior, Rect2(interior.position - cell_rect.position, interior.size))
	if temporal_players[player]: return
	# Varredura de reflexo especular interno na Power Gem
	var sweep_t := fposmod(float(anim_tick) * 0.025 + float(rect.position.x) * 0.17, 1.4)
	if sweep_t <= 1.0:
		var sx_pos := lerpf(area_rect.position.x + 6.0, area_rect.end.x - 14.0, sweep_t)
		canvas.draw_rect(Rect2(sx_pos, area_rect.position.y + 4.0, 8.0, area_rect.size.y - 8.0), Color(1, 1, 1, 0.24))
		canvas.draw_rect(Rect2(sx_pos + 2.0, area_rect.position.y + 4.0, 3.0, area_rect.size.y - 8.0), Color(1, 1, 1, 0.42))
	if not active_wave[player].is_empty() and active_wave[player].phase == "pre":
		for removed in active_wave[player].removed:
			if rect.has_point(Vector2i(removed.x, removed.y)):
				var anticipation := 1.0 - float(active_wave[player].timer) / 10.0
				canvas.draw_rect(area_rect, Color(1,1,1,0.10+0.24*anticipation))
				if anticipation>0.35:
					var center:=area_rect.get_center()
					var fracture:=clampf((anticipation-0.35)/0.65,0.0,1.0)
					for endpoint in [area_rect.position+Vector2(6,6),area_rect.end-Vector2(6,6),Vector2(area_rect.end.x-6,area_rect.position.y+6)]:
						canvas.draw_line(center,center.lerp(endpoint,fracture),Color(0.03,0.08,0.18,0.8),2.0)
						canvas.draw_line(center+Vector2(1,0),center.lerp(endpoint,fracture)+Vector2(1,0),Color(1,1,1,0.7),1.0)
				break
	# Flash de cristalização quando a Power Gem se forma ou expande
	if power_flash_ticks[player] > 0:
		var f_alpha := float(power_flash_ticks[player]) / 14.0 * 0.58
		canvas.draw_rect(area_rect, Color(1, 1, 1, f_alpha))
		canvas.draw_rect(area_rect.grow(2.0), Color.WHITE, false, 2.0)
	# Brilho especular proporcional ao tamanho da Power Gem
	var shatter_tex := load_tex("vfx_muzzle_sas.png")
	if shatter_tex != null and cell_area >= 4:
		var spark_size := 20.0 + intensity * 14.0
		var spark_pos := area_rect.position + Vector2(16, 16)
		canvas.draw_texture_rect(shatter_tex, Rect2(spark_pos - Vector2(spark_size * 0.5, spark_size * 0.5), Vector2(spark_size, spark_size)), false, Color(1, 1, 1, 0.72 + 0.25 * pulse))

func draw_fighter_texture(canvas: CanvasItem, tex: Texture2D, name: String, dst: Rect2, tint: Color) -> void:
	if not BAKED_FLARES.has(name):
		canvas.draw_texture_rect(tex,dst,false,tint)
		return
	var cut: Rect2i = BAKED_FLARES[name]
	var w := tex.get_width()
	var h := tex.get_height()
	var regions := [Rect2i(0,0,w,cut.position.y),Rect2i(0,cut.end.y,w,h-cut.end.y),
		Rect2i(0,cut.position.y,cut.position.x,cut.size.y),Rect2i(cut.end.x,cut.position.y,w-cut.end.x,cut.size.y)]
	for region in regions:
		if region.size.x <= 0 or region.size.y <= 0: continue
		var sc := dst.size / Vector2(w,h)
		canvas.draw_texture_rect_region(tex,Rect2(dst.position+Vector2(region.position)*sc,Vector2(region.size)*sc),Rect2(region),tint)

func fighter_draw_rect(player: int) -> Rect2:
	var seq: Array = fighter_anims[player][fighter_state[player]]
	var key: String = seq[clampi(fighter_anim_frame[player], 0, seq.size() - 1)].tex
	var tex := load_tex(key)
	var scale_base := 0.44 if fighter_native_side[player] == 0 else 0.50
	var scale_mod := Vector2.ONE * scale_base
	var size := Vector2(tex.get_size()) * scale_mod
	var boot_x := float(boot_anchors.get(key, tex.get_width() * 0.5)) * scale_mod.x
	if fighter_mirrored[player]: boot_x = size.x - boot_x
	var anchor_x := 376.0 if player == 0 else 624.0
	var floor_y := float(boot_floors.get(key,tex.get_height())) * scale_mod.y
	var motion := fighter_pos_offset[player]
	if fighter_state[player] in ["idle","danger","shoot","grenade","victory"]:
		motion = Vector2.ZERO
	return Rect2(Vector2(anchor_x-boot_x,492.0-floor_y)+motion,size)

func draw_central_arena_and_hud(canvas: CanvasItem, font: Font, model, next_pairs: Array) -> void:
	# 1. Placa discreta do cenário no topo central
	var stage: Dictionary = STAGES[stage_index]
	draw_outlined_text(canvas, font, Vector2(392, 20), stage["name"] + "  [1/2/3/M]", 13, Color("ffe885"))

	# 2. Emblema central "CS PUZZLE FIGHTER '96" + Caixas NEXT laterais (layout fiel ao CPS-2!)
	var logo_tex := load_tex("hud_logo.png")
	if logo_tex != null:
		canvas.draw_texture_rect(logo_tex, Rect2(382, 24, 236, 178), false)
	for i in range(2):
		var nx := 284.0 if i == 0 else 652.0
		var ny := 56.0
		var nbox := Rect2(nx, ny, 64, 114)
		var team_c := Color("48a8ff") if i == 0 else Color("ff6848")
		# Moldura chanfrada da caixa NEXT
		var nshadow := nbox.grow(6)
		nshadow.position += Vector2(3, 4)
		canvas.draw_rect(nshadow, Color(0, 0, 0, 0.55))
		canvas.draw_rect(nbox.grow(4), Color("161c2e"))
		canvas.draw_rect(nbox.grow(3), team_c, false, 2.0)
		canvas.draw_rect(nbox, Color("090d16"))
		canvas.draw_rect(nbox, Color("d8e6ff"), false, 2.0)
		draw_outlined_text(canvas, font, Vector2(nx + 4, ny - 8), "NEXT", 18, Color.WHITE, team_c.darkened(0.45), 2)
		# Nome do personagem abaixo da caixa NEXT (como "RYU" e "KEN" no CPS-2!)
		var char_label: String = selected_characters[i].name if not selected_characters.is_empty() else ("SAS" if i == 0 else "PHOENIX")
		var name_x := nx + 10.0 if i == 0 else nx - 10.0
		draw_outlined_text(canvas, font, Vector2(name_x, ny + 136), char_label, 12 if char_label.length() > 9 else 18, Color("ffe052"), Color("140c08"), 2)
		# As duas gemas da próxima dupla serão desenhadas pelo main.gd usando draw_gem_sprite

	# 3. Lutadores Chibi na Arena Central — Animação Real Quadro a Quadro com Ancoragem nos Pés
	var base_anchors_x: Array[float] = [376.0, 624.0]
	for band in range(5):
		var bw := 142.0 - float(band) * 18.0
		var bh := 4.0
		var by_off := 476.0 + float(band) * 3.0
		canvas.draw_rect(Rect2(base_anchors_x[0] + fighter_pos_offset[0].x * 0.5 - bw * 0.5, by_off, bw, bh), Color(0, 0, 0, 0.38))
		canvas.draw_rect(Rect2(base_anchors_x[1] + fighter_pos_offset[1].x * 0.5 - bw * 0.5, by_off, bw, bh), Color(0, 0, 0, 0.38))
	for i in range(2):
		var p_anims: Dictionary = fighter_anims.get(i, fighter_anims[0])
		var seq: Array = p_anims.get(fighter_state[i], p_anims["idle"])
		var frame_idx := clampi(fighter_anim_frame[i], 0, maxi(0, seq.size() - 1))
		var tex_name: String = seq[frame_idx]["tex"] if not seq.is_empty() else ("sas_idle_0.png" if i == 0 else "phoenix_idle_0.png")
		var f_tex := load_tex(tex_name)
		if f_tex == null:
			continue
		var draw_rect := fighter_draw_rect(i)
		var f_mod := Color.WHITE
		if fighter_flash[i] == 1:
			f_mod = Color(2.2, 2.2, 2.2, 1.0)
		elif fighter_flash[i] == 2:
			f_mod = Color(1.6, 0.55, 0.55, 1.0)
		elif fighter_state[i] == "defeat":
			f_mod = Color(0.72, 0.72, 0.82, 1.0)
		if fighter_mirrored[i]:
			canvas.draw_set_transform(Vector2(draw_rect.get_center().x * 2.0,0),0,Vector2(-1,1))
		draw_fighter_texture(canvas,f_tex,tex_name,draw_rect,f_mod)
		canvas.draw_set_transform(Vector2.ZERO)
		if not selected_characters.is_empty() and selected_characters[i].temporary:
			draw_outlined_text(canvas,font,Vector2(base_anchors_x[i]-56,510),"ARTE TEMPORARIA",11,Color("ffcc88"))
		# Indicadores visuais extras de estado (gotas de tensão em Danger, estrelas de KO em Defeat)
		if fighter_state[i] == "danger" and (anim_tick / 10) % 2 == 0:
			var sweat_x := base_anchors_x[i] + (-48.0 if i == 0 else 44.0)
			var sweat_y := 312.0 + float(anim_tick % 10) * 1.4
			canvas.draw_rect(Rect2(sweat_x, sweat_y, 4, 8), Color("68e8ff"))
			canvas.draw_rect(Rect2(sweat_x + 1, sweat_y + 1, 2, 4), Color.WHITE)
		elif fighter_state[i] == "defeat":
			for st_idx in range(3):
				var ang := float(anim_tick) * 0.14 + float(st_idx) * TAU / 3.0
				var star_x := base_anchors_x[i] + cos(ang) * 34.0
				var star_y := 292.0 + sin(ang) * 9.0
				canvas.draw_rect(Rect2(star_x - 3, star_y - 3, 6, 6), Color("ffe852"))
				canvas.draw_rect(Rect2(star_x - 1, star_y - 1, 2, 2), Color.WHITE)

	# 4. Placas de SCORE chanfradas, emblema VS cromado e troféus V no rodapé central (fiel ao CPS-2!)
	for i in range(2):
		var sx := 280.0 if i == 0 else 544.0
		var sy := 520.0
		var splate := Rect2(sx, sy, 176, 56)
		var p_col := Color("4878d8") if i == 0 else Color("c85068")
		var sshadow := splate.grow(4)
		sshadow.position += Vector2(2, 4)
		canvas.draw_rect(sshadow, Color(0, 0, 0, 0.55))
		canvas.draw_rect(splate.grow(2), Color("141826"))
		canvas.draw_rect(splate, p_col.darkened(0.25))
		canvas.draw_rect(splate.grow(-3), p_col.darkened(0.45))
		canvas.draw_rect(splate, Color("e6f0ff"), false, 2.0)
		draw_outlined_text(canvas, font, Vector2(sx + 10, sy + 4), "SCORE", 18, Color("ff9ce6") if i == 0 else Color("9cd8ff"), Color("12081c"), 2)
		var score_str := "%07d" % int(model.scores[i])
		var digit_col := Color("d8ff52") if i == 0 else Color("68fff0")
		draw_outlined_text(canvas, font, Vector2(sx + 14, sy + 42), score_str, 28, digit_col, Color("0a101c"), 3)
		# Ícones V de vitórias abaixo do placar
		var v_tex := load_tex("hud_v.png")
		if v_tex != null:
			var v_count := maxi(1, wins[i])
			for v_idx in range(mini(v_count, 3)):
				var vx := sx + 68.0 + v_idx * 34.0
				var vy := sy + 62.0
				var v_mod := Color.WHITE if wins[i] > v_idx else Color(0.45, 0.48, 0.55, 0.75)
				canvas.draw_texture_rect(v_tex, Rect2(vx, vy, 30, 28), false, v_mod)

	var vs_tex := load_tex("hud_vs.png")
	if vs_tex != null:
		canvas.draw_texture_rect(vs_tex, Rect2(458, 502, 84, 74), false)

func draw_foreground_vfx(canvas: CanvasItem, font: Font) -> void:
	# Cápsulas de latão deflagradas (M4A1-S e AK-47) quicando no chão
	for sh in shell_casings:
		var sx := float(sh["x"])
		var sy := float(sh["y"])
		canvas.draw_set_transform(Vector2(sx,sy),float(sh["rot"]))
		canvas.draw_rect(Rect2(-4,-2,8,4),Color("3b2408"))
		canvas.draw_rect(Rect2(-3,-1,6,2),Color("ffd858"))
		canvas.draw_rect(Rect2(-2,-1,2,1),Color.WHITE)
		canvas.draw_set_transform(Vector2.ZERO)

	# Projéteis (Traçantes de M4A1-S / AK-47 e Granadas HE em arco parabólico)
	var gren_tex := load_tex("vfx_grenade.png")
	for proj in projectiles:
		var pos := projectile_position(proj)
		var x := pos.x
		var y := pos.y
		if proj["kind"] == "he":
			if gren_tex != null:
				canvas.draw_set_transform(pos,float(proj["t"]) * TAU * (1.0 if int(proj.owner)==0 else -1.0))
				canvas.draw_texture_rect(gren_tex,Rect2(-12,-15,24,30),false)
				canvas.draw_set_transform(Vector2.ZERO)
		else:
			var beam_col := Color("7ce8ff") if int(proj["owner"]) == 0 else Color("ffcf52")
			canvas.draw_rect(Rect2(x - 24, y - 4, 48, 8), Color(beam_col.r, beam_col.g, beam_col.b, 0.45))
			canvas.draw_rect(Rect2(x - 18, y - 2, 36, 4), Color.WHITE)

	# ESTÁGIO 2 DA DESTRUIÇÃO: Flashes luminosos rápidos de impacto e iluminação localizada
	for imp in impact_flashes:
		var ipos: Vector2 = imp["pos"]
		var icol: Color = imp["color"]
		var irad := float(imp["radius"])
		var ittl := float(imp["ttl"]) / float(maxi(1, int(imp["max_ttl"])))
		canvas.draw_circle(ipos, irad * (1.3 - 0.3 * ittl), Color(icol.r, icol.g, icol.b, 0.42 * ittl))
		canvas.draw_circle(ipos, irad * 0.55 * ittl, Color(1.0, 1.0, 1.0, 0.92 * ittl))
		var flare_len := irad * (0.85 + 0.35 * (1.0 - ittl))
		canvas.draw_line(ipos - Vector2(flare_len, 0), ipos + Vector2(flare_len, 0), Color(1, 1, 1, 0.85 * ittl), 2.5)
		canvas.draw_line(ipos - Vector2(0, flare_len), ipos + Vector2(0, flare_len), Color(1, 1, 1, 0.85 * ittl), 2.5)

	# ESTÁGIO 3 DA DESTRUIÇÃO: Spritesheets reais de 6 quadros (Explosões, Shatter, Relâmpagos, Shockwaves)
	for fx in vfx_sprites:
		var progress := 1.0 - float(fx["ttl"]) / float(maxi(1, int(fx["max_ttl"])))
		var tex_name := str(fx["tex"])
		if tex_name == "vfx_explosion.png":
			tex_name = "vfx_explosion_%d.png" % clampi(int(progress * 6.0), 0, 5)
		elif tex_name == "vfx_shatter.png":
			tex_name = "vfx_shatter_%d.png" % clampi(int(progress * 6.0), 0, 5)
		var ftex := load_tex(tex_name)
		if ftex == null:
			ftex = load_tex(str(fx["tex"]))
		if ftex == null:
			continue
		var sc := lerpf(float(fx["start_scale"]), float(fx["end_scale"]), progress)
		var alpha := clampf(1.0 - pow(progress, 1.8), 0.0, 1.0)
		var fsize := Vector2(ftex.get_width(), ftex.get_height()) * sc
		var c: Color = fx["color"]
		var fx_position: Vector2 = fx["pos"]
		if fx.has("muzzle_owner"): fx_position = attachment_position(int(fx.muzzle_owner),fx.attachment)
		canvas.draw_set_transform(fx_position, float(fx["rot"]))
		canvas.draw_texture_rect(ftex, Rect2(-fsize * 0.5, fsize), false, Color(c.r, c.g, c.b, alpha))
		canvas.draw_set_transform(Vector2.ZERO)

	# ESTÁGIOS 4 & 5 DA DESTRUIÇÃO: Fragmentos de cristais em pixel art (vfx_shard) e dissipação cintilante
	for sp in gem_sparks:
		if int(sp.get("delay",0))>0: continue
		if sp.has("bounds") and not sp.bounds.has_point(Vector2(float(sp.x),float(sp.y))): continue
		var ttl_i := int(sp["ttl"])
		# Cintilação de dissipação estilo CPS-2 nos últimos 7 ticks
		if ttl_i <= 7 and (ttl_i % 2 == 1):
			continue
		var sx := float(sp["x"])
		var sy := float(sp["y"])
		var sz := float(sp["size"])
		var sc_col: Color = sp["color"]
		var life_ratio := float(ttl_i) / float(maxi(1, int(sp["max_ttl"])))
		var salpha := clampf(life_ratio * 1.4, 0.0, 1.0)
		var c_idx := int(sp.get("color_idx", 1))
		var var_idx := int(sp.get("variant", 0))
		var shard_tex := load_tex("vfx_shard_%d_%d.png" % [c_idx, var_idx])
		if shard_tex != null:
			var scale_f := clampf(0.65 + 0.55 * life_ratio, 0.45, 1.2) * float(sp.get("base_scale",1.0))
			var s_size := Vector2(shard_tex.get_width(), shard_tex.get_height()) * scale_f
			canvas.draw_set_transform(Vector2(sx, sy), float(sp.get("rotation", 0.0)))
			canvas.draw_texture_rect(shard_tex, Rect2(-s_size * 0.5, s_size), false, Color(1, 1, 1, salpha))
			canvas.draw_set_transform(Vector2.ZERO)
		else:
			canvas.draw_rect(Rect2(sx - sz * 0.5 - 1.0, sy - sz * 0.5 - 1.0, sz + 2.0, sz + 2.0), Color(0.05, 0.06, 0.1, salpha * 0.85))
			canvas.draw_rect(Rect2(sx - sz * 0.5, sy - sz * 0.5, sz, sz), Color(sc_col.r, sc_col.g, sc_col.b, salpha))
			canvas.draw_rect(Rect2(sx - sz * 0.25, sy - sz * 0.25, maxf(2.0, sz * 0.45), maxf(2.0, sz * 0.45)), Color(1.0, 1.0, 1.0, salpha))

	# Popups flutuantes de pontuação nos tabuleiros
	for pop in board_popups:
		var ppos: Vector2 = pop["pos"]
		var palpha := clampf(float(pop["ttl"]) / float(maxi(1, int(pop["max_ttl"]))) * 1.4, 0.0, 1.0)
		var pcol: Color = pop["color"]
		var prim := Color(0.04, 0.06, 0.12, palpha)
		draw_outlined_text(canvas, font, ppos + Vector2(-24, 0), str(pop["text"]), 16, Color(pcol.r, pcol.g, pcol.b, palpha), prim, 2)
		var psub := str(pop.get("sub", ""))
		if psub != "":
			draw_outlined_text(canvas, font, ppos + Vector2(-18, 15), psub, 12, Color(1.0, 1.0, 1.0, palpha), prim, 2)

	# Multiplicadores de Cadeia estilo Arcade CPS-2 ("2 CHAIN!", "3 CHAIN!", "4 CHAIN!", "5 CHAIN!", "C4 BLAST!")
	for i in range(2):
		if not chain_banners[i].is_empty():
			var cb: Dictionary = chain_banners[i]
			var b_orig: Vector2 = cb["origin"]
			var ttl_b := int(cb["ttl"])
			var max_b := maxi(1, int(cb["max_ttl"]))
			var age := max_b - ttl_b
			var alpha_b := clampf(float(ttl_b) / 10.0, 0.0, 1.0)
			var c_num := int(cb["chain"])
			var is_c4_b := bool(cb.get("is_c4", false))
			var txt := str(cb["text"])
			var bounce_y := -sin(clampf(float(age) / 8.0, 0.0, 1.0) * PI) * 8.0
			var f_sz := 24 + mini(c_num, 5) * 2
			while f_sz > 16 and font.get_string_size(txt,HORIZONTAL_ALIGNMENT_LEFT,-1,f_sz).x > 182.0: f_sz -= 1
			var bx := b_orig.x + (192.0-font.get_string_size(txt,HORIZONTAL_ALIGNMENT_LEFT,-1,f_sz).x)*0.5
			var by := b_orig.y + 446.0 + bounce_y
			var top_col := Color("fff89c") if (age % 4 < 2) else Color("ffc828")
			var bot_col := Color("ff4824") if (c_num >= 4 or is_c4_b) else Color("ff8818")
			top_col.a = alpha_b
			bot_col.a = alpha_b
			var out_col := Color(0.04, 0.05, 0.10, alpha_b)
			draw_outlined_text(canvas, font, Vector2(bx + 3, by + 3), txt, f_sz, out_col, out_col, 4)
			draw_outlined_text(canvas, font, Vector2(bx, by + 1), txt, f_sz, bot_col, out_col, 3)
			draw_outlined_text(canvas, font, Vector2(bx, by - 1), txt, f_sz, top_col, out_col, 2)

	# Callouts de Combo / Ataque Especial em tipografia 3D CPS-2 (sem caixas opacas sobre o cenário!)
	for i in range(2):
		if callout_timer[i] > 0 and callout_text[i] != "":
			var bx := 292.0 if i == 0 else 520.0
			var by := 232.0 + (0 if i == 0 else 28)
			var main_col := Color("ffe852") if i == 0 else Color("ff9848")
			var rim_col := Color("103888") if i == 0 else Color("781408")
			var title_size := 19
			while title_size > 12 and font.get_string_size(callout_text[i],HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x > 198.0: title_size -= 1
			draw_outlined_text(canvas, font, Vector2(bx + 2, by + 2), callout_text[i], title_size, Color("06080e"), Color("06080e"), 3)
			draw_outlined_text(canvas, font, Vector2(bx, by), callout_text[i], title_size, main_col, rim_col, 2)
			if callout_sub[i] != "":
				var sub_size := 13
				while sub_size > 9 and font.get_string_size(callout_sub[i],HORIZONTAL_ALIGNMENT_LEFT,-1,sub_size).x > 198.0: sub_size -= 1
				draw_outlined_text(canvas, font, Vector2(bx + 2, by + 18), callout_sub[i], sub_size, Color.WHITE, Color("080c16"), 2)
