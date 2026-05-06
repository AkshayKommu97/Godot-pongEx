extends CharacterBody2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2(0, -1)

# 🔹 Speed increment variables
var base_speed: float = 300.0
var max_speed: float = 1000.0
var hit_count: int = 0
var is_stopped := false

# Anti-stuck margin
const EDGE_MARGIN := 45.0
const UNSTICK_FORCE := 0.45   # Strong enough to push ball away
# ----------------------------------------------------------
# ⭐ CURVED TRAJECTORY SYSTEM
# ----------------------------------------------------------
var curve_strength: float = 0.0
var curve_target: Node2D = null
var curve_decay := 0.99     # how fast the curve effect fades

func apply_curve(delta: float):
	if curve_target == null:
		return

	var to_target = (curve_target.global_position - global_position).normalized()
	direction =  (direction + to_target * curve_strength * delta * 5.0).normalized()

	curve_strength *= curve_decay
	if curve_strength < 0.005:
		curve_target = null


func _ready() -> void:
	add_to_group("ball")
	randomize()
	direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()


func _physics_process(delta: float) -> void:
	if is_stopped:
		return
	# ⭐ Apply curvature if enabled
	apply_curve(delta)

	var collision = move_and_collide(direction * speed * delta)
	if collision:
		handle_collision(collision)

	check_out_of_bounds()


func check_out_of_bounds() -> void:
	var screen_rect = get_viewport_rect()

	if position.y < 0:
		is_stopped = true
		get_parent().player_scored(1)
		#reset_ball()
	elif position.y > screen_rect.size.y:
		is_stopped = true
		get_parent().player_scored(2)
		#reset_ball()

	if position.x < 0:
		position.x = 0
		direction.x *= -1
	elif position.x > screen_rect.size.x:
		position.x = screen_rect.size.x
		direction.x *= -1


func reset_ball() -> void:
	position = get_viewport_rect().size / 2
	direction = Vector2(randf_range(-0.5, 0.5), -1 if randf() < 0.5 else 1).normalized()
	speed = base_speed
	hit_count = 0
	curve_strength = 0.0
	curve_target = null
	is_stopped = false


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	
	if collider.name == "PlayerPaddle" or collider.name == "CPUPaddle":

		if collider.name == "CPUPaddle":
			if collider.get_node("CollisionShape2D/ColorRect"):
				var color = collider.get_node("CollisionShape2D/ColorRect").color
				print("CPU Paddle Color:", color)

			var paddle_type = GameState.current_level
			handle_paddle_power(paddle_type, collider)
			# ---------------------------------------------------
			# ⚠️ ANTI–STUCK FIX (prevents wall + CPU paddle trap)
			# ---------------------------------------------------
			var screen = get_viewport_rect().size

			# If ball is too close to left edge AND CPU touches it
			if position.x < EDGE_MARGIN:
				direction.x = UNSTICK_FORCE
				position.x += 3

			# If ball is too close to right edge AND CPU touches it
			elif position.x > screen.x - EDGE_MARGIN:
				direction.x = -UNSTICK_FORCE
				position.x -= 3

			# Add small randomness to avoid repeated straight lines
			direction.x += randf_range(-0.15, 0.15)
			direction = direction.normalized()
			# ---------------------------------------------------

		handle_paddle_bounce(collider, collision.get_position())

		# 🔥 Player Paddle — speed boost power
		if collider.name == "PlayerPaddle":
			hit_count += 1
			var t = clamp(hit_count / 10.0, 0.0, 1.0)
			speed = lerp(base_speed, max_speed, t)

			if speed >= max_speed:
				get_parent().player_scored(1)
				reset_ball()

	else:
		direction = direction.bounce(collision.get_normal()).normalized()



# -------------------------------------------------------------------
# 🔥 CPU PADDLE POWER LOGIC
# -------------------------------------------------------------------

func handle_paddle_power(paddle_type: int, paddle: Node) -> void:
	match paddle_type:

		1: # Blue - ⭐ Reset speed ⭐
			speed = base_speed

		2: # Green - ⭐ Spawn bumpers ⭐
			spawn_pinball_bumpers()

		3: # Yellow - Flash clone
			spawn_paddle_clone(paddle)

		4: # Orange - ⭐ CURVED SHOT ⭐ works
			apply_spin()

		5: # Magenta - ⭐ Reverse controls ⭐ works
			reverse_player_controls()

		6: # Cyan - Multi-ball
			spawn_extra_ball()

		7: # Purple - ⭐ Slow ball ⭐ works 
			speed *= 0.7

		8: # Light Gray - Phantom ball
			spawn_phantom_ball()

		9: # Brown - Gravity pull toward CPU
			apply_gravity_pull(paddle)

		10: # White - Stronger phantom
			spawn_stronger_phantom()


# -------------------------------------------------------------------
# 🛠 INDIVIDUAL POWER FUNCTIONS
# -------------------------------------------------------------------

func spawn_pinball_bumpers():
	pass

func spawn_paddle_clone(paddle):
	pass

# ----------------------------------------------------------
# ⭐️ UPDATED SPIN → CURVED TRAJECTORY TOWARD PLAYER
# ----------------------------------------------------------
func apply_spin():
	var player = get_parent().get_node("PlayerPaddle")
	curve_target = player
	curve_strength = randf_range(0.5, 1.0)  # moderate curve


func reverse_player_controls():
	var player = get_tree().get_root().find_child("PlayerPaddle", true, false)
	if player:
		player.speed *= -1

func spawn_extra_ball():
	pass

func spawn_phantom_ball():
	pass

func spawn_stronger_phantom():
	pass


func apply_gravity_pull(paddle):
	var gravity_strength = 5.0
	var to_paddle = (paddle.position - position).normalized()
	direction = (direction + to_paddle * gravity_strength).normalized()



# -------------------------------------------------------------------
func handle_paddle_bounce(paddle: Node2D, collision_point: Vector2) -> void:
	var paddle_shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape as RectangleShape2D
	var paddle_width: float = paddle_shape.extents.x * 2.0
	var offset_x: float = (collision_point.x - paddle.global_position.x) / (paddle_width / 2.0)
	offset_x = clamp(offset_x, -1.0, 1.0)

	var max_bounce_angle = deg_to_rad(75.0)
	var bounce_angle = offset_x * max_bounce_angle
	var new_dir_y = -1.0 if paddle.name == "PlayerPaddle" else 1.0
	direction = Vector2(sin(bounce_angle), new_dir_y * cos(bounce_angle)).normalized()
