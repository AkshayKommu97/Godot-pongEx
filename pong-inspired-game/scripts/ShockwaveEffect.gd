extends ColorRect

@export var speed := 1.5

var radius := 0.0
var active := false


func _process(delta):
	if active:
		radius += speed * delta
		material.set_shader_parameter("radius", radius)

		# stop after one wave
		if radius > 1.2:
			active = false
			radius = 0.0
			material.set_shader_parameter("radius", 0.0)
			material.set_shader_parameter("active", 0.0)


func trigger_shockwave(screen_pos: Vector2):
	active = true
	radius = 0.0

	# convert to UV (CRITICAL for your shader)
	var uv = screen_pos / get_viewport_rect().size
	material.set_shader_parameter("center", uv)
	# ✅ THIS IS REQUIRED
	material.set_shader_parameter("active", 1.0)
