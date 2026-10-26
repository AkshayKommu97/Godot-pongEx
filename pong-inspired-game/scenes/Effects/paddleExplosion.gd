extends GPUParticles2D

func explode(pos: Vector2, color: Color):
	global_position = pos

	modulate = color
	var particle_material := self.process_material as ParticleProcessMaterial
	if particle_material:
		particle_material.gravity = Vector3.ZERO
	emitting = true

	await finished

	queue_free()
