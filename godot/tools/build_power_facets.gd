extends SceneTree
## Gera os overlays de facetas internas das Power Gems (V10.3.4).
## Três fases por cor: b, c, d — a fase "a" é a arte base já existente
## (power_crystal_<cor>.png) e não recebe overlay.
## Sequência medida no MAME: A -> B -> C -> D -> C -> B -> A (blocos de 8 quadros).

const OUT_DIR := "C:/Projetos/CS-Puzzle-Fighter-96/godot/assets/sprites"

const PALETTES := {
	1: {"hi": Color("9ce8ff"), "mid": Color("3898ff"), "rim": Color("ccf4ff")},
	2: {"hi": Color("fff69c"), "mid": Color("ffc828"), "rim": Color("fffacc")},
	3: {"hi": Color("9cffbc"), "mid": Color("32d86e"), "rim": Color("ccffde")},
	4: {"hi": Color("ff9cb0"), "mid": Color("ff425e"), "rim": Color("ffd0da")}
}

const PHASE_NAMES := ["b", "c", "d"]

func build_overlay(color_idx: int, phase: int) -> Image:
	var pal: Dictionary = PALETTES[color_idx]
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# t em 0..1 para b..d: a "abertura" da refração interna cresce monotonicamente.
	var t := float(phase) / 3.0  # b=0.333, c=0.666, d=1.0
	for y in range(s):
		for x in range(s):
			# Margem transparente de 1px para não vazar na célula vizinha.
			if x < 1 or y < 1 or x >= s - 1 or y >= s - 1:
				continue
			var fx := float(x) + 0.5
			var fy := float(y) + 0.5
			# Faixa diagonal principal (canto sup. esq. -> inf. dir.), desloca com t.
			var d1 := fx + fy
			var band1 := 20.0 + t * 22.0
			var a1 := clampf(1.0 - absf(d1 - band1) / 4.0, 0.0, 1.0)
			# Faixa diagonal secundária (contra-diagonal), desloca em sentido oposto.
			var d2 := fx - fy + 31.0
			var band2 := 44.0 - t * 22.0
			var a2 := clampf(1.0 - absf(d2 - band2) / 5.0, 0.0, 1.0)
			# Brilho radial central, raio cresce com t.
			var dx := fx - 16.0
			var dy := fy - 16.0
			var r := sqrt(dx * dx + dy * dy)
			var spot := clampf(1.0 - r / (7.0 + t * 8.0), 0.0, 1.0)
			var band_alpha := maxf(a1, a2)
			var alpha := clampf(band_alpha * 0.42 + spot * spot * 0.30, 0.0, 1.0)
			if alpha <= 0.01:
				continue
			var col: Color = pal.hi.lerp(pal.rim, clampf(spot, 0.0, 1.0))
			if band_alpha > spot:
				col = col.lerp(pal.mid, 0.25)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
	return img

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for color_idx in range(1, 5):
		for p in range(1, 4):
			var img: Image = build_overlay(color_idx, p)
			var out_path := "%s/power_facet_%d_%s.png" % [OUT_DIR, color_idx, PHASE_NAMES[p - 1]]
			img.save_png(out_path)
			print("Saved ", out_path)
	print("POWER_FACETS_OK")
	quit(0)
