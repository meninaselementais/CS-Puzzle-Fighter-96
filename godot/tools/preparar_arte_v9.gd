extends SceneTree
const OUT := "res://assets/sprites/"
var metadata: Dictionary = {}

func digest(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
	return hash.finish().hex_encode()

func opaque_bounds(img: Image) -> Rect2i:
	return img.get_used_rect()

func extract(sheet_path: String, names: Array) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width(); var h := img.get_height()
	var labels := PackedInt32Array(); labels.resize(w*h); labels.fill(-1)
	var regions: Array[Dictionary] = []
	for y in range(h):
		for x in range(w):
			var index := y*w+x
			if labels[index]!=-1 or img.get_pixel(x,y).a<0.2: continue
			var id := regions.size()
			var queue := PackedInt32Array([index]); labels[index]=id
			var cursor := 0; var min_x:=x; var max_x:=x; var min_y:=y; var max_y:=y
			while cursor<queue.size():
				var next := queue[cursor]; cursor+=1
				var px:=next%w; var py:=next/w
				min_x=mini(min_x,px);max_x=maxi(max_x,px);min_y=mini(min_y,py);max_y=maxi(max_y,py)
				for dy in range(-1,2):
					for dx in range(-1,2):
						var nx:=px+dx;var ny:=py+dy
						if nx<0 or nx>=w or ny<0 or ny>=h: continue
						var ni:=ny*w+nx
						if labels[ni]==-1 and img.get_pixel(nx,ny).a>=0.2:
							labels[ni]=id;queue.append(ni)
			regions.append({"id":id,"count":queue.size(),"rect":Rect2i(min_x,min_y,max_x-min_x+1,max_y-min_y+1)})
	regions.sort_custom(func(a,b):return int(a.count)>int(b.count))
	assert(regions.size()>=8)
	var chosen: Array = regions.slice(0,8)
	chosen.sort_custom(func(a,b):return a.rect.get_center().y<b.rect.get_center().y)
	for row in range(2):
		var line: Array = chosen.slice(row*4,row*4+4)
		line.sort_custom(func(a,b):return a.rect.get_center().x<b.rect.get_center().x)
		for column in range(4):
			var entry: Dictionary = line[column]; var rect: Rect2i=entry.rect
			var min_bx:=rect.end.x;var max_bx:=rect.position.x
			for y in range(rect.end.y-24,rect.end.y):
				for x in range(rect.position.x,rect.end.x):
					if labels[y*w+x]==entry.id:
						min_bx=mini(min_bx,x);max_bx=maxi(max_bx,x)
			var foot_x:=int(round(float(min_bx+max_bx)*0.5))
			var offset:=Vector2i(256-foot_x,496-rect.end.y)
			assert(rect.position.x+offset.x>=0 and rect.end.x+offset.x<=512)
			assert(rect.position.y+offset.y>=0)
			var frame:=Image.create(512,512,false,Image.FORMAT_RGBA8)
			frame.fill(Color.TRANSPARENT)
			for y in range(rect.position.y,rect.end.y):
				for x in range(rect.position.x,rect.end.x):
					if labels[y*w+x]==entry.id: frame.set_pixel(x+offset.x,y+offset.y,img.get_pixel(x,y))
			var name: String=names[row*4+column]
			assert(frame.save_png(ProjectSettings.globalize_path(OUT+name))==OK)
			metadata[name]={"sheet":sheet_path,"source_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],
				"anchor":[256,496],"source_pixels":entry.count,"pixel_sha256":digest(frame.get_data()),"review":"pending"}
			print("EXTRACTED ",name," ",rect)

func inventory() -> void:
	var report: Array=[]
	var files: Array[String]=[]
	for name in DirAccess.get_files_at(OUT):
		if (name.begins_with("sas_") or name.begins_with("phoenix_")) and name.ends_with(".png") and not name.contains("v9"):
			files.append(name)
	files.sort()
	var contact:=Image.create(5*180,4*260,false,Image.FORMAT_RGBA8)
	contact.fill(Color("121a28"))
	var normals: Dictionary={}
	for i in range(files.size()):
		var img:=Image.load_from_file(ProjectSettings.globalize_path(OUT+files[i])); img.convert(Image.FORMAT_RGBA8)
		var bounds:=opaque_bounds(img)
		var crop:=img.get_region(bounds)
		var normal:=crop.duplicate(); normal.resize(96,128,Image.INTERPOLATE_NEAREST); normals[files[i]]=normal
		report.append({"file":files[i],"size":[img.get_width(),img.get_height()],"rgba_sha256":digest(img.get_data()),"trimmed_sha256":digest(crop.get_data())})
		var scale:=minf(164.0/float(crop.get_width()),238.0/float(crop.get_height()))
		crop.resize(int(crop.get_width()*scale),int(crop.get_height()*scale),Image.INTERPOLATE_NEAREST)
		contact.blend_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i((i%5)*180+8,(i/5)*260+6))
	assert(contact.save_png(ProjectSettings.globalize_path("res://../relatorios/animacoes_v9/sprites_v8_contato.png"))==OK)
	var near: Array=[]
	for a in range(files.size()):
		for b in range(a+1,files.size()):
			if files[a].begins_with("sas")!=files[b].begins_with("sas"):continue
			var ia:Image=normals[files[a]];var ib:Image=normals[files[b]]
			var sum:=0.0
			for y in range(128):
				for x in range(96):
					var ca:=ia.get_pixel(x,y);var cb:=ib.get_pixel(x,y)
					sum+=(absf(ca.r*ca.a-cb.r*cb.a)+absf(ca.g*ca.a-cb.g*cb.a)+absf(ca.b*ca.a-cb.b*cb.a)+absf(ca.a-cb.a))/4.0
			var difference:=sum/(96.0*128.0)
			if difference<0.04: near.append({"a":files[a],"b":files[b],"normalized_difference":difference})
	var file:=FileAccess.open("res://../relatorios/animacoes_v9/inventario_v8.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ordered_contact":files,"files":report,"near_pairs":near},"\t"));file.close()

