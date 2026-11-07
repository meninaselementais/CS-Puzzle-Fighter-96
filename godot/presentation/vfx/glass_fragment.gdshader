shader_type canvas_item;
render_mode unshaded, blend_mix;
// CanvasItem blend and mask conventions follow the flash/dissolve templates.
// INSTANCE_CUSTOM: x = variant (integer part) + seed (fraction), y = radial angle / TAU,
// zw = instance scale in pixels. In Godot 4 the MultiMesh instance transform (which carries
// the scale) is applied AFTER this vertex() code, so every pixel-space quantity is divided by zw.
uniform float age = 0.0;
uniform vec4 tint : source_color = vec4(0.25,0.65,1.0,1.0);
uniform int kind = 0; // 0 = macro sliver, 1 = micro shard, 2 = crystal dust
uniform float salt = 0.0; // per-event variation of the shared, cached instance layout
uniform int visible_count = 1000000; // draw only a prefix of the shared layout
varying float variant;
varying float seed;
varying float life;
varying float glint;

float hash(float x) { return fract(sin(x*127.1+311.7)*43758.5453); }

void vertex() {
	seed=fract(fract(INSTANCE_CUSTOM.x)+salt);
	variant=floor(INSTANCE_CUSTOM.x);
	vec2 size=max(INSTANCE_CUSTOM.zw,vec2(0.001));
	float t=age/60.0;
	float a=INSTANCE_CUSTOM.y*6.2831853+(hash(seed*7.0)-0.5)*0.7;
	float r1=hash(seed*13.0);
	float r2=hash(seed*29.0);
	float drag; float speed; float gravity; float fade_start; float fade_end; float spin_rate;
	if(kind==0) { drag=4.0; speed=mix(90.0,240.0,r1); gravity=70.0; fade_start=12.0+r2*8.0; fade_end=28.0+r2*8.0; spin_rate=10.0; }
	else if(kind==1) { drag=5.0; speed=mix(80.0,430.0,pow(r1,1.6)); gravity=45.0; fade_start=6.0+r2*14.0; fade_end=20.0+r2*16.0; spin_rate=22.0; }
	else { drag=2.8; speed=mix(30.0,200.0,r1); gravity=-10.0; fade_start=10.0+r2*18.0; fade_end=30.0+r2*24.0; spin_rate=4.0; }
	life=1.0-smoothstep(fade_start,fade_end,age);
	if(INSTANCE_ID>=visible_count) life=0.0;
	float rot=seed*6.2831853+t*(hash(seed*3.0)-0.5)*spin_rate;
	// Facet reflection: a tumbling shard catches light only at some orientations.
	glint=pow(max(0.0,cos(rot*2.0+seed*40.0)),kind==2 ? 6.0 : 10.0);
	mat2 rotation=mat2(vec2(cos(rot),sin(rot)),vec2(-sin(rot),cos(rot)));
	// Rotate in pixel space (scale first, rotate, unscale) so non-square shards keep their shape.
	VERTEX=(rotation*(VERTEX*size))/size;
	vec2 wobble=kind==2 ? vec2(sin(t*7.0+seed*50.0),cos(t*5.0+seed*31.0))*2.5*t : vec2(0.0);
	vec2 offset=vec2(cos(a),sin(a))*speed*(1.0-exp(-t*drag))/drag+vec2(0.0,gravity*t*t)+wobble;
	VERTEX+=offset/size;
	if(life<=0.0) VERTEX=vec2(0.0); // collapse hidden or expired instances (no fill cost)
}

void fragment() {
	vec3 lit=mix(tint.rgb,vec3(1.0),0.38); // brightened gem colour, never pure white
	if(kind==2) {
		COLOR=vec4(mix(tint.rgb,lit,glint*0.9),life*(0.2+glint*0.6));
	} else {
		vec4 mask=texture(TEXTURE,vec2((UV.x+variant)/8.0,UV.y));
		vec3 body=tint.rgb*(0.55+mask.r*0.5);
		float edge=clamp(mask.g*0.85+mask.b*0.25,0.0,1.0);
		vec3 rgb=mix(body,lit,clamp(edge*0.35+glint*(kind==1 ? 0.8 : 0.65),0.0,1.0));
		float base=kind==0 ? 0.55 : 0.5;
		COLOR=vec4(rgb,mask.a*life*(base+edge*0.25+glint*0.3));
	}
}
