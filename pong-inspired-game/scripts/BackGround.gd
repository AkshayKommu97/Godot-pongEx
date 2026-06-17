extends ColorRect

var time_passed := 0.0

func _process(delta):
	time_passed += delta

	material.set_shader_parameter("time_val", time_passed)
	material.set_shader_parameter("spin_time", time_passed)
