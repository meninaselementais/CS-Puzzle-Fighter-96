extends RefCounted

static func build_5x_chain_board() -> PackedInt32Array:
	var cells := PackedInt32Array()
	cells.resize(84)
	cells.fill(0)
	# ONDA 1 (Azul): (1,13)=9 (Crash Orb Azul) + (1,12)=1 (Gema Azul) -> quebram na Onda 1 (remove 2 células na Col 1)
	cells[13 * 6 + 1] = 9
	cells[12 * 6 + 1] = 1
	# ONDA 2 (Amarelo): (0,13)=2, (0,12)=2 + (1,11)=10 (Crash Orb Amarela). Após Onda 1, (1,11) cai 2 linhas para (1,13) e toca (0,13)=2!
	cells[13 * 6 + 0] = 2
	cells[12 * 6 + 0] = 2
	cells[11 * 6 + 1] = 10
	# ONDA 3 (Verde + Power Gem 2x2): (2,13)=3, (3,13)=3, (3,12)=3 + (1,10)=11 (Crash Orb Verde).
	# Após Onda 1 cai para (1,12); após Onda 2 cai para (1,13) e toca (2,13)=3!
	cells[13 * 6 + 2] = 3
	cells[13 * 6 + 3] = 3
	cells[12 * 6 + 3] = 3
	cells[10 * 6 + 1] = 11
	# ONDA 4 (Vermelho): (4,13)=4 + (3,11)=12 (Crash Orb Vermelha sobre (3,12)=3).
	# Permanece em (3,11) nas Ondas 1 e 2; quando a Onda 3 quebra (3,13) e (3,12), cai para (3,13) e toca (4,13)=4!
	cells[13 * 6 + 4] = 4
	cells[11 * 6 + 3] = 12
	# ONDA 5 (Azul Finale): (5,13)=9 (Crash Orb Azul isolada) + coluna de gemas Azuis (4,12)=1, (4,11)=1, (4,10)=1 sobre (4,13)=4.
	# Quando a Onda 4 destrói (4,13)=4, a coluna Azul desce para (4,13..11) e toca (5,13)=9 -> 5X CHAIN!
	cells[13 * 6 + 5] = 9
	cells[12 * 6 + 4] = 1
	cells[11 * 6 + 4] = 1
	cells[10 * 6 + 4] = 1
	return cells

static func build_c4_board() -> PackedInt32Array:
	# Tabuleiro P2 com C4 (código 5) pousando sobre um grande conjunto de gemas e Power Gem Vermelhas (cor 4)
	# + Crash Orbs das 4 cores visíveis nas colunas laterais!
	var cells := PackedInt32Array()
	cells.resize(84)
	cells.fill(0)
	# Power Gem Vermelha 2x2 em (2..3, 12..13) + gemas vermelhas espalhadas
	cells[12 * 6 + 2] = 4
	cells[12 * 6 + 3] = 4
	cells[13 * 6 + 2] = 4
	cells[13 * 6 + 3] = 4
	cells[11 * 6 + 2] = 4
	cells[13 * 6 + 1] = 4
	cells[13 * 6 + 4] = 12 # Crash Orb Vermelha
	# C4 (código 5) na posição (2, 10) logo acima de (2, 11)=4!
	cells[10 * 6 + 2] = 5
	# Orbes de vidro translúcidas nas 4 cores em exposição no tabuleiro P2
	cells[12 * 6 + 0] = 9  # Crash Orb Azul
	cells[13 * 6 + 0] = 2  # Gema Amarela
	cells[12 * 6 + 5] = 10 # Crash Orb Amarela
	cells[13 * 6 + 5] = 3  # Gema Verde
	cells[11 * 6 + 5] = 11 # Crash Orb Verde
	return cells

static func chain_board(count: int) -> PackedInt32Array:
	var cells := build_5x_chain_board()
	if count < 2: cells[11 * 6 + 1] = 0
	if count < 3: cells[10 * 6 + 1] = 0
	if count < 4: cells[11 * 6 + 3] = 0
	if count < 5: cells[13 * 6 + 5] = 0
	return cells

static func power_board() -> PackedInt32Array:
	var cells := PackedInt32Array()
	cells.resize(84)
	for y in range(11, 14):
		for x in range(1, 4): cells[y * 6 + x] = 3
	cells[13 * 6 + 4] = 11
	return cells
