shader_type canvas_item;
render_mode unshaded;

// The uncovered center stays clear even at the peak of a critical-health beat.
uniform float clear_center : hint_range(0.15, 0.7) = 0.43;
uniform float peak_density : hint_range(0.1, 1.0) = 0.69;
uniform float injury = 0.0;
uniform float impact = 0.0;
uniform float beat = 0.0;

const float BAYER[16] = float[16](0.,8.,2.,10.,12.,4.,14.,6.,3.,11.,1.,9.,15.,7.,13.,5.);

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 offset = (UV - vec2(0.5, 0.55)) * res / (res.x * 0.75);
	float radius = length(offset);
	float strength = max(injury, impact * 0.78);
	float inner = mix(0.98, clear_center, strength);
	float edge = smoothstep(inner, 1.19, radius);
	float coverage = edge * min(0.97, strength * (0.55 + 0.42 * beat) + impact * 0.22);
	float blood = edge * min(coverage, peak_density * injury * (0.30 + 0.70 * beat) + impact * 0.58);
	ivec2 p = ivec2(mod(floor(FRAGCOORD.xy), 4.0));
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	if (threshold >= coverage) { discard; }
	COLOR = vec4(threshold < blood ? vec3(1.,0.,0.) : vec3(0.), 1.);
}
