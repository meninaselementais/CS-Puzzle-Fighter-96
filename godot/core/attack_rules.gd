extends RefCounted

static var profiles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/attack_profiles.json"))

static func columns(permutation: int) -> Array:
	assert(permutation >= 0 and permutation < 8)
	return profiles.permutations[permutation]

static func counter_color(character: int, row: int, column: int) -> int:
	assert(character >= 0 and character < 11 and column >= 0 and column < 6)
	return int(profiles.patterns[character][mini(row,11)][column])

static func power_points(area: int) -> int:
	# Taxas por célula medidas no arcade; dimensões válidas: 2..6 por 2..8.
	# shortcut: somas de Power Gems acima de 48 células ainda não foram ensaiadas.
	var rate := 200 if area < 10 else 250 if area < 18 else 300 if area < 25 else 350 if area < 40 else 400
	return area * rate

static func wave(event: Dictionary) -> Dictionary:
	var score := 0
	var colors := {}
	var count := 0
	var power_area := 0
	for group in event.groups:
		colors[int(group.color)] = true
		count += int(group.count)
		var group_score: int = 100 * (group.normal + group.crash)
		for size in group.powers: power_area += int(size[0]) * int(size[1])
		score += group_score
	score += power_points(power_area)
	var chain_bonus := [0,200,400,1000,1600,2200,2800,3400,4000,4000,4000]
	var total_score: int = score + 10*maxi(0,count+int(event.counter)-2) + 10*int(event.counter)
	total_score += 200*colors.size() if colors.size()>1 else 0
	total_score += int(chain_bonus[mini(int(event.chain)-1,10)])
	return {"score": total_score, "attack": mini(99, total_score / 100)}

static func counter_strength(attack: int) -> int:
	if attack <= 12: return attack / 2
	var factor := 5 if attack<=18 else 6 if attack<=24 else 7 if attack<=30 else 8
	return (attack/8 + 1)*factor
