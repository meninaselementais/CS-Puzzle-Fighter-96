shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float age = -1.0;
uniform float progress = 0.0;
uniform vec4 tint : source_color = vec4(0.25,0.65,1.0,1.0);
uniform sampler2D grain : filter_nearest, repeat_enable;
// V11.4.2: a block of the formation. Defaults reproduce the approved V11.4.1 single-sprite result exactly.
uniform vec4 uv_rect = vec4(0.0,0.0,1.0,1.0); // crop of the crack mask (texture UV space)
uniform vec2 g_range = vec2(0.0,1.0); // range of the mask's x-gradient inside the crop
uniform vec4 block_frame = vec4(0.0,0.0,1.0,1.0); // block position and size inside the whole formation (0..1)
uniform vec2 formation_px = vec2(160.0,64.0); // whole formation size in logical pixels
void fragment() {
 vec2 tuv=uv_rect.xy+UV*uv_rect.zw;
 vec4 crack=texture(TEXTURE,tuv);
 float gnorm=clamp((crack.g-g_range.x)/max(g_range.y-g_range.x,0.001),0.0,1.0);
 vec2 fuv=block_frame.xy+UV*block_frame.zw;
 vec3 lit=mix(tint.rgb,vec3(1.0),0.38);
 if(age<0.0) {
  float reveal=step(gnorm*0.65,progress);
  float light=smoothstep(0.55,1.0,progress);
  COLOR=vec4(mix(tint.rgb*0.28,vec3(0.85,0.97,1.0),light),crack.r*reveal*(0.5+light*0.4));
 } else {
  // Apparent crystal-dust density: per-texel grains (about 1 logical pixel), radially expanding.
  float t=age/60.0;
  vec2 q=(fuv-0.5)/(1.0+t*1.7)+0.5;
  vec4 n=texture(grain,q*(formation_px/vec2(100.0,80.0))+vec2(t*0.07,-t*0.11));
  vec2 c=(fuv-0.5)*2.0;
  float border=smoothstep(1.0,0.55,length(c*vec2(0.9,1.0)));
  float fade=1.0-smoothstep(6.0,34.0,age);
  float cloud=texture(grain,q*0.06+vec2(0.3,0.7)).b;
  float grains=step(0.55+cloud*0.25+0.2*(1.0-fade),n.r);
  float shine=step(0.975,n.g)*step(0.55,sin(floor(age/2.0)*1.3+n.b*20.0));
  vec3 rgb=mix(tint.rgb*0.9,lit,shine);
  COLOR=vec4(rgb,border*fade*(grains*0.28+shine*0.4));
  if(age<2.0) COLOR=vec4(mix(tint.rgb,lit,0.5),crack.r*0.7+0.06);
 }
}
