shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec4 pigment : source_color = vec4(1.);
uniform float view_depth_scale = 1.0;
varying vec3 point;
void vertex() {
	point = (MODEL_MATRIX * vec4(VERTEX, 1.)).xyz;
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.);
	view_position.xyz *= view_depth_scale;
	POSITION = PROJECTION_MATRIX * view_position;
}
void fragment() {
	vec3 tex = texture(atlas, UV).rgb * pigment.rgb;
	float value = dot(tex, vec3(.3, .59, .11));
	float contrast = clamp((value - .12) * 1.65, 0., 1.);
	float light = illumination(point, CAMERA_POSITION_WORLD, TIME);
	ALBEDO = vec3(contrast) * clamp(light * 1.35, .40, 1.);
}
