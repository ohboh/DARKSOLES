shader_type spatial;
render_mode unshaded;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D planks : source_color, filter_linear_mipmap, repeat_enable;
varying vec2 face;
varying vec3 point;
void vertex() { point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; face=VERTEX.xz*2.; }
void fragment() {
	float radius=length(face);
	float wood=dot(texture(planks,face*.48+.5).rgb,vec3(.30,.59,.11));
	float seam=smoothstep(.012,.035,abs(fract(face.x*2.4+.5)-.5));
	float grain=(.22+.62*wood)*mix(.58,1.,seam);
	float rim=.46+.19*face.y-.11*face.x;
	ALBEDO=vec3(radius>.89?rim:grain)*illumination(point,CAMERA_POSITION_WORLD,TIME);
}
