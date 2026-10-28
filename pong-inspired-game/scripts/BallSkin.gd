extends RefCounted

const BALL_SHADER: Shader = preload("res://shaders/BallSkin.gdshader")
const BASE_COLORS: Array[Color] = [
	Color(0.035, 0.06, 0.2), Color(0.025, 0.14, 0.08), Color(0.18, 0.16, 0.025),
	Color(0.2, 0.065, 0.015), Color(0.16, 0.025, 0.16), Color(0.015, 0.12, 0.17),
	Color(0.09, 0.025, 0.18), Color(0.11, 0.12, 0.14), Color(0.14, 0.065, 0.025),
	Color(0.16, 0.16, 0.17)
]
const PRIMARY_COLORS: Array[Color] = [
	Color(0.08, 0.36, 1.0), Color(0.08, 0.92, 0.24), Color(0.88, 0.96, 0.08),
	Color(1.0, 0.38, 0.05), Color(0.94, 0.08, 0.94), Color(0.0, 0.86, 0.96),
	Color(0.52, 0.16, 1.0), Color(0.72, 0.82, 0.9), Color(0.55, 0.27, 0.1),
	Color(0.92, 0.96, 1.0)
]
const SECONDARY_COLORS: Array[Color] = [
	Color(0.48, 0.9, 1.0), Color(0.78, 1.0, 0.34), Color(1.0, 1.0, 0.65),
	Color(1.0, 0.77, 0.3), Color(1.0, 0.62, 0.96), Color(0.72, 1.0, 1.0),
	Color(0.82, 0.66, 1.0), Color(0.98, 0.99, 1.0), Color(1.0, 0.68, 0.34),
	Color(1.0, 1.0, 1.0)
]


static func create_material(level: int) -> ShaderMaterial:
	var index := clampi(level - 1, 0, BASE_COLORS.size() - 1)
	var material := ShaderMaterial.new()
	material.shader = BALL_SHADER
	material.set_shader_parameter("design_id", index + 1)
	material.set_shader_parameter("base_color", BASE_COLORS[index])
	material.set_shader_parameter("primary_color", PRIMARY_COLORS[index])
	material.set_shader_parameter("secondary_color", SECONDARY_COLORS[index])
	return material
