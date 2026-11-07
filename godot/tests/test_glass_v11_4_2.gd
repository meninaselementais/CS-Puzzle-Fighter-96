extends SceneTree
## V11.4.2 glass integration contract tests. Logic only (no match rendering): selection, counts,
## quotas, surface blocks, C4 preservation and the default-off switch. Rendering/performance in a
## real match is validated separately (see relatorios/v11_4_2/RELATORIO_INTEGRACAO_GLASS.md).
const Glass = preload("res://presentation/vfx/glass_shatter.gd")
const Destruction = preload("res://presentation/gem_destruction_vfx.gd")
const Arena = preload("res://presentation/cs_arena.gd")
const GemRules = preload("res://core/gem_rules.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func entry(x: int, y: int, code: int) -> Dictionary:
	var diamond: bool = GemRules.is_diamond(code)
	return {"x":x,"y":y,"code":code,"color":5 if diamond else GemRules.color(code),"is_power":GemRules.kind(code)==GemRules.Kind.POWER,"is_c4":diamond}

func wave_of(items: Array, regions: Array = [], chain: int = 1) -> Dictionary:
	return {"phase":"pre","timer":6,"chain":chain,"removed":items,"powers_before":regions}

func power_items(rect: Rect2i, color: int) -> Array:
	var items: Array = []
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x): items.append(entry(x,y,color|128))
	return items

func integrated(profile: String = "high") -> RefCounted:
	var glass: RefCounted = Glass.new()
	glass.configure_integrated(profile)
	return glass

func test_default_scope() -> void:
	var glass: RefCounted = Glass.new()
	expect(not glass.full_scope,"default scope is the approved V11.4.1 prototype")
	expect(not glass.handles(wave_of([entry(1,12,2)]),Vector2i(1,12)),"prototype scope ignores non-blue single gems")
	expect(glass.handles(wave_of([entry(1,12,1)]),Vector2i(1,12)),"prototype scope still handles blue single gems")
	var rect: Rect2i = Rect2i(0,12,2,2)
	expect(glass.selected(wave_of(power_items(rect,4),[rect])).is_empty(),"prototype scope ignores 2x2 powers")

func test_four_colors() -> void:
	for color in range(1,5):
		var glass: RefCounted = integrated()
		var wave: Dictionary = wave_of([entry(2,12,color)])
		var groups: Array = glass.selected(wave)
		expect(groups.size()==1 and groups[0].color==Glass.TINTS[color] and groups[0].kind=="gem","colour %d common gem keeps its own tint" % color)
		glass.emit(0,wave)
		var event: Dictionary = glass.history[0]
		expect(event.macro==3 and event.micro==300 and event.dust==200,"colour %d single gem counts" % color)

func test_power_dimensions() -> void:
	var sizes: Array[Vector2i] = [Vector2i(2,2),Vector2i(2,3),Vector2i(3,2),Vector2i(5,2),Vector2i(6,4)]
	for dimensions in sizes:
		var glass: RefCounted = integrated()
		var rect: Rect2i = Rect2i(0,14-dimensions.y,dimensions.x,dimensions.y)
		var wave: Dictionary = wave_of(power_items(rect,3),[rect])
		var groups: Array = glass.selected(wave)
		expect(groups.size()==1 and groups[0].rect==rect and groups[0].cells.size()==dimensions.x*dimensions.y and groups[0].kind=="power","power %s is one region matching the real formation (width x height)" % str(dimensions))
		expect(glass.handles(wave,Vector2i(rect.position.x,rect.position.y)),"power %s cells are handled" % str(dimensions))
		glass.emit(0,wave)
		var event: Dictionary = glass.history[0]
		var area: int = dimensions.x*dimensions.y
		expect(event.rect.size==dimensions,"power %s history keeps width x height" % str(dimensions))
		expect(event.macro==mini(Glass.MAX_MACRO,maxi(3,roundi(area*Glass.MACRO_PER_CELL))),"power %s macro count" % str(dimensions))
		expect(event.micro==mini(Glass.MAX_MICRO,area*Glass.MICRO_PER_CELL),"power %s micro count" % str(dimensions))
		expect(event.dust==mini(Glass.MAX_DUST,area*Glass.DUST_PER_CELL),"power %s dust count" % str(dimensions))
	var reference: RefCounted = integrated()
	var plate: Rect2i = Rect2i(1,12,5,2)
	reference.emit(0,wave_of(power_items(plate,4),[plate]))
	var first: Dictionary = reference.history[0]
	expect(first.macro==16 and first.micro==3000 and first.dust==2000,"approved 5x2 reference: 16 macro, 3000 micro, 2000 dust")
	var incomplete: Array = power_items(plate,4)
	incomplete.remove_at(3)
	expect(integrated().selected(wave_of(incomplete,[plate])).is_empty(),"incomplete power region is never half-shattered")

