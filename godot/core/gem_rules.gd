extends RefCounted

enum Kind { EMPTY, NORMAL, CRASH, COUNTER, POWER, DIAMOND }

static func color(code: int) -> int:
	if (code & 15) in [6, 7]:
		return (code >> 12) & 7
	var value := code & 7
	return value if value in [1, 2, 3, 4] else 0

static func kind(code: int) -> int:
	if code == 0:
		return Kind.EMPTY
	if (code & 15) in [6, 7]:
		return Kind.COUNTER
	if (code & 7) == 5:
		return Kind.DIAMOND
	if code & 128:
		return Kind.POWER
	if code & 8:
		return Kind.CRASH
	return Kind.NORMAL

static func is_diamond(code: int) -> bool:
	return kind(code) == Kind.DIAMOND

static func countdown(code: int) -> int:
	return (code >> 8) & 15

static func counter(gem_color: int, turns: int = 5) -> int:
	assert(gem_color in [1, 2, 3, 4] and turns >= 0 and turns <= 5)
	return (gem_color << 12) | (turns << 8) | 7

static func canonical(code: int) -> int:
	if code == 0:
		return 0
	if (code & 7) == 5 and (code & 15) not in [6, 7]:
		return 5
	var c := color(code)
	if c == 0:
		return code
	match kind(code):
		Kind.COUNTER: return counter(c, mini(countdown(code), 5))
		Kind.POWER: return c | 128
		Kind.CRASH: return c | 8
	return c

static func can_power(code: int, target_color: int) -> bool:
	return color(code) == target_color and kind(code) in [Kind.NORMAL, Kind.POWER]
