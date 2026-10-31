extends Node2D
const Session = preload("res://core/match_session.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const MenuInput = preload("res://presentation/selection_input.gd")
const SPIN_SECONDS: float = 1.5
const RESULT_SECONDS: float = 1.1
var elapsed: float = 0.0
var revealed: bool = false
var leaving: bool = false
var input_decoder: RefCounted = MenuInput.new()
var art: RefCounted = Arena.new()
var spin_audio: AudioStreamPlayer
var result_audio: AudioStreamPlayer

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# A animação não sorteia: o único resultado já existe antes do primeiro quadro.
	if Session.phase != "coin": Session.begin_local_match()
	spin_audio = make_audio("coin_flip.wav")
	result_audio = make_audio("coin_result.wav")
	spin_audio.play()

func make_audio(file_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path("res://assets/audio/" + file_name))
	player.volume_db = -9.0
	add_child(player)
	return player

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= SPIN_SECONDS and not revealed:
		revealed = true
		Session.reveal()
		spin_audio.stop()
		result_audio.play()
	if elapsed >= SPIN_SECONDS + RESULT_SECONDS: finish()
	queue_redraw()

func skip() -> void:
	if not revealed:
		elapsed = SPIN_SECONDS
		_process(0.0)
	elif elapsed >= SPIN_SECONDS + 0.2:
		finish()

func finish() -> void:
	if leaving or not revealed: return
	leaving = true
	get_tree().change_scene_to_file("res://player_select.tscn")

func _unhandled_input(event: InputEvent) -> void:
	var command: Dictionary = input_decoder.decode(event)
	if not command.is_empty() and command.command in ["confirm","skip","menu"]:
		get_viewport().set_input_as_handled()
		skip()

func text(at: Vector2, value: String, size: int, color: Color = Color.WHITE) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	Arena.draw_outlined_text(self,font,at-Vector2(width*0.5,0),value,size,color,Color("050916"),2)

func emblem(center: Vector2, ct: bool, radius: float) -> void:
	var color: Color = Color("b6efff") if ct else Color("ffe0a8")
	if ct:
		var points: PackedVector2Array = PackedVector2Array([
			center+Vector2(-0.65,-0.65)*radius,center+Vector2(0.65,-0.65)*radius,
			center+Vector2(0.55,0.3)*radius,center+Vector2(0,0.8)*radius,center+Vector2(-0.55,0.3)*radius])
		draw_colored_polygon(points,color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-0.4,-0.4)*radius,center+Vector2(0.4,-0.4)*radius,center+Vector2(0,0.45)*radius]),Color("22465e"))
	else:
		for flip in [-1.0,1.0]:
			draw_line(center+Vector2(-0.6*flip,0.65)*radius,center+Vector2(0.6*flip,-0.65)*radius,Color("6d3824"),radius*0.24)
			draw_line(center+Vector2(-0.45*flip,0.45)*radius,center+Vector2(0.6*flip,-0.65)*radius,color,radius*0.12)
			draw_line(center+Vector2(-0.65*flip,0.15)*radius,center+Vector2(-0.15*flip,0.65)*radius,Color("e8b35c"),radius*0.1)

func coin(center: Vector2, radius: float, angle: float) -> void:
	var ct: bool = cos(angle) >= 0.0
	var squeeze: float = maxf(0.055,absf(cos(angle)))
	draw_set_transform(center,0,Vector2(squeeze,1))
	draw_circle(Vector2(5,6),radius+7,Color("090c15"))
	draw_circle(Vector2.ZERO,radius+5,Color("825526"))
	draw_circle(Vector2.ZERO,radius,Color("f6cf70"))
	draw_circle(Vector2.ZERO,radius-7,Color("65452e"))
	draw_circle(Vector2.ZERO,radius-12,Color("193c59") if ct else Color("64352d"))
	for index in range(32):
		var theta: float = float(index)*TAU/32.0
		draw_line(Vector2.from_angle(theta)*(radius-4),Vector2.from_angle(theta)*(radius-10),Color("ffe9a6"),2)
	emblem(Vector2(0,-14),ct,radius*0.54)
	text(Vector2(0,radius*0.63),"CT" if ct else "TR",int(radius*0.31),Color("fff0b5"))
	draw_arc(Vector2.ZERO,radius-2,PI*1.05,PI*1.75,24,Color("fff4bf"),3)
	draw_set_transform(Vector2.ZERO)

func side_card(player: int) -> void:
	var center: Vector2 = Vector2(180 if player == 0 else 820,339)
	var ct: bool = Session.team_for(player) == "CT"
	var color: Color = Color("63d6ff") if ct else Color("ffb96a")
	draw_rect(Rect2(center-Vector2(124,110),Vector2(248,220)),Color("0b1325"))
	draw_rect(Rect2(center-Vector2(124,110),Vector2(248,220)),color if revealed else Color("3b4b68"),false,2)
	text(center+Vector2(0,-73),"PLAYER %d" % (player+1),23,Color("bacce7"))
	if revealed:
		emblem(center-Vector2(0,3),ct,48)
		text(center+Vector2(0,76),"COUNTER-TERRORIST" if ct else "TERRORISTA",17,color)
	else:
		text(center+Vector2(0,20),"?",62,Color("506581"))
		text(center+Vector2(0,76),"SORTEANDO LADO",13,Color("738caf"))

func _draw() -> void:
	var background: Texture2D = art.load_tex("stage_dust2.png")
	draw_texture_rect(background,Rect2(0,0,1000,700),false,Color(0.2,0.24,0.34))
	draw_rect(Rect2(0,0,1000,700),Color(0.01,0.02,0.06,0.74))
	for y in range(0,700,4): draw_line(Vector2(0,y),Vector2(1000,y),Color(0,0,0,0.16))
	text(Vector2(500,58),"COUNTER-STRIKE / PUZZLE FIGHTER '96",15,Color("9eb9dc"))
	text(Vector2(500,113),"SIDE SELECTION",42,Color("ffe4a0"))
	text(Vector2(500,145),"COIN FLIP  /  MELHOR DE TRES ROUNDS",15,Color("8ba8ce"))
	side_card(0)
	side_card(1)
	var progress: float = clampf(elapsed/SPIN_SECONDS,0,1)
	var eased: float = 1.0-pow(1.0-progress,2.5)
	var end_angle: float = TAU*5.0 + (0.0 if Session.team_for(0) == "CT" else PI)
	var height: float = sin(progress*PI)*78.0
	draw_set_transform(Vector2(500,478),0,Vector2(1,0.18))
	draw_circle(Vector2.ZERO,80,Color(0,0,0,0.5))
	draw_set_transform(Vector2.ZERO)
	coin(Vector2(500,352-height),112,end_angle*eased)
	text(Vector2(500,530),"CT  VS  TR" if revealed else "A MOEDA DECIDE OS LADOS",27,Color("ffe4a0"))
	text(Vector2(500,568),"EQUIPES FIXAS ATE O FIM DA PARTIDA",15,Color("b2c8e6"))
	text(Vector2(500,621),"Z / Q / ENTER / A / START: " + ("CONTINUAR" if revealed else "PULAR ANIMACAO"),14,Color("7bd9ef"))
	text(Vector2(500,670),"50% CT / 50% TR   /   O SORTEIO NAO ALTERA OS PADROES DE GEMAS",12,Color("7f98bc"))