func test_surface_blocks() -> void:
	var glass: RefCounted = integrated()
	var expectations: Dictionary = {Vector2i(1,1):1,Vector2i(5,2):1,Vector2i(2,2):1,Vector2i(2,3):2,Vector2i(6,2):2,Vector2i(6,4):4}
	for dimensions in expectations:
		var group: Dictionary = {"rect":Rect2i(0,6,dimensions.x,dimensions.y),"color":Color.RED}
		var blocks: Array = glass.build_surfaces(group)
		expect(blocks.size()==expectations[dimensions],"surface blocks for %s" % str(dimensions))
		var pixels: float = 0.0
		for block in blocks:
			var sprite: Sprite2D = block.node
			var size: Vector2 = sprite.scale*Vector2(sprite.texture.get_size())
			pixels += size.x*size.y
			expect(sprite.scale.x<=1.0001 and sprite.scale.y<=1.0001,"mask crops are never stretched (%s)" % str(dimensions))
			sprite.free()
		expect(is_equal_approx(pixels,float(dimensions.x*dimensions.y)*1024.0),"blocks cover the whole formation %s" % str(dimensions))

func test_special_gems() -> void:
	var glass: RefCounted = integrated()
	var crash: Dictionary = entry(0,13,9)
	var c4: Dictionary = entry(1,13,5)
	var counter: Dictionary = entry(2,13,GemRules.counter(1,3))
	var normal: Dictionary = entry(3,13,1)
	var wave: Dictionary = wave_of([crash,c4,counter,normal])
	var groups: Array = glass.selected(wave)
	expect(groups.size()==2,"crash and common gems are selected")
	expect(glass.handles(wave,Vector2i(0,13)),"crash gem is glass")
	expect(glass.handles(wave,Vector2i(3,13)),"gem destroyed by C4 or crash is glass")
	expect(not glass.handles(wave,Vector2i(1,13)),"C4 diamond stays with V11.4 effects")
	expect(not glass.handles(wave,Vector2i(2,13)),"counter gem stays with V11.4 effects")
	var kinds: Array = []
	for group in groups: kinds.append(group.kind)
	expect("crash" in kinds and "gem" in kinds,"crash gems are tagged crash")
	expect(glass.selected(wave_of([entry(1,1,1)])).is_empty(),"hidden rows are never glass")

func test_c4_effects_preserved() -> void:
	var items: Array = [entry(1,13,5),entry(2,13,4),entry(3,13,4),entry(4,13,4)]
	for item in items: item["is_c4"] = true
	var glass: RefCounted = integrated()
	var fx: RefCounted = Destruction.new()
	fx.prototype = glass
	var wave: Dictionary = wave_of(items,[],2)
	fx.observe_pre(0,Vector2.ZERO,wave)
	expect(fx.anticipation[0].removed.size()==1,"C4 LED/anticipation kept for the diamond only")
	fx.emit_wave(0,wave)
	expect(fx.bursts.filter(func(b: Dictionary) -> bool: return str(b.kind)=="c4").size()==1,"C4 keeps exactly one shock ring")
	expect(fx.bursts.filter(func(b: Dictionary) -> bool: return str(b.kind)=="cell").size()==1,"only the diamond keeps a V11.4 cell burst")
	expect(fx.motes.size()>=16,"C4 keeps its 16 rays")
	expect(glass.history.size()==3,"each gem destroyed by the C4 becomes glass, once")
	var legacy: RefCounted = Destruction.new()
	var legacy_wave: Dictionary = wave_of(items,[],2)
	legacy.observe_pre(0,Vector2.ZERO,legacy_wave)
	legacy.emit_wave(0,legacy_wave)
	expect(legacy.bursts.filter(func(b: Dictionary) -> bool: return str(b.kind)=="cell").size()==4,"glass off: V11.4 draws every cell")
	expect(legacy.bursts.filter(func(b: Dictionary) -> bool: return str(b.kind)=="c4").size()==1,"glass off: V11.4 C4 ring unchanged")

