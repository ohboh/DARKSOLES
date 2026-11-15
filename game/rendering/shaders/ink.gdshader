shader_type spatial;
render_mode unshaded,cull_disabled;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D atlas : source_color,filter_linear_mipmap,repeat_enable,hint_default_white;
uniform vec4 pigment : source_color = vec4(1.);
uniform float stone = 0.;
uniform float phase = 0.;
varying vec3 local_point;
void vertex(){local_point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
float light=illumination(local_point,CAMERA_POSITION_WORLD,TIME);
vec3 tex=texture(atlas,UV).rgb;
float v=dot(tex,vec3(.3,.59,.11));

// Use the atlas luminance as a height field. Raking light picks out block lips and mortar.
float masonry=0.;
if(stone>.5){
	vec2 texel=1./vec2(textureSize(atlas,0));
	float raised=dot(texture(atlas,UV-texel*vec2(1.,1.)).rgb,vec3(.3,.59,.11));
	float recessed=dot(texture(atlas,UV+texel*vec2(1.,1.)).rgb,vec3(.3,.59,.11));
	float slope=(recessed-raised)/max(.08,v);
	masonry=pow(clamp((v-.085)*1.65,0.,1.),1.05)*clamp(1.+1.9*slope,.18,1.85);
}
ALBEDO=pigment.rgb*mix((.23+.73*pow(v,.75))*(.57+.43*max(0.,dot(normalize(NORMAL),normalize(vec3(-.4,.7,.45))))),masonry,stone)*light*(1.-stone*smoothstep(1.2,4.5,local_point.y-CAMERA_POSITION_WORLD.y));
}
