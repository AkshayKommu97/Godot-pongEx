extends GPUParticles2D

func explode(pos: Vector2, color: Color):
	global_position = pos

	modulate = color
	var process_material := self.process_material as ParticleProcessMaterial
	if process_material:
		process_material.gravity = Vector3.ZERO
	emitting = true

	await finished

	queue_free()
