extends GPUParticles2D


func emit_impact(point: Vector2, normal: Vector2, intensity: float, tint: Color) -> void:
	var material_copy := _copy_material()
	global_position = point
	modulate = tint
	amount = 10
	lifetime = 0.22
	material_copy.spread = 38.0
	material_copy.direction = Vector3(normal.x, normal.y, 0.0)
	material_copy.initial_velocity_min = lerpf(65.0, 125.0, intensity)
	material_copy.initial_velocity_max = lerpf(125.0, 230.0, intensity)
	material_copy.scale_min = lerpf(1.0, 1.5, intensity)
	material_copy.scale_max = lerpf(2.0, 3.5, intensity)
	_start(material_copy)


func emit_ability(point: Vector2, flow: Vector2, intensity: float, tint: Color, ability_id: int) -> void:
	var material_copy := _copy_material()
	global_position = point
	modulate = tint
	var heading := flow.normalized()
	material_copy.spread = 44.0
	amount = 14
	lifetime = 0.24
	material_copy.direction = Vector3(heading.x, heading.y, 0.0)
	material_copy.initial_velocity_min = lerpf(70.0, 115.0, intensity)
	material_copy.initial_velocity_max = lerpf(140.0, 210.0, intensity)
	material_copy.scale_min = 0.8
	material_copy.scale_max = 2.3

	match ability_id:
		1: # Blue: speed reset pulse
			material_copy.spread = 160.0
			amount = 18
			material_copy.direction = Vector3(0.0, 1.0, 0.0)
			material_copy.scale_min = 1.1
			material_copy.scale_max = 2.6
		2: # Green: bumper-like impact
			material_copy.spread = 72.0
			amount = 18
			material_copy.initial_velocity_min *= 0.8
			material_copy.initial_velocity_max *= 0.85
			material_copy.scale_max = 3.0
		3: # Yellow: clean directional streaks
			material_copy.spread = 9.0
			amount = 7
			material_copy.initial_velocity_min *= 1.35
			material_copy.initial_velocity_max *= 1.45
			material_copy.scale_min = 0.4
			material_copy.scale_max = 1.0
		4: # Orange: curved-shot trail accent
			material_copy.spread = 24.0
			material_copy.direction = Vector3(-heading.y, heading.x, 0.0)
			material_copy.initial_velocity_min *= 0.8
			material_copy.initial_velocity_max *= 0.9
		5: # Magenta: reverse-control snap
			material_copy.spread = 20.0
			material_copy.direction = Vector3(-heading.x, -heading.y, 0.0)
			lifetime = 0.18
		6: # Cyan: multi-ball radial cue (visual only)
			material_copy.spread = 180.0
			amount = 22
			material_copy.initial_velocity_min *= 0.85
			material_copy.initial_velocity_max *= 0.9
		7: # Purple: slow-ball lingering pulse
			material_copy.spread = 100.0
			lifetime = 0.34
			material_copy.initial_velocity_min *= 0.45
			material_copy.initial_velocity_max *= 0.5
			material_copy.scale_min = 1.4
			material_copy.scale_max = 3.0
		8: # Light gray: phantom echo cue (visual only)
			material_copy.spread = 170.0
			amount = 10
			lifetime = 0.32
			modulate.a = 0.58
			material_copy.initial_velocity_min *= 0.4
			material_copy.initial_velocity_max *= 0.55
			material_copy.scale_min = 1.3
			material_copy.scale_max = 2.8
		9: # Brown: inward gravity streak
			material_copy.spread = 18.0
			material_copy.direction = Vector3(0.0, -1.0, 0.0)
			material_copy.initial_velocity_min *= 0.75
			material_copy.initial_velocity_max *= 0.85
		10: # White: strong phantom flash (visual only)
			material_copy.spread = 145.0
			amount = 24
			lifetime = 0.2
			material_copy.initial_velocity_min *= 1.3
			material_copy.initial_velocity_max *= 1.4
			material_copy.scale_min = 0.6
			material_copy.scale_max = 1.8

	_start(material_copy)


func _copy_material() -> ParticleProcessMaterial:
	return (process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial


func _start(material_copy: ParticleProcessMaterial) -> void:
	process_material = material_copy
	finished.connect(queue_free, CONNECT_ONE_SHOT)
	emitting = true
