shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.25;

void fragment() {
	vec2 p = abs(UV - vec2(0.5));
	vec2 size = vec2(0.5 - corner_radius);

	vec2 d = max(p - size, vec2(0.0));

	float dist = length(d);

	float alpha = 1.0 - smoothstep(
		corner_radius - 0.01,
		corner_radius + 0.01,
		dist
	);

	COLOR = vec4(COLOR.rgb, COLOR.a * alpha);
}