global uniform vec3 torch_0;
global uniform vec3 torch_1;
global uniform vec3 torch_2;
global uniform vec3 torch_3;
global uniform vec3 torch_4;
global uniform vec3 torch_5;

float pool(vec3 point, vec3 center, float radius) {
	vec3 offset = point - center;
	float falloff = max(0.0, 1.0 - dot(offset, offset) / (radius * radius));
	return falloff * falloff;
}

float illumination(vec3 point, vec3 eye, float time) {
	float torch = max(pool(point, torch_0, 3.0), pool(point, torch_1, 3.0));
	torch = max(torch, max(pool(point, torch_2, 3.0), pool(point, torch_3, 3.0)));
	torch = max(torch, max(pool(point, torch_4, 3.0), pool(point, torch_5, 3.0)));
	float flicker = 0.94 + 0.06 * sin(time * 13.0) * sin(time * 7.3);
	return 0.85 * torch * flicker + 0.65 * pool(point, eye, 11.0);
}

