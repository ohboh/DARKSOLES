// Keep each ink dot on whole output pixels to avoid uneven Bayer rows.
vec2 dither_cell(vec2 pixel, vec2 pixel_size) {
	float cell_size = max(1.0, floor(1.0 / (540.0 * pixel_size.x) + 0.5));
	return floor(pixel / cell_size);
}
