extends SceneTree
const Arena=preload("res://presentation/cs_arena.gd")
const Match=preload("res://core/match_model.gd")
var checks:int=0
var failures:Array[String]=[]
func expect(ok:bool,name:String)->void:
	checks+=1
	if not ok: failures.append(name);push_error(name)
func _initialize()->void:
	call_deferred("run")
func run()->void:
	var arena=Arena.new();var model=Match.new()
	expect(arena.imported_frames.size()==16,"sixteen reviewed frames")
	var hashes:Dictionary={}
	for name in arena.imported_frames:
		var image:Image=arena.load_tex(name).get_image()
		var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(image.get_data())
		var digest:=hash.finish().hex_encode()
		expect(digest==arena.imported_frames[name].pixel_sha256,"reviewed pixels match runtime %s"%name)
		expect(not hashes.has(digest),"distinct drawn frame %s"%name);hashes[digest]=true
		expect(image.get_size()==Vector2i(512,512) and image.get_pixel(0,0).a==0.0,"canvas and alpha %s"%name)
		expect(image.get_used_rect().end.y==496,"ground registration %s"%name)
		expect(str(arena.imported_frames[name].review).begins_with("accepted"),"review accepted %s"%name)
	var shoot_images:Dictionary={}
	for keyframe in Arena.FIGHTER_ANIMS[1].shoot: shoot_images[keyframe.tex]=true
	expect(shoot_images.size()>=6,"Phoenix shooting uses distinct drawings, not one translated PNG")
	for player in range(2):
		for state in ["idle","shoot","grenade","victory"]:
			arena.reset_state();arena.set_fighter_state(player,state,0,true)
			var pinned:=true
			var stable_scale:=true
			for tick in range(160):
				arena.advance_fighter_anim(player,model)
				var kf:Dictionary=Arena.FIGHTER_ANIMS[player][arena.fighter_state[player]][arena.fighter_anim_frame[player]]
				var rect:Rect2=arena.fighter_draw_rect(player)
				var tex:Texture2D=arena.load_tex(kf.tex)
				var scale:=0.44 if player==0 else 0.5
				var anchor:=Vector2(float(arena.boot_anchors[kf.tex]),float(arena.boot_floors[kf.tex]))
				pinned=pinned and (rect.position+anchor*scale).distance_to(Vector2(376 if player==0 else 624,492))<0.001
				stable_scale=stable_scale and absf(rect.size.x/float(tex.get_width())-scale)<0.001
			expect(pinned,"registered feet %d %s"%[player,state])
			expect(stable_scale,"no proportion pumping %d %s"%[player,state])
	arena.reset_state()
	arena.spawn_board_explosion(Vector2(64,108),2,12,3,true,5,false,true)
	expect(arena.gem_sparks.size()<=8,"bounded fracture density")
	expect(arena.gem_sparks.any(func(s):return int(s.delay)>0),"fragment emission stagger")
	var sizes:Dictionary={}
	for spark in arena.gem_sparks: sizes[spark.base_scale]=true
	expect(sizes.size()>1,"large and small crystal fragments")
	for tick in range(160):arena.step_from_model(model)
	expect(arena.gem_sparks.is_empty() and arena.vfx_sprites.is_empty() and arena.impact_flashes.is_empty(),"fracture effects drain")
	print("ART_V9_TESTS ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
