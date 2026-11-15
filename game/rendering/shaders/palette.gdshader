shader_type canvas_item;
uniform sampler2D composed : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool menu = false;
void fragment() {
	vec3 pixel = texture(composed,SCREEN_UV).rgb;
	float red = pixel.r - max(pixel.g,pixel.b);
	if(menu && max(pixel.g,pixel.b) > .20){ red=0.; }
	float coverage = red > .15 ? pixel.r : dot(pixel,vec3(.30,.59,.11));
	vec2 p = floor(FRAGCOORD.xy);
	float threshold = fract(52.9829189*fract(dot(p,vec2(.06711056,.00583715))));
	// Menus use solid ink with a short, stable halftone transition on illustration edges.
	if(menu){
		threshold=0.29+0.16*mod(p.x+2.*p.y,4.)/3.;
	}
	COLOR = vec4(coverage > threshold ? (red > .15 ? vec3(1.,0.,0.) : vec3(1.)) : vec3(0.),1.);
}

