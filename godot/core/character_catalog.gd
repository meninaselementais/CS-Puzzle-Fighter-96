extends RefCounted
## Dados de personagem; contas, patentes, XP e inventário pertencem a outro sistema.
const Attack = preload("res://core/attack_rules.gd")
const ROSTER := [
	{"id":"sas", "name":"SAS", "team":"CT", "pattern":"A", "sprite":"sas_idle_0.png", "animations":"sas", "attack_style":"M4A1-S", "temporary":false},
	{"id":"fbi", "name":"FBI", "team":"CT", "pattern":"B", "sprite":"select_fbi.svg", "animations":"placeholder_ct", "attack_style":"RAJADA TATICA", "temporary":true},
	{"id":"seal", "name":"SEAL TEAM 6", "team":"CT", "pattern":"C", "sprite":"select_seal.svg", "animations":"placeholder_ct", "attack_style":"SUPRESSAO", "temporary":true},
	{"id":"gign", "name":"GIGN", "team":"CT", "pattern":"D", "sprite":"select_gign.svg", "animations":"placeholder_ct", "attack_style":"PRECISAO", "temporary":true},
	{"id":"phoenix", "name":"PHOENIX", "team":"TR", "pattern":"A", "sprite":"phoenix_v9_idle.png", "animations":"phoenix", "attack_style":"AK-47", "temporary":false},
	{"id":"professional", "name":"PROFISSIONAL", "team":"TR", "pattern":"B", "sprite":"select_professional.svg", "animations":"placeholder_tr", "attack_style":"RAJADA CONTROLADA", "temporary":true},
	{"id":"clown", "name":"PALHACO", "team":"TR", "pattern":"C", "sprite":"select_clown.svg", "animations":"placeholder_tr", "attack_style":"PRESSAO", "temporary":true},
	{"id":"guerrilla", "name":"GUERRILHEIRO", "team":"TR", "pattern":"D", "sprite":"select_guerrilla.svg", "animations":"placeholder_tr", "attack_style":"EMBOSCADA", "temporary":true}
]
static var patterns: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/character_patterns.json"))

static func find(id: String) -> Dictionary:
	for character in ROSTER:
		if character.id == id: return character
	return {}

static func pattern_index(id: String) -> int:
	return int(patterns[find(id).pattern].arcade_index)

static func pattern_rows(id: String) -> Array:
	# A mesma tabela de cores usada por receive_attack(), sem cópia CT/TR.
	return Attack.profiles.patterns[pattern_index(id)]
