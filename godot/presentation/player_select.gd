extends Node2D

const Catalog = preload("res://core/character_catalog.gd")
const Selection = preload("res://core/selection_state.gd")
const Session = preload("res://core/match_session.gd")
const MenuInput = preload("res://presentation/selection_input.gd")
var input_decoder: RefCounted = MenuInput.new()
const Arena = preload("res://presentation/cs_arena.gd")
var selection = Selection.new()
var art = Arena.new()
var elapsed: float = 0.0
var launch_time: float = -1.0
var confirm_time: Array[float] = [-10.0, -10.0]
const P_COLORS := [Color("66d9ff"), Color("ffb45b")]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if Session.phase != "select" or Session.player_groups.size() != 2:
		get_tree().change_scene_to_file("res://coin_flip.tscn")
		return
	selection = Selection.new()

func _process(delta: float) -> void:
	elapsed += delta
	if launch_time >= 0.0:
		launch_time -= delta
		if launch_time <= 0.0:
			if selection.save_selection():
				get_tree().change_scene_to_file("res://main.tscn")
			else:
				launch_time = -1.0
	queue_redraw()

func handle_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	handle_command(input_decoder.decode(event))

func handle_command(command: Dictionary) -> void:
	if command.is_empty() or launch_time >= 0.0: return
	var player: int = int(command.player)
	match str(command.command):
		"move": selection.move(player, command.direction)
		"confirm":
			if selection.confirm(player): confirm_time[player] = elapsed
		"cancel": selection.cancel(player)
		"menu":
			selection.cancel(0)
			selection.cancel(1)
	if selection.ready_to_start(): launch_time = 0.6
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var command: Dictionary = input_decoder.decode(event)
	if not command.is_empty():
		handle_command(command)
		get_viewport().set_input_as_handled()

func text(at: Vector2, value: String, size: int, color: Color = Color.WHITE, centered: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	Arena.draw_outlined_text(self, font, at - Vector2(width * 0.5 if centered else 0.0, 0), value, size, color, Color("050916"), 2)

func panel(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(4,5),rect.size), Color(0,0,0,0.65))
	draw_rect(rect, Color("0a1224"))
	draw_rect(rect.grow(-3), Color("15213a"), false, 2)
	draw_rect(rect, color.darkened(0.35), false, 2)
	draw_line(rect.position, rect.position + Vector2(rect.size.x,0), color.lightened(0.3), 2)

func portrait(character: Dictionary, rect: Rect2, full: bool = false) -> void:
	var texture: Texture2D = art.load_tex(character.sprite)
	if texture == null: return
	var used: Rect2 = Rect2(texture.get_image().get_used_rect())
	if not full:
		used.size.y *= 0.62
		used.position.x += used.size.x * 0.1
		used.size.x *= 0.8
	var ratio := minf(rect.size.x / used.size.x, rect.size.y / used.size.y)
	var size := used.size * ratio
	draw_texture_rect_region(texture, Rect2(rect.position + (rect.size - size) * 0.5, size), used)

func player_panel(player: int) -> void:
	var character: Dictionary = Catalog.ROSTER[selection.cursors[player]]
	var left := 28.0 if player == 0 else 732.0
	var center := left + 120.0
	var tint: Color = P_COLORS[player]
	panel(Rect2(left,146,240,468),tint)
	text(Vector2(center,178), "PLAYER %d / %s" % [player+1,Session.team_for(player)], 22,tint,true)
	text(Vector2(center,207),character.name, 21,Color("ffe49a"),true)
	text(Vector2(center,228),"COUNTER-TERRORIST" if character.team == "CT" else "TERRORISTA",12,tint,true)
	draw_rect(Rect2(left+12,240,216,190),Color("080e1a"))
	portrait(character,Rect2(left+17,246,206,177),true)
	if character.temporary:
		text(Vector2(center,446),"ARTE TEMPORARIA",12,Color("ffca78"),true)
	else:
		text(Vector2(center,446),character.attack_style,13,Color("b1c7e4"),true)
	text(Vector2(center,473),"COUNTER GEMS / %s" % character.pattern,16,tint,true)
	var rows: Array = Catalog.pattern_rows(character.id)
	# As seis primeiras linhas, na mesma ordem da entrega; a tabela completa tem 12.
	for row in range(6):
		for col in range(6):
			var at := Vector2(left+60+col*20,485+row*15)
			var tex: Texture2D = art.load_tex("gem_normal_%d.png" % int(rows[row][col]))
			draw_texture_rect(tex,Rect2(at,Vector2(17,14)),false)
	text(Vector2(center,590),"CONFIRMADO" if selection.confirmed[player] else "ESCOLHA SEU AGENTE",14,Color("9fffbe") if selection.confirmed[player] else Color("c3d0e6"),true)
	var pulse := 1.0 - clampf((elapsed - confirm_time[player]) / 0.45,0.0,1.0)
	if pulse > 0.0: draw_rect(Rect2(left,146,240,468),Color(1,1,1,pulse*0.4))

