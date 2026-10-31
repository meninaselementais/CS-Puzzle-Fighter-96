extends RefCounted

# Rotinas 02DB6A (global) e 0122EC (duplas), com aritmética de 16/8 bits.
static func advance(seed: int, piece: bool = false) -> int:
	assert(seed >= 0 and seed <= 65535)
	if piece and seed == 0: seed = 0x1c3
	var product := (seed * 3) & 65535
	return (product & 0xff00) | ((seed + (product >> 8)) & 255)
