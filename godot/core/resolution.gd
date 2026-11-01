extends RefCounted

const Gem = preload("res://core/gem_rules.gd")
const Economy = preload("res://core/attack_rules.gd")

static func form_powers(board) -> void:
	var valid: Array[Rect2i] = []
	for rect in board.power_gems:
		var c: int = Gem.color(board.cells[rect.position.y * 6 + rect.position.x])
		if c != 0 and board.indices(rect).all(func(i): return Gem.can_power(board.cells[i], c)):
			valid.append(rect)
	board.power_gems = valid
	# shortcut: desempates entre retÃƒÂ¢ngulos concorrentes ainda precisam de casos irregulares do arcade.
	for _attempt in range(84):
		var best := Rect2i()
		for y in range(12, -1, -1):
			for x in range(5):
				var c: int = Gem.color(board.cells[y * 6 + x])
				if c == 0 or not Gem.can_power(board.cells[y * 6 + x], c): continue
				var width := 6 - x
				for bottom in range(y, mini(14, y + 8)):
					var run := 0
					while run < width and Gem.can_power(board.cells[bottom * 6 + x + run], c): run += 1
					width = mini(width, run)
					if width < 2: break
					if bottom == y: continue
					for w in range(2, width + 1):
						var candidate := Rect2i(x, y, w, bottom - y + 1)
						if candidate.get_area() <= best.get_area() or candidate in board.power_gems: continue
						var compatible := true
						for old in board.power_gems:
							if candidate.intersects(old) and not candidate.encloses(old): compatible = false; break
						if compatible: best = candidate
		if best.get_area() == 0: break
		var kept: Array[Rect2i] = []
		for old in board.power_gems:
			if not best.encloses(old): kept.append(old)
		kept.append(best)
		board.power_gems = kept
		for index in board.indices(best): board.cells[index] = Gem.color(board.cells[index]) | 128

static func gravity_step(board) -> int:
	# Uma cÃƒÂ©lula livre por coluna e quadro; Power Gems continuam corpos rÃƒÂ­gidos.
	var moved: int = 0
	var covered: Dictionary = {}
	for rect in board.power_gems:
		for index in board.indices(rect): covered[index] = true
	for x in range(6):
		for y in range(12,-1,-1):
			var index: int = y*6+x
			if not covered.has(index) and board.cells[index] != 0 and board.cells[index+6] == 0:
				board.cells[index+6] = board.cells[index]
				board.cells[index] = 0
				moved += 1
				break
	for i in range(board.power_gems.size()-1,-1,-1):
		var rect: Rect2i = board.power_gems[i]
		if rect.end.y >= 14: continue
		var free: bool = true
		for x in range(rect.position.x,rect.end.x):
			if board.cells[rect.end.y*6+x] != 0: free = false
		if not free: continue
		for y in range(rect.end.y-1,rect.position.y-1,-1):
			for x in range(rect.position.x,rect.end.x):
				board.cells[(y+1)*6+x] = board.cells[y*6+x]
				board.cells[y*6+x] = 0
		rect.position.y += 1
		board.power_gems[i] = rect
		moved += rect.get_area()
	return moved

static func counter_gravity_step(board) -> int:
	# Em $D058 (fase 19), todas as gemas sem suporte de cada coluna descem 1 linha no mesmo quadro.
	var moved: int = 0
	var covered: Dictionary = {}
	for rect in board.power_gems:
		for index in board.indices(rect): covered[index] = true
	for x in range(6):
		for y in range(12, -1, -1):
			var index: int = y * 6 + x
			if not covered.has(index) and board.cells[index] != 0 and board.cells[index + 6] == 0:
				board.cells[index + 6] = board.cells[index]
				board.cells[index] = 0
				moved += 1
	return moved

static func count_flood_steps(board) -> int:
	# Conta os passos síncronos de propagação ($D3D6 + $D26A + $D462) na fase 8 da CPS-2.
	for i in range(84):
		if Gem.is_diamond(board.cells[i]):
			return 1
	var flags: PackedInt32Array = PackedInt32Array()
	flags.resize(84)
	var steps: int = 0
	for _pass in range(84):
		for i in range(84):
			if (flags[i] & 0x20) != 0:
				flags[i] |= 0x10
		var d5: bool = false
		for x in range(6):
			for y in range(13, 0, -1):
				var idx: int = y * 6 + x
				var c: int = board.cells[idx]
				if c == 0 or Gem.kind(c) == Gem.Kind.COUNTER:
					continue
				if (flags[idx] & 0x20) != 0:
					if (flags[idx] & 0x10) == 0:
						continue
				else:
					if (flags[idx] & 0x40) != 0 or Gem.kind(c) != Gem.Kind.CRASH:
						continue
				flags[idx] = (flags[idx] & ~0x20) | 0x40
				var col: int = Gem.color(c)
				var d4: bool = false
				for n in [idx - 1, idx + 1, idx + 6, idx - 6]:
					if (n == idx - 1 and x == 0) or (n == idx + 1 and x == 5) or n < 0 or n >= 84:
						continue
					var nc: int = board.cells[n]
					if nc != 0 and Gem.kind(nc) != Gem.Kind.COUNTER and (flags[n] & 0x40) == 0 and Gem.color(nc) == col:
						flags[n] |= 0x20
						d4 = true
						d5 = true
		if d5:
			steps += 1
		else:
			break
	return steps