func test_no_duplicate_effects() -> void:
	var fx: RefCounted = Destruction.new()
	fx.prototype = integrated()
	var rect: Rect2i = Rect2i(1,12,5,2)
	var wave: Dictionary = wave_of(power_items(rect,4),[rect])
	fx.observe_pre(0,Vector2.ZERO,wave)
	expect(fx.anticipation[0].removed.is_empty(),"old anticipation skips glass cells")
	fx.emit_wave(0,wave)
	expect(fx.bursts.is_empty() and fx.motes.is_empty(),"old fragmentation not drawn for glass cells")
	expect(fx.prototype.history.size()==1,"one glass event for the destroyed region")

func test_player_quotas_and_quality() -> void:
	var glass: RefCounted = integrated()
	var rect: Rect2i = Rect2i(1,12,5,2)
	var wave: Dictionary = wave_of(power_items(rect,4),[rect])
	for repetition in range(5): glass.emit(0,wave)
	glass.emit(1,wave)
	var micro: Array[int] = [0,0]
	var dust: Array[int] = [0,0]
	var macro: Array[int] = [0,0]
	for event in glass.history:
		micro[int(event.player)] += int(event.micro)
		dust[int(event.player)] += int(event.dust)
		macro[int(event.player)] += int(event.macro)
	expect(micro[0]==Glass.MAX_MICRO and dust[0]==Glass.MAX_DUST and macro[0]==Glass.MAX_MACRO,"P1 is capped by its own quota")
	expect(micro[1]==3000 and dust[1]==2000 and macro[1]==16,"P2 keeps its full independent quota")
	var profiles: Dictionary = {"high":[16,3000,2000],"medium":[8,1500,1000],"low":[4,750,500]}
	for profile in profiles:
		var scaled: RefCounted = integrated(profile)
		scaled.emit(0,wave)
		var event: Dictionary = scaled.history[0]
		expect(event.macro==profiles[profile][0] and event.micro==profiles[profile][1] and event.dust==profiles[profile][2],"quality profile %s counts" % profile)
	expect(is_equal_approx(integrated("unknown").density,1.0),"unknown profile falls back to high")

func test_cache_and_layouts() -> void:
	var glass: RefCounted = integrated()
	var wave: Dictionary = wave_of([entry(2,12,3)])
	expect(glass.handles(wave,Vector2i(2,12)) and glass.handles(wave,Vector2i(2,12)),"handles is stable across cached calls")
	glass.clear()
	expect(glass.cache.is_empty() and glass.history.is_empty() and glass.groups.is_empty(),"clear resets cache, groups and history")
	expect(glass.handles(wave,Vector2i(2,12)),"handles works after clear")
	var layout: MultiMesh = Glass.layouts["2_3_%d" % Glass.Kind.MICRO] as MultiMesh
	expect(layout != null and layout.instance_count>=1800,"2x3 layouts are pre-warmed")

func test_default_off_switch() -> void:
	var arena: RefCounted = Arena.new()
	expect(arena.destruction.prototype==null and not arena.glass_enabled,"glass presentation is OFF by default")
	expect(arena.set_glass_presentation(true,"medium") and arena.destruction.prototype!=null and arena.glass_enabled,"glass can be switched on")
	expect(arena.destruction.prototype.full_scope and is_equal_approx(arena.destruction.prototype.density,0.5),"switched-on glass uses full scope and the profile")
	expect(not arena.set_glass_presentation(false) and arena.destruction.prototype==null,"glass can be switched off, restoring V11.4")

func _initialize() -> void:
	test_default_scope()
	test_four_colors()
	test_power_dimensions()
	test_surface_blocks()
	test_special_gems()
	test_c4_effects_preserved()
	test_no_duplicate_effects()
	test_player_quotas_and_quality()
	test_cache_and_layouts()
	test_default_off_switch()
	print("GLASS_V11_4_2 checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