func corrected_victory() -> void:
	var image:=Image.load_from_file(ProjectSettings.globalize_path("res://../arte/v9/phoenix_win_corrected_source.png"))
	image.convert(Image.FORMAT_RGBA8)
	image.resize(512,512,Image.INTERPOLATE_NEAREST)
	var used:=image.get_used_rect()
	var frame:=Image.create(512,512,false,Image.FORMAT_RGBA8); frame.fill(Color.TRANSPARENT)
	var min_x:=512;var max_x:=0
	for y in range(used.end.y-20,used.end.y):
		for x in range(used.position.x,used.end.x):
			if image.get_pixel(x,y).a>0.2: min_x=mini(min_x,x);max_x=maxi(max_x,x)
	var offset:=Vector2i(256-int(round(float(min_x+max_x)*0.5)),496-used.end.y)
	frame.blit_rect(image,used,used.position+offset)
	assert(frame.save_png(ProjectSettings.globalize_path(OUT+"phoenix_v9_win.png"))==OK)
	metadata["phoenix_v9_win.png"]={"sheet":"res://../arte/v9/phoenix_win_corrected_source.png","anchor":[256,496],"pixel_sha256":digest(frame.get_data()),"review":"corrected_anatomy_two_hands"}

func _initialize() -> void:
	inventory()
	extract("res://../arte/v9/phoenix_weapon_sheet.png",["phoenix_v9_idle.png","phoenix_v9_blink.png","phoenix_v9_ready.png","phoenix_v9_aim.png","phoenix_v9_recoil_a.png","phoenix_v9_recoil_b.png","phoenix_v9_recover.png","phoenix_v9_settle.png"])
	extract("res://../arte/v9/phoenix_actions_sheet.png",["phoenix_v9_windup.png","phoenix_v9_release.png","phoenix_v9_follow.png","phoenix_v9_hit.png","phoenix_v9_hurt.png","phoenix_v9_win.png","phoenix_v9_stagger.png","phoenix_v9_defeat.png"])
	corrected_victory()
	var file:=FileAccess.open("res://../arte/v9/frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata,"\t"));file.close()
	print("ART_V9_EXTRACT_OK ",metadata.size())
	quit(0)
