extends SceneTree

const BRAIN_DIR := "C:/Projetos/CS-Puzzle-Fighter-96/arte/fontes"
const OUT_DIR := "C:/Projetos/CS-Puzzle-Fighter-96/godot/assets/sprites"

func is_magenta_bg(c: Color) -> bool:
	# Magenta background (#FF00FF with JPEG tolerance)
	return c.r > 0.55 and c.b > 0.55 and c.g < 0.42 and (c.r + c.b - c.g * 2.0) > 0.75

func clean_magenta_sheet(path: String) -> Image:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if is_magenta_bg(c):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				# Despill any slight magenta fringe on dark outline pixels
				var spill := minf(c.r, c.b) - c.g
				if spill > 0.22 and c.g < 0.35:
					c.r = maxf(0.0, c.r - spill * 0.75)
					c.b = maxf(0.0, c.b - spill * 0.75)
					img.set_pixel(x, y, c)
	return img

func extract_n_items(img: Image, prefix: String, names: Array, mirror: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var n_count := names.size()
	var labels := PackedInt32Array()
	labels.resize(w * h)
	labels.fill(-1)
	var comp_pixels: Array = []
	var comp_rects: Array[Rect2i] = []
	var comp_cx: Array[float] = []
	var queue: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			var idx := y * w + x
			if labels[idx] != -1 or img.get_pixel(x, y).a <= 0.1:
				continue
			var cid := comp_pixels.size()
			var pts: Array[Vector2i] = []
			var min_x := x; var max_x := x; var min_y := y; var max_y := y
			var sum_x := 0.0
			queue.clear()
			queue.append(Vector2i(x, y))
			labels[idx] = cid
			var head := 0
			while head < queue.size():
				var p := queue[head]
				head += 1
				pts.append(p)
				sum_x += float(p.x)
				if p.x < min_x: min_x = p.x
				if p.x > max_x: max_x = p.x
				if p.y < min_y: min_y = p.y
				if p.y > max_y: max_y = p.y
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if dx == 0 and dy == 0: continue
						var nx := p.x + dx
						var ny := p.y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							var nidx := ny * w + nx
							if labels[nidx] == -1 and img.get_pixel(nx, ny).a > 0.1:
								labels[nidx] = cid
								queue.append(Vector2i(nx, ny))
			comp_pixels.append(pts)
			comp_rects.append(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
			comp_cx.append(sum_x / float(pts.size()))
	var order: Array[int] = []
	for i in range(comp_pixels.size()):
		order.append(i)
	order.sort_custom(func(a, b): return comp_pixels[a].size() > comp_pixels[b].size())
	var main_ids: Array[int] = []
	for i in range(n_count):
		main_ids.append(order[i])
	main_ids.sort_custom(func(a, b): return comp_cx[a] < comp_cx[b])
	var pose_groups: Array = []
	for p_idx in range(n_count):
		pose_groups.append([main_ids[p_idx]])
	for cid in range(comp_pixels.size()):
		if cid in main_ids or comp_pixels[cid].size() < 8:
			continue
		var best_p := 0
		var best_dist := 1e18
		var r: Rect2i = comp_rects[cid]
		var center := Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5)
		for p_idx in range(n_count):
			var mr: Rect2i = comp_rects[main_ids[p_idx]]
			var mc := Vector2(mr.position.x + mr.size.x * 0.5, mr.position.y + mr.size.y * 0.5)
			var d := center.distance_squared_to(mc)
			if center.x < mr.position.x + mr.size.x * 0.28 and p_idx > 0:
				d += 500000.0
			if d < best_dist:
				best_dist = d
				best_p = p_idx
		pose_groups[best_p].append(cid)
	for i in range(n_count):
		if str(names[i]) == "":
			continue
		var cids: Array = pose_groups[i]
		var union_rect: Rect2i = comp_rects[cids[0]]
		for cid in cids:
			union_rect = union_rect.merge(comp_rects[cid])
		var sub := Image.create(union_rect.size.x, union_rect.size.y, false, Image.FORMAT_RGBA8)
		sub.fill(Color(0, 0, 0, 0))
		for cid in cids:
			for pt in comp_pixels[cid]:
				sub.set_pixel(pt.x - union_rect.position.x, pt.y - union_rect.position.y, img.get_pixel(pt.x, pt.y))
		if mirror:
			sub.flip_x()
		var out_path := "%s/%s_%s.png" % [OUT_DIR, prefix, names[i]]
		sub.save_png(out_path)
		print("Saved 2D component ", out_path, " size=", sub.get_size())

func is_dark_bg(c: Color, bg: Color) -> bool:
	var dist := absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b)
	return dist < 0.14 and c.get_luminance() < 0.18