static func gravity(board) -> int:
	var distance := 0
	for _pass in range(14):
		var changed := false
		var covered := {}
		for rect in board.power_gems:
			for i in board.indices(rect): covered[i] = true
		for y in range(12, -1, -1):
			for x in range(6):
				var i := y * 6 + x
				if not covered.has(i) and board.cells[i] != 0 and board.cells[i + 6] == 0:
					board.cells[i + 6] = board.cells[i]
					board.cells[i] = 0
					changed = true
					distance += 1
		for p in range(board.power_gems.size() - 1, -1, -1):
			var rect: Rect2i = board.power_gems[p]
			if rect.end.y >= 14: continue
			var clear := true
			for x in range(rect.position.x, rect.end.x):
				if board.cells[rect.end.y * 6 + x] != 0: clear = false; break
			if not clear: continue
			for y in range(rect.end.y - 1, rect.position.y - 1, -1):
				for x in range(rect.position.x, rect.end.x):
					board.cells[(y + 1) * 6 + x] = board.cells[y * 6 + x]
					board.cells[y * 6 + x] = 0
			rect.position.y += 1
			board.power_gems[p] = rect
			changed = true
			distance += rect.get_area()
		if not changed: break
	return distance

static func advance_counters(board) -> int:
	var converted := 0
	for i in range(84):
		var code: int = board.cells[i]
		if Gem.kind(code) == Gem.Kind.COUNTER:
			var turns := Gem.countdown(code) - 1
			board.cells[i] = Gem.counter(Gem.color(code), turns) if turns > 0 else Gem.color(code)
			if turns <= 0: converted += 1
	return converted

static func crash_groups(board) -> Array:
	var visited := {}
	var groups: Array = []
	for i in range(84):
		if visited.has(i) or Gem.kind(board.cells[i]) != Gem.Kind.CRASH: continue
		var color: int = Gem.color(board.cells[i])
		var group: Array[int] = [i]
		visited[i] = true
		var head := 0
		while head < group.size():
			for next in board.neighbors(group[head]):
				if not visited.has(next) and Gem.color(board.cells[next]) == color and Gem.kind(board.cells[next]) != Gem.Kind.COUNTER:
					visited[next] = true
					group.append(next)
			head += 1
		if group.size() > 1: groups.append(group)
	return groups

static func diamond_wave(board, chain: int) -> Dictionary:
	var diamond_idx := -1
	for i in range(84):
		if Gem.is_diamond(board.cells[i]):
			diamond_idx = i
			break
	if diamond_idx == -1:
		return {}
	if diamond_idx >= 78:
		board.cells[diamond_idx] = 0
		return {"chain": chain, "combo": 1, "groups": [{"normal": 1, "crash": 0, "powers": [], "count": 1, "color": 0, "diamond_floor": true}], "counter": 0, "removed": 1, "score": 10000, "attack": 0, "diamond": true}
	var below_idx := diamond_idx + 6
	var target_color: int = Gem.color(board.cells[below_idx])
	var removed := {diamond_idx: true}
	if board.cells[below_idx] != 0:
		removed[below_idx] = true
	if target_color != 0:
		for i in range(84):
			if i != diamond_idx and board.cells[i] != 0 and Gem.color(board.cells[i]) == target_color:
				removed[i] = true
	var normal_or_converted := 0
	var crash_count := 0
	for i in removed:
		var k: int = Gem.kind(board.cells[i])
		if k == Gem.Kind.CRASH:
			crash_count += 1
		elif k != Gem.Kind.POWER:
			normal_or_converted += 1
	var powers_hit: Array = []
	for rect in board.power_gems:
		if removed.has(rect.position.y * 6 + rect.position.x):
			powers_hit.append([rect.size.x, rect.size.y])
	var event := {"normal": normal_or_converted, "crash": crash_count, "powers": powers_hit, "count": removed.size(), "color": target_color}
	var wave := {"chain": chain, "combo": 1, "groups": [event], "counter": 0, "removed": removed.size(), "score": 0, "attack": 0, "diamond": true}
	var economy := Economy.wave(wave)
	wave.score = economy.score
	wave.attack = economy.attack >> 1
	for i in removed:
		board.cells[i] = 0
	var kept: Array[Rect2i] = []
	for rect in board.power_gems:
		if not removed.has(rect.position.y * 6 + rect.position.x):
			kept.append(rect)
	board.power_gems = kept
	return wave

