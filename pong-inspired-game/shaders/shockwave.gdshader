shader_type canvas_item;

uniform float strength: hint_range(0.0, 0.1, 0.001) = 0.08;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.0;

uniform float aberration: hint_range(0.0, 1.0, 0.001) = 0.425;
uniform float width: hint_range(0.0, 0.1, 0.0001) = 0.04;
uniform float feather: hint_range(0.0, 1.0, 0.001) = 0.135;

// ✅ NEW: explicit control
uniform float active = 0.0;

// 🔥 NEW glow controls
uniform vec3 glow_color = vec3(0.3, 0.7, 1.0);
uniform float glow_intensity: hint_range(0.0, 5.0) = 2.0;
uniform float glow_width: hint_range(0.0, 0.1) = 0.01;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {

	vec2 st = SCREEN_UV;

	float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	vec2 scaled_st = (st - vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0.0, 0.5);

	//vec2 dist_center = scaled_st - center;
	vec2 scaled_center = (center - vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0.0, 0.5);
	vec2 dist_center = scaled_st - scaled_center;
	float dist = length(dist_center);

	// ✅ Mask with active control (critical fix)
	float mask = active * (
		(1.0 - smoothstep(radius - feather, radius, dist)) *
		smoothstep(radius - width - feather, radius - width, dist)
	);

	// Avoid NaN when very close to center
	vec2 dir = dist > 0.0001 ? normalize(dist_center) : vec2(0.0);

	vec2 offset = dir * strength * mask;

	vec2 biased_st = scaled_st - offset;

	vec2 abber_vec = offset * aberration;

	vec2 final_st = st * (1.0 - mask) + biased_st * mask;

	// Sample colors
	vec4 original = texture(SCREEN_TEXTURE, SCREEN_UV);

	vec4 red   = texture(SCREEN_TEXTURE, final_st + abber_vec);
	vec4 green = texture(SCREEN_TEXTURE, final_st);
	vec4 blue  = texture(SCREEN_TEXTURE, final_st - abber_vec);

	vec4 effect = vec4(red.r, green.g, blue.b, 1.0);

// ---------------------------
	// 🔥 GLOW RING (NEW)
	// ---------------------------
	float ring = smoothstep(radius - glow_width, radius, dist) -
	             smoothstep(radius, radius + glow_width, dist);

	ring *= active;

	vec3 glow = glow_color * ring * glow_intensity;
	
	
	// ✅ Final blend
	vec4 result = mix(original, effect, mask);
	
	result.rgb += glow;

	COLOR = result;
}