func extract_grid_4x4(path: String) -> void:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var cw := w / 4
	var ch := h / 4
	var bg := img.get_pixel(4, 4)
	var grid_names := [
		["gem_normal_1", "gem_normal_2", "gem_normal_3", "gem_normal_4"],
		["gem_crash_1", "gem_crash_2", "gem_crash_3", "gem_crash_4"],
		["gem_diamond", "vfx_muzzle_sas", "vfx_muzzle_phoenix", "vfx_grenade"],
		["vfx_explosion", "vfx_shatter", "vfx_shockwave", "vfx_lightning"]
	]
	for gy in range(4):
		for gx in range(4):
			var cell := img.get_region(Rect2i(gx * cw, gy * ch, cw, ch))
			# Flood fill from cell border so internal dark outlines of gems stay opaque
			var visited := PackedByteArray()
			visited.resize(cw * ch)
			var queue: Array[Vector2i] = []
			for x in range(cw):
				queue.append(Vector2i(x, 0))
				queue.append(Vector2i(x, ch - 1))
			for y in range(ch):
				queue.append(Vector2i(0, y))
				queue.append(Vector2i(cw - 1, y))
			var head := 0
			while head < queue.size():
				var p := queue[head]
				head += 1
				if p.x < 0 or p.x >= cw or p.y < 0 or p.y >= ch:
					continue
				var idx := p.y * cw + p.x
				if visited[idx] != 0:
					continue
				var c := cell.get_pixel(p.x, p.y)
				if is_dark_bg(c, bg):
					visited[idx] = 1
					cell.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
					queue.append(Vector2i(p.x + 1, p.y))
					queue.append(Vector2i(p.x - 1, p.y))
					queue.append(Vector2i(p.x, p.y + 1))
					queue.append(Vector2i(p.x, p.y - 1))
			# For luminous VFX sprites, remove dark outlines and convert dark pixels to smooth alpha glow
			var name: String = grid_names[gy][gx]
			if name.begins_with("vfx_") and name != "vfx_grenade":
				for y in range(ch):
					for x in range(cw):
						var c := cell.get_pixel(x, y)
						if c.a <= 0.0:
							continue
						var max_ch := maxf(c.r, maxf(c.g, c.b))
						var lum := c.get_luminance()
						if max_ch < 0.32 or lum < 0.20:
							cell.set_pixel(x, y, Color(0, 0, 0, 0))
						elif max_ch < 0.62:
							var a := clampf((max_ch - 0.32) / 0.30, 0.0, 1.0)
							cell.set_pixel(x, y, Color(c.r, c.g, c.b, a))
			# Tight bounding box crop
			var min_x := cw - 1
			var max_x := 0
			var min_y := ch - 1
			var max_y := 0
			for y in range(ch):
				for x in range(cw):
					if cell.get_pixel(x, y).a > 0.05:
						if x < min_x: min_x = x
						if x > max_x: max_x = x
						if y < min_y: min_y = y
						if y > max_y: max_y = y
			var cropped := cell.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
			# Make square canvas for gems so they center cleanly
			if name.begins_with("gem_"):
				var side := maxi(cropped.get_width(), cropped.get_height())
				var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
				sq.fill(Color(0, 0, 0, 0))
				var ox := (side - cropped.get_width()) / 2
				var oy := (side - cropped.get_height()) / 2
				sq.blit_rect(cropped, Rect2i(0, 0, cropped.get_width(), cropped.get_height()), Vector2i(ox, oy))
				cropped = sq
			var out_path := "%s/%s.png" % [OUT_DIR, name]
			cropped.save_png(out_path)
			print("Saved ", out_path, " size=", cropped.get_size())

