shader_type spatial;
render_mode unshaded, cull_front;
uniform float outline_width : hint_range(1.,10.) = 7.; // Pixels at the 540-wide design size.
void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.);
	vec2 normal = (MODELVIEW_NORMAL_MATRIX * NORMAL).xy;
	clip.xy += normal / max(length(normal), .001) * (2. * outline_width * VIEWPORT_SIZE.x / 540. / VIEWPORT_SIZE) * clip.w;
	POSITION = clip;
}
void fragment() { ALBEDO = vec3(0.); }
