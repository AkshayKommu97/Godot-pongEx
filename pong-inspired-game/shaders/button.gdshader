shader_type canvas_item;

uniform vec4 accent_color : source_color =
	vec4(0.2,0.8,1.0,1.0);

uniform float pulse_speed = 2.0;

void fragment() {

	vec4 tex = texture(TEXTURE, UV);

	float pulse =
		0.75 +
		0.25 * sin(TIME * pulse_speed);

	COLOR = vec4(
		tex.rgb * accent_color.rgb * pulse,
		tex.a
	);
}