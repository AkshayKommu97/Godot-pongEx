shader_type canvas_item;

uniform int design_id = 1;
uniform vec4 base_color : source_color = vec4(0.04, 0.08, 0.2, 1.0);
uniform vec4 primary_color : source_color = vec4(0.1, 0.7, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.9, 0.97, 1.0, 1.0);

float line_mask(float distance_to_line, float width) {
	return 1.0 - smoothstep(width, width + 0.055, distance_to_line);
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (texel.a < 0.01) {
		discard;
	}

	vec2 point = (UV - vec2(0.5)) * 2.0;
	float radius = length(point);
	float angle = atan(point.y, point.x);
	float pattern = 0.0;
	float core = 0.0;

	if (design_id == 1) {
		pattern = max(line_mask(abs(point.y + point.x * 0.42), 0.09), line_mask(abs(point.y + point.x * 0.42 - 0.42), 0.055));
	} else if (design_id == 2) {
		pattern = max(line_mask(abs(radius - 0.63), 0.055), 0.0);
		pattern = max(pattern, 1.0 - smoothstep(0.11, 0.17, length(point - vec2(-0.36, -0.3))));
		pattern = max(pattern, 1.0 - smoothstep(0.11, 0.17, length(point - vec2(0.36, -0.3))));
		pattern = max(pattern, 1.0 - smoothstep(0.11, 0.17, length(point - vec2(0.0, 0.38))));
	} else if (design_id == 3) {
		pattern = line_mask(abs(radius - 0.68), 0.065) * step(0.0, point.y);
		pattern = max(pattern, line_mask(abs(point.x + 0.34), 0.045) * step(0.1, point.y));
		pattern = max(pattern, line_mask(abs(point.x - 0.34), 0.045) * step(0.1, point.y));
	} else if (design_id == 4) {
		pattern = line_mask(abs(sin(angle * 1.5 + radius * 8.0)), 0.12) * step(0.18, radius) * (1.0 - smoothstep(0.76, 0.9, radius));
	} else if (design_id == 5) {
		pattern = line_mask(abs(radius - 0.62), 0.05);
		pattern = max(pattern, 1.0 - smoothstep(0.12, 0.18, length(point - vec2(cos(2.4) * 0.62, sin(2.4) * 0.62))));
		core = 1.0 - smoothstep(0.25, 0.34, radius);
	} else if (design_id == 6) {
		pattern = max(line_mask(abs(point.x), 0.065), line_mask(abs(point.y), 0.065));
		pattern *= step(0.22, radius) * (1.0 - smoothstep(0.75, 0.9, radius));
	} else if (design_id == 7) {
		pattern = line_mask(abs(abs(point.x) + abs(point.y) - 0.68), 0.06);
		pattern = max(pattern, line_mask(abs(point.x), 0.035) * step(0.35, abs(point.y)));
	} else if (design_id == 8) {
		pattern = max(line_mask(abs(radius - 0.66), 0.05), line_mask(abs(radius - 0.42), 0.045));
		core = 1.0 - smoothstep(0.2, 0.3, radius);
	} else if (design_id == 9) {
		pattern = max(line_mask(abs(radius - 0.68), 0.055), line_mask(abs(radius - 0.49), 0.04));
		pattern = max(pattern, line_mask(abs(sin(angle * 4.0)), 0.14) * step(0.45, radius));
	} else {
		float spokes = line_mask(abs(sin(angle * 5.0)), 0.12) * step(0.32, radius);
		pattern = max(spokes, line_mask(abs(radius - 0.38), 0.05));
		core = 1.0 - smoothstep(0.19, 0.28, radius);
	}

	float rim = 1.0 - smoothstep(0.82, 0.98, radius);
	float highlight = 1.0 - smoothstep(0.015, 0.31, length(point - vec2(-0.31, -0.34)));
	vec3 body = mix(base_color.rgb, primary_color.rgb, clamp(pattern, 0.0, 1.0));
	body = mix(body, secondary_color.rgb, clamp(core * 0.86 + highlight * 0.72, 0.0, 1.0));
	body = mix(body, base_color.rgb * 0.35, rim * 0.42);
	COLOR = vec4(body * texel.rgb * COLOR.rgb, texel.a * COLOR.a);
}
