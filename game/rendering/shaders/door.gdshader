shader_type spatial;
render_mode unshaded, cull_disabled;
#include "res://game/rendering/shaders/torchlight.gdshaderinc"
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform float texture_contrast : hint_range(1., 4.) = 1.15;
varying vec3 point;
void vertex() { point = (MODEL_MATRIX * vec4(VERTEX, 1.)).xyz; }
void fragment() {
	float value = dot(texture(atlas, UV).rgb, vec3(.3, .59, .11));
	float detail = clamp((pow(value, .75) - .4) * texture_contrast + .4, .08, 1.);
	float light = illumination(point, CAMERA_POSITION_WORLD, TIME);
	ALBEDO = vec3(.16 + .74 * detail) * min(1., light * 1.5);
}