const DIGIT_BITMAPS := {
	1: [
		"0011100",
		"0111100",
		"1101100",
		"0001100",
		"0001100",
		"0001100",
		"0001100",
		"0001100",
		"1111111"
	],
	2: [
		"0111110",
		"1111111",
		"1100011",
		"0000110",
		"0011100",
		"0110000",
		"1100000",
		"1111111",
		"1111111"
	],
	3: [
		"0111110",
		"1111111",
		"1100011",
		"0001110",
		"0001110",
		"0000011",
		"1100011",
		"1111111",
		"0111110"
	],
	4: [
		"0001110",
		"0011110",
		"0110110",
		"1100110",
		"1100110",
		"1111111",
		"1111111",
		"0000110",
		"0000110"
	],
	5: [
		"1111111",
		"1111111",
		"1100000",
		"1111110",
		"1111111",
		"0000011",
		"1100011",
		"1111111",
		"0111110"
	]
}

func build_counter_gems() -> void:
	for color_idx in range(1, 5):
		var base_img := Image.load_from_file("%s/gem_normal_%d.png" % [OUT_DIR, color_idx])
		base_img.convert(Image.FORMAT_RGBA8)
		var w := base_img.get_width()
		var h := base_img.get_height()
		var cx := w * 0.5
		var cy := h * 0.5
		var r_outer := w * 0.36
		var r_inner := w * 0.29
		for count in range(1, 6):
			var img := base_img.duplicate() as Image
			# Add dark metallic recessed timer dial in the center while preserving outer crystal facets
			for y in range(h):
				for x in range(w):
					var c := img.get_pixel(x, y)
					if c.a <= 0.05: continue
					var d := Vector2(x - cx, y - cy).length()
					if d < r_inner:
						img.set_pixel(x, y, c.darkened(0.62))
					elif d < r_outer:
						# Metallic gold/steel bezel ring around the countdown dial
						var ring_col := Color("ffd86b") if (x + y) % 12 < 6 else Color("967030")
						img.set_pixel(x, y, c.lerp(ring_col, 0.82))
			# Stamp 3D CPS-2 arcade countdown digit (7x9 scaled by 10x)
			var bmp: Array = DIGIT_BITMAPS[count]
			var scale := maxi(1, w / 18)
			var dw := 7 * scale
			var dh := 9 * scale
			var ox := int(cx - dw * 0.5)
			var oy := int(cy - dh * 0.5)
			# First pass: thick black outline + drop shadow
			for by in range(9):
				var row_str: String = bmp[by]
				for bx in range(7):
					if row_str[bx] != "1": continue
					for sy in range(-scale, scale * 2 + 2):
						for sx in range(-scale, scale * 2 + 2):
							var px := ox + bx * scale + sx
							var py := oy + by * scale + sy
							if px >= 0 and px < w and py >= 0 and py < h:
								img.set_pixel(px, py, Color("0b0d14"))
			# Second pass: glossy gradient numeral (white->gold->orange)
			for by in range(9):
				var row_str: String = bmp[by]
				var t := float(by) / 8.0
				var fill_col := Color.WHITE.lerp(Color("ffe052"), clampf(t * 1.4, 0.0, 1.0))
				if count == 1:
					fill_col = Color.WHITE.lerp(Color("ff6852"), clampf(t * 1.4, 0.0, 1.0))
				for bx in range(7):
					if row_str[bx] != "1": continue
					for sy in range(scale):
						for sx in range(scale):
							var px := ox + bx * scale + sx
							var py := oy + by * scale + sy
							if px >= 0 and px < w and py >= 0 and py < h:
								img.set_pixel(px, py, fill_col)
			var out_path := "%s/gem_counter_%d_%d.png" % [OUT_DIR, color_idx, count]
			img.save_png(out_path)
			print("Saved ", out_path)

