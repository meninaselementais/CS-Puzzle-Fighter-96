extends RefCounted

var frames: Array = []
var error_message: String = ""

func fail(message: String) -> bool:
	error_message = message
	frames = []
	return false

func whole_number(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return fail("Replay ausente: " + path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return fail("JSON inválido")
	return load_data(json.data)

func load_data(data: Variant) -> bool:
	frames = []
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("columns") != 6 or data.get("rows") != 14:
		return fail("Schema de replay incompatível")
	if not data.get("frames") is Array:
		return fail("Lista de quadros ausente")
	for item in data.frames:
		if not item is Dictionary or not item.get("players") is Array or item.players.size() != 2:
			return fail("Quadro sem dois jogadores")
		for player in item.players:
			if not player is Dictionary or not player.get("cells") is Array or player.cells.size() != 84:
				return fail("Tabuleiro inválido")
			if not whole_number(player.get("x"), 0, 5) or not whole_number(player.get("y"), 0, 65535) or not whole_number(player.get("rotation"), 0, 3):
				return fail("Posição/rotação inválida")
			if not (player.get("render_y") is float or player.get("render_y") is int) or not is_finite(float(player.render_y)):
				return fail("Posição interpolada inválida")
			if not player.get("colors") is Array or player.colors.size() != 2:
				return fail("Cores da dupla inválidas")
			for value in player.cells + player.colors:
				if not whole_number(value, 0, 65535):
					return fail("Código de pedra inválido")
	frames = data.frames.duplicate(true)
	error_message = ""
	return true
