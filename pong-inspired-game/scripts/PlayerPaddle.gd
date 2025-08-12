extends CharacterBody2D

@export var speed = 400.0
@export var ball_speed_increase = 30.0
@export var max_ball_speed = 800.0

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity = Vector2(direction * speed, 0)

	# Move and detect collision only when paddle moves
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		# safer type check instead of has_variable()
		if collider is CharacterBody2D and collider.name == "Ball":
			# increase ball speed and keep direction
			var ball_vel = collider.velocity
			var new_speed = min(ball_vel.length() + ball_speed_increase, max_ball_speed)
			collider.velocity = ball_vel.normalized() * new_speed

	# usual keep-in-bounds
	move_and_slide()  # if you want to continue using move_and_slide instead, adjust above
	position.x = clamp(position.x, 40, get_viewport_rect().size.x - 40)
	position.y = 550