func _draw() -> void:
	var backdrop: Texture2D = art.load_tex("stage_dust2.png")
	draw_texture_rect(backdrop,Rect2(0,0,1000,700),false,Color(0.25,0.29,0.4))
	draw_rect(Rect2(0,0,1000,700),Color(0.015,0.025,0.07,0.72))
	for y in range(0,700,4): draw_line(Vector2(0,y),Vector2(1000,y),Color(0,0,0,0.13))
	draw_line(Vector2(28,24),Vector2(972,24),Color("435c86"),2)
	text(Vector2(500,52),"COUNTER-STRIKE  /  PUZZLE FIGHTER '96",14,Color("abbcda"),true)
	text(Vector2(500,103),"PLAYER SELECT",44,Color("ffe49a"),true)
	text(Vector2(500,128),"8 AGENTES    /    4 PADROES COMPARTILHADOS",13,Color("8cadd7"),true)
	player_panel(0)
	player_panel(1)
	text(Vector2(500,175),"COUNTER-TERRORISTS / P%d" % (1 if Session.team_for(0) == "CT" else 2),14,Color("66d9ff"),true)
	for index in range(8):
		var character: Dictionary = Catalog.ROSTER[index]
		var x := 290.0 + float(index%4)*106.0
		var y := 196.0 if index < 4 else 382.0
		var rect := Rect2(x,y,100,136)
		var team_color := Color("4b83be") if index < 4 else Color("ad634d")
		panel(rect,team_color)
		portrait(character,Rect2(x+7,y+6,86,87))
		text(Vector2(x+50,y+110),character.name,10 if character.name.length()>9 else 13,Color("e6eaf1"),true)
		text(Vector2(x+50,y+128),"P%d / %s%s" % [1 if character.team == Session.team_for(0) else 2,character.pattern," / TEMP" if character.temporary else ""],10,Color("d1ad76") if character.temporary else Color("90b9df"),true)
		for player in range(2):
			if selection.cursors[player] != index: continue
			var border := rect.grow(3+player*3)
			var pulse := 0.65+sin(elapsed*6.0)*0.25
			draw_rect(border.grow(3),Color(P_COLORS[player],0.13),false,6)
			draw_rect(border,Color(P_COLORS[player],1.0 if selection.confirmed[player] else pulse),false,3)
			var badge := Vector2(x+3+player*53,y+18)
			draw_rect(Rect2(badge-Vector2(0,14),Vector2(42,20)),P_COLORS[player])
			draw_string(ThemeDB.fallback_font,badge+Vector2(4,1),"P%d%s" % [player+1," OK" if selection.confirmed[player] else ""],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("06101e"))
	text(Vector2(500,365),"TERRORISTAS / P%d" % (1 if Session.team_for(0) == "TR" else 2),14,Color("ffac7a"),true)
	text(Vector2(500,555),"A / A     B / B     C / C     D / D",15,Color("ffe49a"),true)
	text(Vector2(500,580),"CT CONTRA TR. EQUIPES BLOQUEADAS.",12,Color("a8bfde"),true)
	text(Vector2(500,603),"TABELAS MAME / PREVIA: 6 DE 12 LINHAS",10,Color("7e96ba"),true)
	draw_line(Vector2(28,632),Vector2(972,632),Color("435c86"),2)
	text(Vector2(250,660),"P1  SETAS: MOVER   Z: CONFIRMAR   X: VOLTAR",13,P_COLORS[0],true)
	text(Vector2(750,660),"P2  W/A/S/D: MOVER   Q: CONFIRMAR   E: VOLTAR",13,P_COLORS[1],true)
	text(Vector2(500,685),"EQUIPES BLOQUEADAS / CONTROLE: D-PAD OU ANALOGICO, A: CONFIRMAR, B: VOLTAR",11,Color("91a7c9"),true)
	if launch_time >= 0.0:
		draw_rect(Rect2(270,292,460,112),Color("080e1a"))
		draw_rect(Rect2(270,292,460,112),Color("ffe49a"),false,3)
		text(Vector2(500,339),"READY TO FIGHT",30,Color("ffe49a"),true)
		text(Vector2(500,375),"P1  VS  P2",18,Color.WHITE,true)