static func resolve(board, decrement: bool = true) -> Dictionary:
	# shortcut: resoluÃƒÂ§ÃƒÂ£o lÃƒÂ³gica imediata; duraÃƒÂ§ÃƒÂ£o e interaÃƒÂ§ÃƒÂµes durante as animaÃƒÂ§ÃƒÂµes ainda nÃƒÂ£o foram portadas.
	var result := {"waves": [], "score": 0, "attack": 0, "converted": 0, "gravity": 0}
	if decrement: result.converted = advance_counters(board)
	form_powers(board)
	result.gravity += gravity(board)
	for chain in range(1, 85):
		form_powers(board)
		var dwave := diamond_wave(board, chain)
		if not dwave.is_empty():
			result.score += int(dwave.score)
			result.attack += int(dwave.attack)
			result.waves.append(dwave)
			result.gravity += gravity(board)
			continue
		var groups := crash_groups(board)
		if groups.is_empty(): break
		var removed := {}
		var collateral := {}
		var wave := {"chain": chain, "combo": groups.size(), "groups": [], "counter": 0, "removed": 0, "score": 0, "attack": 0}
		for group in groups:
			var event := {"normal": 0, "crash": 0, "powers": [], "count": group.size(),"color":Gem.color(board.cells[group[0]])}
			for i in group:
				removed[i] = true
				if Gem.kind(board.cells[i]) == Gem.Kind.CRASH: event.crash += 1
				elif Gem.kind(board.cells[i]) == Gem.Kind.NORMAL: event.normal += 1
				for next in board.neighbors(i):
					if Gem.kind(board.cells[next]) == Gem.Kind.COUNTER: collateral[next] = true
			for rect in board.power_gems:
				if group.has(rect.position.y * 6 + rect.position.x): event.powers.append([rect.size.x, rect.size.y])
			wave.groups.append(event)
		wave.counter = collateral.size()
		for i in collateral: removed[i] = true
		wave.removed = removed.size()
		var economy := Economy.wave(wave)
		wave.score = economy.score
		wave.attack = economy.attack
		result.score += wave.score
		result.attack += wave.attack
		for i in removed: board.cells[i] = 0
		var kept: Array[Rect2i] = []
		for rect in board.power_gems:
			if not removed.has(rect.position.y * 6 + rect.position.x): kept.append(rect)
		board.power_gems = kept
		result.waves.append(wave)
		result.gravity += gravity(board)
	form_powers(board)
	return result

static func resolve_single_wave(board, chain: int) -> Dictionary:
	form_powers(board)
	var dwave := diamond_wave(board, chain)
	if not dwave.is_empty():
		return dwave
	var groups := crash_groups(board)
	if groups.is_empty():
		return {}
	var removed := {}
	var collateral := {}
	var wave := {"chain": chain, "combo": groups.size(), "groups": [], "counter": 0, "removed": 0, "score": 0, "attack": 0}
	for group in groups:
		var event := {"normal": 0, "crash": 0, "powers": [], "count": group.size(), "color": Gem.color(board.cells[group[0]])}
		for i in group:
			removed[i] = true
			if Gem.kind(board.cells[i]) == Gem.Kind.CRASH: event.crash += 1
			elif Gem.kind(board.cells[i]) == Gem.Kind.NORMAL: event.normal += 1
			for next in board.neighbors(i):
				if Gem.kind(board.cells[next]) == Gem.Kind.COUNTER: collateral[next] = true
		for rect in board.power_gems:
			if group.has(rect.position.y * 6 + rect.position.x): event.powers.append([rect.size.x, rect.size.y])
		wave.groups.append(event)
	wave.counter = collateral.size()
	for i in collateral: removed[i] = true
	wave.removed = removed.size()
	var economy := Economy.wave(wave)
	wave.score = economy.score
	wave.attack = economy.attack
	for i in removed: board.cells[i] = 0
	var kept: Array[Rect2i] = []
	for rect in board.power_gems:
		if not removed.has(rect.position.y * 6 + rect.position.x): kept.append(rect)
	board.power_gems = kept
	return wave
