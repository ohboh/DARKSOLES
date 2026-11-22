shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas : source_color, hint_default_white;
void fragment() {
	float value = dot(texture(atlas, UV).rgb, vec3(.3,.59,.11));
	ALBEDO = vec3(value);
}
