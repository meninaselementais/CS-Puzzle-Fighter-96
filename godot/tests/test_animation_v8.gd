extends SceneTree
const Arena = preload("res://presentation/cs_arena.gd")
const Match = preload("res://core/match_model.gd")
const Fixtures = preload("res://presentation/showcase_fixtures.gd")
const Controls = preload("res://core/control_model.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(value: bool, name: String) -> void:
	checks += 1
	if not value: failures.append(name); push_error(name)

func empty_effects(arena) -> bool:
	return arena.projectiles.is_empty() and arena.vfx_sprites.is_empty() and arena.gem_sparks.is_empty() and arena.shell_casings.is_empty() and arena.impact_flashes.is_empty()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = Arena.new()
	var model = Match.new()
	for tex in Arena.BAKED_FLARES:
		var image: Texture2D = arena.load_tex(tex)
		expect(Rect2i(Vector2i.ZERO,image.get_size()).encloses(Arena.BAKED_FLARES[tex]), "flare mask within sprite")
	for player in range(2):
		for level in range(1,4):
			arena.reset_state(); arena.fighter_attack_level[player] = level
			arena.trigger_action(player,"shoot")
			var shots := 0
			var peak_recoil := 0.0
			var aligned := true
			var correct_frames := true
			var max_muzzles := 0
			var max_skew := 0.0
			for tick in range(90):
				arena.step_from_model(model)
				peak_recoil = maxf(peak_recoil,arena.fighter_recoil[player])
				max_muzzles = maxi(max_muzzles,arena.vfx_sprites.filter(func(f): return int(f.get("muzzle_owner",-1))==player).size())
				var state: String = arena.fighter_state[player]
				var kf: Dictionary = Arena.FIGHTER_ANIMS[player][state][arena.fighter_anim_frame[player]]
				var rect: Rect2 = arena.fighter_draw_rect(player)
				var tex: Texture2D = arena.load_tex(kf.tex)
				max_skew = maxf(max_skew,absf(rect.size.x/rect.size.y-float(tex.get_width())/float(tex.get_height())))
				for projectile in arena.projectiles:
					if int(projectile.owner)==player and int(projectile.born_tick)==arena.anim_tick:
						shots += 1
						correct_frames = correct_frames and state=="shoot" and bool(kf.get("shell",false)) and int(projectile.source_frame)==arena.fighter_anim_frame[player]
						aligned = aligned and float(projectile.t)==0.0 and Arena.projectile_position(projectile).distance_to(arena.attachment_position(player,kf.muzzle))<0.001
			expect(shots==level,"burst count P%d level%d" % [player,level])
			expect(correct_frames and aligned,"shot pose/position exact on release")
			expect(max_muzzles==1,"no overlapping muzzle flashes per player")
			expect(peak_recoil>=3.0 and arena.fighter_recoil[player]<0.001,"recoil impulse and recovery")
			expect(max_skew<0.00001,"authored sprite aspect ratio preserved")
			expect(arena.fighter_state[player]=="idle" and empty_effects(arena),"shot returns to idle and expires")
		for level in [1,5]:
			arena.reset_state(); arena.fighter_attack_level[player] = level
			arena.trigger_action(player,"grenade")
			var release_tick := -1
			var grenades := 0
			var source_ok := true
			var center_lane := true
			var saw_fragments := false
			for tick in range(110):
				arena.step_from_model(model)
				for pr in arena.projectiles:
					if pr.kind!="he": continue
					var position := Arena.projectile_position(pr)
					center_lane = center_lane and position.x>280.0 and position.x<720.0 and position.y>202.0 and position.y<492.0
					if int(pr.born_tick)==arena.anim_tick:
						grenades += 1; release_tick = tick+1
						var kf: Dictionary = Arena.FIGHTER_ANIMS[player].grenade[arena.fighter_anim_frame[player]]
						source_ok = source_ok and bool(kf.get("release",false)) and position.distance_to(arena.attachment_position(player,kf.hand))<0.001 and float(pr.t)==0.0
						var sample: Dictionary = pr.duplicate(); sample.t=0.5
						var baseline := (float(pr.y)+float(pr.ty))*0.5
						expect(absf(baseline-Arena.projectile_position(sample).y-72.0)<0.001,"parabolic midpoint")
						sample.t=1.0
						expect(Arena.projectile_position(sample).distance_to(Vector2(pr.tx,pr.ty))<0.001,"arc ends on target")
				saw_fragments = saw_fragments or not arena.gem_sparks.is_empty()
			expect(grenades==1 and release_tick==10 and source_ok,"one grenade after windup, at hand")
			expect(center_lane,"grenade avoids boards, logo and score HUD")
			expect(saw_fragments and empty_effects(arena),"grenade explosion/shrapnel expires")
		for state in ["hit","victory","defeat"]:
			arena.reset_state(); arena.set_fighter_state(player,state,28 if state=="hit" else 0,true)
			for tick in range(180): arena.step_from_model(model)
			expect(arena.fighter_state[player]==("idle" if state=="hit" else state),"expressive state completes or holds")
			expect(arena.fighter_flash[player]==0 and empty_effects(arena),"no terminal flash/projectile leak")
	# Both players keep their own action events, even when hit on the same tick.
	for chain in [2,3,5]:
		arena.reset_state()
		for player in range(2): arena.trigger_wave_presentation(player,chain,1200,false,false,Vector2(64+680*player,108),Vector2(160,420))
		var owners := {}
		for tick in range(140):
			arena.step_from_model(model)
			for pr in arena.projectiles:
				if int(pr.born_tick)==arena.anim_tick: owners[pr.owner]=true
		expect(owners.size()==2,"simultaneous owners %dX" % chain)
		expect(empty_effects(arena) and arena.pending_hit==[0,0] and arena.fighter_state==["idle","idle"],"simultaneous effects drain")
	# The first attack keyframe of each wave must coincide with that wave's destruction boundary.
	for cells in [Fixtures.chain_board(5),Fixtures.build_c4_board()]:
		arena.reset_state()
		for player in range(2): arena.enqueue_visual_waves(player,cells,Vector2(64+680*player,108))
		var first_releases := {}
		var impact_ticks := {}
		for tick in range(360):
			arena.step_from_model(model)
			for player in range(2):
				if not arena.active_wave[player].is_empty():
					var w: Dictionary = arena.active_wave[player]
					var key := "%d:%d" % [player,int(w.chain)]
					if w.phase=="burst" and not impact_ticks.has(key): impact_ticks[key]=arena.anim_tick
			for pr in arena.projectiles:
				if int(pr.born_tick)!=arena.anim_tick: continue
				var player := int(pr.owner)
				if arena.active_wave[player].is_empty(): continue
				var key := "%d:%d" % [player,int(arena.active_wave[player].chain)]
				if not first_releases.has(key): first_releases[key]=arena.anim_tick
		expect(first_releases==impact_ticks,"wave impact equals first attack keyframe, both owners")
		expect(not first_releases.is_empty() and empty_effects(arena),"synchronized waves expire")
	var magnitudes: Array[float] = []
	for chain in [2,3,5]:
		arena.reset_state(); arena.trigger_wave_presentation(0,chain,800,false,false,Vector2(64,108),Vector2(160,420))
		magnitudes.append(arena.screen_shake_mag)
		for tick in range(140): arena.step_from_model(model)
		expect(arena.get_screen_shake_offset()==Vector2.ZERO,"screen shake returns to rest")
	expect(magnitudes[0]<magnitudes[1] and magnitudes[1]<magnitudes[2] and magnitudes[2]<=2.5,"progressive bounded screen shake")
	arena.reset_state(); arena.trigger_action(0,"shoot"); arena.trigger_action(0,"hit")
	arena.set_fighter_state(0,"victory")
	expect(arena.pending_hit[0]==0,"winner cancels deferred damage")
	var scene = load("res://animation_showcase.tscn").instantiate()
	root.add_child(scene); scene.set_physics_process(false); scene.auto_button.button_pressed=false
	for actor in range(3):
		scene.actors.item_selected.emit(actor)
		for topic in range(scene.TOPICS.size()):
			scene.select_topic(topic)
			for tick in range(300): scene.advance_showcase()
			expect(empty_effects(scene.arena) and scene.model.frame==0,"Showcase actor %d topic %d drains; game clock isolated" % [actor,topic])
	for speed_index in range(4):
		scene.select_topic(0); scene.paused=false
		scene.speed_picker.item_selected.emit(speed_index)
		for tick in range(4): scene._physics_process(1.0/Controls.FRAMES_PER_SECOND)
		expect(scene.topic_tick==[1,2,4,8][speed_index],"speed selector uses fixed ticks")
		scene.toggle_pause(); var saved_tick: int = scene.topic_tick
		scene._physics_process(1.0)
		expect(scene.topic_tick==saved_tick,"pause freezes at any speed")
		scene.single_step()
		expect(scene.topic_tick==saved_tick+1 and scene.paused and scene.pause_button.text=="Continuar","single step ignores playback speed")
	scene.loop_button.button_pressed=true
	scene.select_topic(1)
	for tick in range(scene.sequence_duration()): scene.advance_showcase()
	expect(scene.topic==1 and scene.topic_tick==0 and not scene.autoplay,"continuous loop same sequence")
	scene.auto_button.button_pressed=true
	expect(not scene.loop_sequence,"catalog and loop mutually exclusive")
	for tick in range(scene.sequence_duration()): scene.advance_showcase()
	expect(scene.topic==2 and scene.topic_tick==0,"catalog continues to next topic")
	expect(scene.information.text.contains("SAS:") and scene.information.text.contains("Phoenix:"),"current animation/frame identified")
	scene.queue_free()
	print("ANIMATION_V8_TESTS ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
