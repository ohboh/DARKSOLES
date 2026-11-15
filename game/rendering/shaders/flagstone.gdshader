shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D ground : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 point;
void vertex() { point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
void fragment() {
	// Lay courses continuously across tile and junction boundaries.
	vec2 stone=point.xz/vec2(1.12,.77);
	float row=floor(stone.y);
	stone.x+=.5*mod(row,2.);
	vec2 cell=floor(stone);
	vec2 uv=fract(stone);
	float variation=fract(sin(dot(cell,vec2(17.13,51.71)))*437.19);
	float grit=dot(texture(ground,uv*.36+vec2(.07+.45*step(.5,variation),.56)).rgb,vec3(.3,.59,.11));
	vec2 edge=min(uv,1.-uv)*vec2(1.12,.77);
	float distance_to_joint=min(edge.x,edge.y);
	float aa=max(fwidth(distance_to_joint),.002);
	float slab=smoothstep(.007-aa,.02+aa,distance_to_joint);
	float lip=(1.-smoothstep(.018,.050,distance_to_joint))*slab;
	float value=mix(.02,.22+.42*grit+.075*variation,slab)+.09*lip;
	ALBEDO=vec3(value*illumination(point,CAMERA_POSITION_WORLD,TIME));
}