func build_power_crystals() -> void:
	var palettes := {
		1: {"base": Color("1c68e8"), "mid": Color("3898ff"), "hi": Color("9ce8ff"), "deep": Color("0d2d7a"), "rim": Color("ccf4ff")},
		2: {"base": Color("e09814"), "mid": Color("ffc828"), "hi": Color("fff69c"), "deep": Color("7a4406"), "rim": Color("fffacc")},
		3: {"base": Color("149e48"), "mid": Color("32d86e"), "hi": Color("9cffbc"), "deep": Color("084d22"), "rim": Color("ccffde")},
		4: {"base": Color("d41c38"), "mid": Color("ff425e"), "hi": Color("ff9cb0"), "deep": Color("6e0818"), "rim": Color("ffd0da")}
	}
	var s := 96
	var bev := 16
	for color_idx in range(1, 5):
		var pal: Dictionary = palettes[color_idx]
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(s):
			for x in range(s):
				# Chamfered octagonal corners (4px cut)
				var cx_dist := mini(x, s - 1 - x)
				var cy_dist := mini(y, s - 1 - y)
				if cx_dist + cy_dist < 5:
					continue
				if cx_dist + cy_dist < 7 or x < 2 or x >= s - 2 or y < 2 or y >= s - 2:
					img.set_pixel(x, y, Color("090c14"))
					continue
				if x == 2 or y == 2 or cx_dist + cy_dist == 7:
					img.set_pixel(x, y, pal["rim"])
					continue
				var d_left := x
				var d_top := y
				var d_right := s - 1 - x
				var d_bot := s - 1 - y
				var min_d := mini(mini(d_left, d_right), mini(d_top, d_bot))
				var col: Color = pal["base"]
				if min_d < bev:
					# Outer 3D crystal bevel facets (top/left lit, bottom/right shaded)
					if d_top <= d_left and d_top <= d_right and d_top <= d_bot:
						col = pal["hi"].lerp(pal["mid"], float(d_top) / float(bev))
					elif d_left <= d_top and d_left <= d_right and d_left <= d_bot:
						col = pal["mid"].lerp(pal["hi"], 0.55 - 0.35 * float(d_left) / float(bev))
					elif d_bot <= d_right:
						col = pal["deep"].lerp(pal["base"], float(d_bot) / float(bev) * 0.5)
					else:
						col = pal["deep"].lerp(pal["base"], float(d_right) / float(bev) * 0.65)
					# Diagonal corner facet ridge lines
					if abs(d_left - d_top) <= 1 or abs(d_right - d_top) <= 1 or abs(d_left - d_bot) <= 1 or abs(d_right - d_bot) <= 1:
						col = col.lightened(0.38)
				else:
					# Inner crystal core with radial luminescence and diagonal sheen
					var nx := (float(x) - 48.0) / 32.0
					var ny := (float(y) - 48.0) / 32.0
					var r2 := clampf(1.0 - sqrt(nx * nx + ny * ny) * 0.72, 0.0, 1.0)
					col = pal["base"].lerp(pal["mid"], r2 * 0.75).lerp(pal["hi"], pow(r2, 2.4) * 0.55)
					var diag := (x + y) % 28
					if diag >= 10 and diag <= 13:
						col = col.lightened(0.22)
					elif diag == 14:
						col = col.darkened(0.12)
					if min_d == bev:
						col = pal["rim"].lerp(col, 0.35)
				img.set_pixel(x, y, col)
		var out_path := "%s/power_crystal_%d.png" % [OUT_DIR, color_idx]
		img.save_png(out_path)
		print("Saved ", out_path)

