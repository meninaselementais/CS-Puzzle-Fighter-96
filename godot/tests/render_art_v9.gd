extends SceneTree
class Gallery extends Node2D:
	var names: Array[String]=["idle","blink","ready","aim","recoil_a","recoil_b","recover","settle","windup","release","follow","hit","hurt","win","stagger","defeat"]
	var images: Array[Texture2D]=[]
	func _ready() -> void:
		for name in names: images.append(ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/phoenix_v9_"+name+".png"))))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1200,1200),Color("10192b"))
		for i in range(names.size()):
			var pos:=Vector2((i%4)*300,(i/4)*300)
			draw_rect(Rect2(pos+Vector2(4,4),Vector2(292,292)),Color("19273b"))
			draw_texture_rect(images[i],Rect2(pos+Vector2(22,4),Vector2(256,256)),false)
			draw_line(pos+Vector2(20,252),pos+Vector2(280,252),Color("537498"))
			draw_string(ThemeDB.fallback_font,pos+Vector2(22,282),"%02d  %s"%[i+1,names[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1200,1200)
	root.content_scale_size=Vector2i(1200,1200)
	root.add_child(Gallery.new())
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../relatorios/animacoes_v9/quadros_phoenix_v9.png"))==OK)
	print("ART_GALLERY_V9_OK")
	quit(0)
