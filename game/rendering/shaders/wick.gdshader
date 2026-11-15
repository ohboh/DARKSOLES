shader_type spatial;
render_mode unshaded, cull_disabled;
void vertex() {
	// Keep the flame facing the camera as the corridor turns.
	vec3 center=(VIEW_MATRIX*MODEL_MATRIX[3]).xyz;
	POSITION=PROJECTION_MATRIX*vec4(center+vec3(VERTEX.xy,0.),1.);
}
void fragment() {
	float y = 1. - UV.y;
	float sway = (.055 * sin(TIME*8.) + .032 * sin(TIME*13.)) * y*y;
	float width = .42 * pow(max(0.,sin(3.14159*y)),.57) * (1.-.82*y);
	float x = abs(UV.x-.5-sway);
	if (x > width) { discard; }
	ALBEDO = vec3(x < width*.45 && y < .68 ? 1. : .74);
}
