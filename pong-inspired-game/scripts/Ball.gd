extends CharacterBody2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2(0, -1)

# 🔹 New variables for speed increment
var base_speed: float = 300.0
var max_speed: float = 1000.0
var hit_count: int = 0

func _ready() -> void:
	randomize()
	direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		handle_collision(collision)

	check_out_of_bounds()

func check_out_of_bounds() -> void:
	var screen_rect = get_viewport_rect()

	if position.y < 0:
		get_parent().player_scored(1)
		reset_ball()
	elif position.y > get_viewport_rect().size.y:
		get_parent().player_scored(2)
		reset_ball()

	if position.x < 0:
		position.x = 0
		direction.x *= -1
	elif position.x > screen_rect.size.x:
		position.x = screen_rect.size.x
		direction.x *= -1

func reset_ball() -> void:
	position = get_viewport_rect().size / 2
	direction = Vector2(randf_range(-0.5, 0.5), -1 if randf() < 0.5 else 1).normalized()
	speed = base_speed  # Reset speed when round restarts
	hit_count = 0       # Reset hit count

func handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	if collider.name == "PlayerPaddle" or collider.name == "EnemyPaddle":
		handle_paddle_bounce(collider, collision.get_position())

		# 🔹 Increase speed ONLY if PlayerPaddle is hit
		if collider.name == "PlayerPaddle":
			hit_count += 1
			var t = clamp(hit_count / 10.0, 0.0, 1.0) # fraction of progress to max speed
			speed = lerp(base_speed, max_speed, t)
	else:
		direction = direction.bounce(collision.get_normal()).normalized()

func handle_paddle_bounce(paddle: Node2D, collision_point: Vector2) -> void:
	var paddle_shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape as RectangleShape2D
	var paddle_width: float = paddle_shape.extents.x * 2.0
	var offset_x: float = (collision_point.x - paddle.global_position.x) / (paddle_width / 2.0)
	offset_x = clamp(offset_x, -1.0, 1.0)

	var max_bounce_angle = deg_to_rad(75.0)
	var bounce_angle = offset_x * max_bounce_angle
	var new_dir_y = -1.0 if paddle.name == "PlayerPaddle" else 1.0
	direction = Vector2(sin(bounce_angle), new_dir_y * cos(bounce_angle)).normalized()
