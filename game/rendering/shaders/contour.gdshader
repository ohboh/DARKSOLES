shader_type spatial;
render_mode unshaded, cull_front;
uniform float outline_width : hint_range(1.,10.) = 7.; // Pixels at the 540-wide design size.
uniform float view_depth_scale = 1.0;
void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.);
	view_position.xyz *= view_depth_scale;
	vec4 clip = PROJECTION_MATRIX * view_position;
	vec2 normal = (MODELVIEW_NORMAL_MATRIX * NORMAL).xy;
	clip.xy += normal / max(length(normal), .001) * (2. * outline_width * VIEWPORT_SIZE.x / 540. / VIEWPORT_SIZE) * clip.w;
	POSITION = clip;
}
void fragment() { ALBEDO = vec3(0.); }