func build_crash_orbs() -> void:
	# Orbes de vidro translúcidas estilo Super Puzzle Fighter II Turbo (sem garras ou molduras metálicas)
	var palettes := {
		1: {
			"outline": Color("061028"),
			"rim_hi": Color("8cf4ff"),
			"rim_mid": Color("2488ff"),
			"rim_deep": Color("0a3488"),
			"glass": Color(0.04, 0.16, 0.42, 0.56),
			"core_mid": Color("289cff"),
			"core_hi": Color("9cf8ff"),
			"bounce": Color("48c8ff")
		},
		2: {
			"outline": Color("281404"),
			"rim_hi": Color("fff898"),
			"rim_mid": Color("ffbc18"),
			"rim_deep": Color("8c4804"),
			"glass": Color(0.36, 0.18, 0.02, 0.56),
			"core_mid": Color("ffc820"),
			"core_hi": Color("fffca8"),
			"bounce": Color("ffe058")
		},
		3: {
			"outline": Color("042410"),
			"rim_hi": Color("9cffb8"),
			"rim_mid": Color("1cd85c"),
			"rim_deep": Color("066424"),
			"glass": Color(0.02, 0.28, 0.10, 0.56),
			"core_mid": Color("24e068"),
			"core_hi": Color("b4ffd0"),
			"bounce": Color("58ff94")
		},
		4: {
			"outline": Color("2a040c"),
			"rim_hi": Color("ff9cb0"),
			"rim_mid": Color("ff2444"),
			"rim_deep": Color("840618"),
			"glass": Color(0.38, 0.03, 0.08, 0.56),
			"core_mid": Color("ff3250"),
			"core_hi": Color("ffb4c4"),
			"bounce": Color("ff6880")
		}
	}
	var grid := 32
	var scale := 3
	var out_s := grid * scale
	for color_idx in range(1, 5):
		var pal: Dictionary = palettes[color_idx]
		var img := Image.create(out_s, out_s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for gy in range(grid):
			for gx in range(grid):
				var dx := float(gx) - 15.5
				var dy := float(gy) - 15.5
				var r := sqrt(dx * dx + dy * dy)
				if r > 15.2:
					continue
				var col := Color(0, 0, 0, 0)
				var angle_light := (-dx - dy) / (2.0 * maxf(1.0, r)) # +1 top-left, -1 bottom-right
				if r >= 13.9:
					# Silhueta perfeitamente circular com contorno escuro nítido CPS-2
					col = pal["outline"]
				elif r >= 10.8:
					# Borda de vidro espessa e luminosa (anel refratário)
					var rim_t := (r - 10.8) / 3.1
					if angle_light > 0.25:
						col = pal["rim_hi"].lerp(pal["rim_mid"], clampf(1.0 - angle_light * 0.85, 0.0, 1.0))
					elif angle_light > -0.35:
						col = pal["rim_mid"]
					else:
						col = pal["rim_deep"].lerp(pal["bounce"], clampf((1.0 - rim_t) * 0.75, 0.0, 1.0))
					# Reflexo interno luminoso na borda inferior direita
					if angle_light < -0.45 and r >= 11.4 and r <= 12.6:
						col = pal["bounce"].lightened(0.25)
				elif r >= 6.0:
					# Cavidade de vidro parcialmente transparente entre a borda e o núcleo energético
					var cav_t := (r - 6.0) / 4.8
					var g_col: Color = pal["glass"]
					var alpha := lerpf(0.74, 0.50, sin(cav_t * PI))
					if angle_light < -0.35 and r > 8.8:
						g_col = g_col.lerp(Color(pal["bounce"].r, pal["bounce"].g, pal["bounce"].b, 0.78), 0.45)
					col = Color(g_col.r, g_col.g, g_col.b, alpha)
				else:
					# Núcleo energético luminoso suspenso no centro da orbe
					var cdx := float(gx) - 16.0
					var cdy := float(gy) - 16.0
					var cr := sqrt(cdx * cdx + cdy * cdy)
					var core_t := clampf(1.0 - cr / 6.2, 0.0, 1.0)
					col = pal["core_mid"].lerp(pal["core_hi"], pow(core_t, 1.35))
					if cr < 2.4:
						col = col.lerp(Color.WHITE, 0.75)
					col.a = 0.96
				# Brilho branco especular curvo no canto superior esquerdo da esfera de vidro
				var sdx := float(gx) - 10.2
				var sdy := float(gy) - 10.0
				var sr := sqrt(sdx * sdx + sdy * sdy)
				if r >= 7.2 and r <= 12.8 and gx <= 15 and gy <= 15:
					if absf(r - 10.3) <= 1.15 and (gx + gy) >= 17 and (gx + gy) <= 24:
						col = Color.WHITE
					elif absf(r - 10.3) <= 1.85 and (gx + gy) >= 16 and (gx + gy) <= 25:
						col = col.lerp(Color.WHITE, 0.65)
				if sr <= 1.6:
					col = Color.WHITE
				# Ponto secundário de refração cristalina inferior direito
				if gx >= 20 and gx <= 21 and gy >= 20 and gy <= 21:
					col = pal["rim_hi"].lightened(0.35)
				for sy in range(scale):
					for sx in range(scale):
						img.set_pixel(gx * scale + sx, gy * scale + sy, col)
		var out_path := "%s/gem_crash_%d.png" % [OUT_DIR, color_idx]
		img.save_png(out_path)
		print("Saved translucent Crash Orb ", out_path)

func build_c4_sprites() -> void:
	# C4 explosiva do Counter-Strike em pixel art CPS-2 com visor digital e LED vermelho piscando
	var grid := 32
	var scale := 3
	var out_s := grid * scale
	for frame in range(2):
		var img := Image.create(out_s, out_s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for gy in range(grid):
			for gx in range(grid):
				var col := Color(0, 0, 0, 0)
				# Bloco duplo de explosivo plástico C4 (verde-oliva / cáqui militar) de (3, 5) a (28, 27)
				if gx >= 3 and gx <= 28 and gy >= 5 and gy <= 27:
					var is_border := (gx == 3 or gx == 28 or gy == 5 or gy == 27)
					var is_corner := (gx in [3, 28] and gy in [5, 27])
					if is_corner:
						col = Color(0, 0, 0, 0)
					elif is_border or (gx in [4, 27] and gy in [6, 26]):
						col = Color("0b0e14")
					else:
						# Dois pacotes de C4 separados por vinco central em gy == 16
						var pack_hi := Color("9aa668")
						var pack_mid := Color("78844c")
						var pack_deep := Color("4e5830")
						if gy < 9 or gx < 6:
							col = pack_hi
						elif gy > 23 or gx > 25:
							col = pack_deep
						else:
							col = pack_mid
						if gy == 16:
							col = Color("2c321c")
						elif gy == 15:
							col = pack_deep
						elif gy == 17:
							col = pack_hi
						# Fitas isolantes táticas pretas verticais prendendo os blocos (gx 7..9 e gx 22..24)
						if (gx >= 6 and gx <= 8) or (gx >= 23 and gx <= 25):
							col = Color("181c24")
							if gx in [6, 23] and gy < 24:
								col = Color("3c4454")
				# Fios detonadores vermelho e azul saindo do módulo central (gx 9..11, gy 3..6)
				if gy >= 3 and gy <= 6:
					if gx in [10, 11] and (gy == 3 or gx == 10):
						col = Color("0b0e14")
					elif gx == 10 and gy in [4, 5]:
						col = Color("ff3244")
					elif gx == 12 and gy in [4, 5]:
						col = Color("3898ff")
				# Módulo eletrônico central (visor digital + teclado numérico) em gx 9..22, gy 6..25
				if gx >= 9 and gx <= 22 and gy >= 6 and gy <= 25:
					if gx == 9 or gx == 22 or gy == 6 or gy == 25:
						col = Color("0b0e14")
					elif gy == 7 or gx == 10:
						col = Color("768498")
					elif gy == 24 or gx == 21:
						col = Color("2a313d")
					else:
						col = Color("465162")
					# Visor digital LCD (gx 11..20, gy 8..13) com código 7355608 / timer luminoso
					if gx >= 11 and gx <= 20 and gy >= 8 and gy <= 13:
						if gx == 11 or gx == 20 or gy == 8 or gy == 13:
							col = Color("0d1612")
						else:
							col = Color("122c1c") if frame == 0 else Color("1c3f28")
							# Dígitos estilo 7-segmentos brilhantes no visor LCD
							if gy in [9, 11] and gx in [12, 13, 15, 16, 18, 19]:
								col = Color("68ff98") if frame == 0 else Color("ffe868")
							elif gy == 10 and gx in [13, 16, 18, 19]:
								col = Color("68ff98") if frame == 0 else Color("ffe868")
							elif gy == 12 and gx in [13, 15, 16, 19]:
								col = Color("42d874") if frame == 0 else Color("ffc838")
					# Teclado numérico tático 3x3 abaixo do visor (gx 11..19, gy 15..23)
					if gx >= 11 and gx <= 19 and gy >= 15 and gy <= 23:
						if (gx - 11) % 3 != 2 and (gy - 15) % 3 != 2:
							if gx >= 17 and gy >= 21:
								col = Color("ff4858") # tecla vermelha ARM
							elif gx <= 12 and gy >= 21:
								col = Color("ffd848") # tecla amarela
							else:
								col = Color("9aa8bc")
						else:
							col = Color("222832")
				# LED vermelho de ativação da C4 no canto superior direito (centro em gx=24, gy=8)
				var ldx := float(gx) - 24.0
				var ldy := float(gy) - 8.0
				var lr := sqrt(ldx * ldx + ldy * ldy)
				if frame == 0:
					if lr <= 1.5:
						col = Color("ff98a4")
					elif lr <= 2.6:
						col = Color("ff182c")
					elif lr <= 3.4:
						col = Color("18060a")
				else:
					# Frame 1: Pisca intensamente com halo rubro-branco
					if lr <= 1.8:
						col = Color.WHITE
					elif lr <= 3.3:
						col = Color("ff1c30")
					elif lr <= 5.2:
						var ha := clampf(1.0 - (lr - 3.3) / 1.9, 0.0, 1.0)
						var glow := Color(1.0, 0.18, 0.24, ha * 0.85)
						col = col.lerp(glow, ha * 0.85) if col.a > 0.0 else glow
				if col.a > 0.0:
					for sy in range(scale):
						for sx in range(scale):
							img.set_pixel(gx * scale + sx, gy * scale + sy, col)
		var out_path := "%s/gem_c4_%d.png" % [OUT_DIR, frame]
		img.save_png(out_path)
		if frame == 0:
			img.save_png("%s/gem_diamond.png" % OUT_DIR)
		print("Saved C4 sprite ", out_path)

func build_crystal_shards() -> void:
	# Fragmentos de cristal facetados em pixel art CPS-2 para o estágio de fragmentação
	var palettes := {
		1: {"hi": Color("c8f8ff"), "mid": Color("3898ff"), "deep": Color("0c3488"), "out": Color("061024")},
		2: {"hi": Color("fffca8"), "mid": Color("ffc418"), "deep": Color("884804"), "out": Color("241202")},
		3: {"hi": Color("c4ffd8"), "mid": Color("24d864"), "deep": Color("085824"), "out": Color("04200c")},
		4: {"hi": Color("ffc4d0"), "mid": Color("ff2c4c"), "deep": Color("84081c"), "out": Color("280408")},
		5: {"hi": Color("fff4b8"), "mid": Color("ff6824"), "deep": Color("682408"), "out": Color("1c0804")}
	}
	var patterns := [
		[
			"0001110000",
			"0012231000",
			"0122233100",
			"1223344310",
			"1233444431",
			"0133444310",
			"0013443100",
			"0001331000",
			"0000110000",
			"0000000000"
		],
		[
			"00001100",
			"00112310",
			"01223341",
			"12233441",
			"13344410",
			"01344100",
			"00111000",
			"00000000"
		],
		[
			"001100",
			"012210",
			"122341",
			"133441",
			"014410",
			"001100"
		]
	]
	var scale := 2
	for color_idx in range(1, 6):
		var pal: Dictionary = palettes[color_idx]
		for v in range(3):
			var pat: Array = patterns[v]
			var h := pat.size()
			var w := String(pat[0]).length()
			var img := Image.create(w * scale, h * scale, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			for y in range(h):
				var row_s: String = pat[y]
				for x in range(w):
					var ch := row_s[x]
					if ch == "0":
						continue
					var c := Color.WHITE
					if ch == "1": c = pal["out"]
					elif ch == "2": c = pal["hi"]
					elif ch == "3": c = pal["mid"]
					elif ch == "4": c = pal["deep"]
					for sy in range(scale):
						for sx in range(scale):
							img.set_pixel(x * scale + sx, y * scale + sy, c)
			var out_path := "%s/vfx_shard_%d_%d.png" % [OUT_DIR, color_idx, v]
			img.save_png(out_path)

func extract_vfx_strip(path: String, prefix: String, n_frames: int) -> void:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	# Clean pure black background while preserving dark smoke and crystal glints
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var max_ch := maxf(c.r, maxf(c.g, c.b))
			if max_ch <= 0.065:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif max_ch < 0.18:
				var a := clampf((max_ch - 0.065) / 0.115, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	# Find horizontal active span and divide into 6 frame columns using local minima between frames
	var col_energy := PackedFloat32Array()
	col_energy.resize(w)
	var min_active_x := w - 1
	var max_active_x := 0
	for x in range(w):
		var s := 0.0
		for y in range(h):
			var a := img.get_pixel(x, y).a
			if a > 0.05:
				s += a
		col_energy[x] = s
		if s > 0.5:
			if x < min_active_x: min_active_x = x
			if x > max_active_x: max_active_x = x
	var span := float(max_active_x - min_active_x + 1)
	var splits: Array[int] = [ maxi(0, min_active_x - 8) ]
	for i in range(1, n_frames):
		var approx := int(min_active_x + span * float(i) / float(n_frames))
		var best_x := approx
		var best_val := 1e18
		for sx in range(maxi(0, approx - 45), mini(w, approx + 45)):
			if col_energy[sx] < best_val:
				best_val = col_energy[sx]
				best_x = sx
		splits.append(best_x)
	splits.append(mini(w, max_active_x + 8))
	var canvas_side := 220
	for i in range(n_frames):
		var x0 := splits[i]
		var x1 := splits[i + 1]
		var cw := maxi(1, x1 - x0)
		var cell := img.get_region(Rect2i(x0, 0, cw, h))
		var min_x := cw - 1; var max_x := 0; var min_y := h - 1; var max_y := 0
		var found := false
		for y in range(h):
			for x in range(cw):
				if cell.get_pixel(x, y).a > 0.05:
					found = true
					if x < min_x: min_x = x
					if x > max_x: max_x = x
					if y < min_y: min_y = y
					if y > max_y: max_y = y
		var sq := Image.create(canvas_side, canvas_side, false, Image.FORMAT_RGBA8)
		sq.fill(Color(0, 0, 0, 0))
		if found:
			var cropped := cell.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
			if cropped.get_width() > canvas_side or cropped.get_height() > canvas_side:
				var sc := float(canvas_side - 8) / float(maxi(cropped.get_width(), cropped.get_height()))
				cropped.resize(maxi(1, int(cropped.get_width() * sc)), maxi(1, int(cropped.get_height() * sc)), Image.INTERPOLATE_NEAREST)
			var ox := (canvas_side - cropped.get_width()) / 2
			var oy := (canvas_side - cropped.get_height()) / 2
			sq.blit_rect(cropped, Rect2i(0, 0, cropped.get_width(), cropped.get_height()), Vector2i(ox, oy))
		var out_path := "%s/%s_%d.png" % [OUT_DIR, prefix, i]
		sq.save_png(out_path)
		print("Saved VFX frame ", out_path, " split=[", x0, "..", x1, "]")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var sas := clean_magenta_sheet(BRAIN_DIR + "/sas_poses_v1.jpg")
	extract_n_items(sas, "sas", ["idle", "shoot", "grenade", "hit"], false)
	var sas_idle_s := clean_magenta_sheet(BRAIN_DIR + "/sas_idle_strip.jpg")
	extract_n_items(sas_idle_s, "sas", ["idle_0", "idle_1", "", "idle_2"], false)
	var sas_spec_s := clean_magenta_sheet(BRAIN_DIR + "/sas_special_strip.jpg")
	# Separate the contact where Pose 1's muzzle flash tip touches Pose 2's back elbow around x=780..792, y=380..450
	for y in range(370, 460):
		for x in range(780, 793):
			sas_spec_s.set_pixel(x, y, Color(0, 0, 0, 0))
	extract_n_items(sas_spec_s, "sas", ["idle_3", "shoot_0", "shoot_1", "win_0"], false)
	var phx := clean_magenta_sheet(BRAIN_DIR + "/phoenix_poses_v1.jpg")
	extract_n_items(phx, "phoenix", ["idle", "shoot", "grenade", "hit"], true)
	var phx_idle_s := clean_magenta_sheet(BRAIN_DIR + "/phoenix_idle_strip.jpg")
	extract_n_items(phx_idle_s, "phoenix", ["idle_0", "idle_1", "idle_2", "idle_3"], true)
	var hud := clean_magenta_sheet(BRAIN_DIR + "/hud_emblems_v1.jpg")
	extract_n_items(hud, "hud", ["logo", "vs", "v"], false)
	extract_grid_4x4(BRAIN_DIR + "/gems_vfx_sheet_v1.jpg")
	extract_vfx_strip(BRAIN_DIR + "/vfx_explosion_strip.jpg", "vfx_explosion", 6)
	extract_vfx_strip(BRAIN_DIR + "/vfx_shatter_strip.jpg", "vfx_shatter", 6)
	build_crash_orbs()
	build_c4_sprites()
	build_crystal_shards()
	build_counter_gems()
	build_power_crystals()
	var dust2 := Image.load_from_file(BRAIN_DIR + "/stage_dust2.jpg")
	dust2.save_png(OUT_DIR + "/stage_dust2.png")
	var mirage := Image.load_from_file(BRAIN_DIR + "/stage_mirage.jpg")
	mirage.save_png(OUT_DIR + "/stage_mirage.png")
	var inferno := Image.load_from_file(BRAIN_DIR + "/stage_inferno.jpg")
	inferno.save_png(OUT_DIR + "/stage_inferno.png")
	print("PROCESS_SPRITES_OK")
	quit(0)
