shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D illustration : source_color, filter_linear_mipmap;
uniform float hit_flash = 0.0;
uniform float outline_width : hint_range(1.,10.) = 4.;
varying vec3 point;
void vertex(){point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment() {
	vec3 ink = texture(illustration, UV).rgb;
	float value = dot(ink, vec3(0.30, 0.59, 0.11));
	float light=illumination(point,CAMERA_POSITION_WORLD,TIME);
	vec2 radius_uv=min(fwidth(UV)*outline_width*VIEWPORT_SIZE.x/540.,vec2(.025));
	if (value < .048) {
		// Expand the keyed silhouette outward, preserving the illustrated bones and fingers.
		bool border=false;
		for (int i=0;i<12;i++) {
			float angle=float(i)*TAU/12.;
			vec2 offset=vec2(cos(angle),sin(angle))*radius_uv;
			float edge=dot(texture(illustration,UV+offset).rgb,vec3(.30,.59,.11));
			float inner=dot(texture(illustration,UV+.5*offset).rgb,vec3(.30,.59,.11));
			if(max(edge,inner)>=.048){border=true;break;}
		}
		if(!border){discard;}
		ALBEDO=vec3(0.);
	} else {
		ALBEDO=mix(vec3(pow(value,.75)),vec3(1.),hit_flash)*min(1.,1.45*light);
	}
}
