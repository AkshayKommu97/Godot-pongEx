extends CharacterBody2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2(0, -1)

@onready var trail_particles: GPUParticles2D = $TrailParticles
@onready var ball_sprite: Sprite2D = get_node_or_null("Sprite2D")
var sprite_rest_scale := Vector2.ONE
var squash_tween: Tween
var ability_trail_color: Color = Color.WHITE
var ability_trail_time: float = 0.0

var dominance := 0

const MAX_DOMINANCE := 10

var player_color := Color.WHITE
var cpu_color := Color.WHITE

var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS := 20

# ðŸ”¹ Speed increment variables
var base_speed: float = 300.0
var max_speed: float = 1000.0
var hit_count: int = 0
var is_stopped := false

# Anti-stuck margin
const EDGE_MARGIN := 45.0
const UNSTICK_FORCE := 0.45   # Strong enough to push ball away
# ----------------------------------------------------------
# â­ CURVED TRAJECTORY SYSTEM
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
	if ball_sprite:
		sprite_rest_scale = ball_sprite.scale
	randomize()
	direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()
	var player_rect = get_parent().get_node(
		"PlayerPaddle/CollisionShape2D/ColorRect"
	)

	var cpu_rect = get_parent().get_node(
		"CPUPaddle/CollisionShape2D/ColorRect"
	)

	player_color = player_rect.color
	cpu_color = cpu_rect.color

	update_trail()

func _physics_process(delta: float) -> void:
	if is_stopped:
		return
	# â­ Apply curvature if enabled
	if ability_trail_time > 0.0:
		ability_trail_time = maxf(0.0, ability_trail_time - delta)
	apply_curve(delta)

	#var collision = move_and_collide(direction * speed * delta)
	#if collision:
		#handle_collision(collision)
	var remaining_motion = direction * speed * delta

	for i in range(4):
		var collision = move_and_collide(remaining_motion)

		if collision == null:
			break

		handle_collision(collision)

		remaining_motion = collision.get_remainder()

	check_out_of_bounds()
	update_trail()


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
		_emit_wall_feedback(Vector2.RIGHT)
	elif position.x > screen_rect.size.x:
		position.x = screen_rect.size.x
		direction.x *= -1
		_emit_wall_feedback(Vector2.LEFT)


func reset_ball() -> void:
	position = get_viewport_rect().size / 2
	if ball_sprite:
		ball_sprite.scale = sprite_rest_scale
		ball_sprite.rotation = 0.0
	direction = Vector2(randf_range(-0.5, 0.5), -1 if randf() < 0.5 else 1).normalized()
	speed = base_speed
	hit_count = 0
	curve_strength = 0.0
	curve_target = null
	is_stopped = false
	dominance = 0
	update_trail()



func handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	
	if collider.name == "PlayerPaddle" or collider.name == "CPUPaddle":

		if collider.name == "CPUPaddle":
			dominance = clamp(
				dominance - 1,
				-MAX_DOMINANCE,
				MAX_DOMINANCE
			)

			
			if collider.get_node("CollisionShape2D/ColorRect"):
				var color = collider.get_node("CollisionShape2D/ColorRect").color
				print("CPU Paddle Color:", color)

			var paddle_type = GameState.current_level
			handle_paddle_power(paddle_type, collider)
			var game := get_parent()
			if game.has_method("play_ability_feedback"):
				game.play_ability_feedback(paddle_type, collision.get_position(), collision.get_normal(), speed, self)
			# ---------------------------------------------------
			# âš ï¸ ANTIâ€“STUCK FIX (prevents wall + CPU paddle trap)
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
		_emit_paddle_feedback(collider, collision)

		# ðŸ”¥ Player Paddle â€” speed boost power
		if collider.name == "PlayerPaddle":
			hit_count += 1
			var t = clamp(hit_count / 10.0, 0.0, 1.0)
			speed = lerp(base_speed, max_speed, t)
			dominance = clamp(
				dominance + 1,
				-MAX_DOMINANCE,
				MAX_DOMINANCE
			)

			#if speed >= max_speed:
				#get_parent().player_scored(1)
				#reset_ball()
			if speed >= max_speed:
				is_stopped = true
				get_parent().player_scored(1)
				return

	else:
		direction = direction.bounce(collision.get_normal()).normalized()



# -------------------------------------------------------------------
# ðŸ”¥ CPU PADDLE POWER LOGIC
# -------------------------------------------------------------------

func handle_paddle_power(paddle_type: int, paddle: Node) -> void:
	match paddle_type:

		1: # Blue - â­ Reset speed â­
			speed = base_speed

		2: # Green - â­ Spawn bumpers â­
			spawn_pinball_bumpers()

		3: # Yellow - Flash clone
			spawn_paddle_clone(paddle)

		4: # Orange - â­ CURVED SHOT â­ works
			apply_spin()

		5: # Magenta - â­ Reverse controls â­ works
			reverse_player_controls()

		6: # Cyan - Multi-ball
			spawn_extra_ball()

		7: # Purple - â­ Slow ball â­ works 
			speed *= 0.7

		8: # Light Gray - Phantom ball
			spawn_phantom_ball()

		9: # Brown - Gravity pull toward CPU
			apply_gravity_pull(paddle)

		10: # White - Stronger phantom
			spawn_stronger_phantom()


# -------------------------------------------------------------------
# ðŸ›  INDIVIDUAL POWER FUNCTIONS
# -------------------------------------------------------------------

func spawn_pinball_bumpers():
	pass

func spawn_paddle_clone(_paddle):
	pass

# ----------------------------------------------------------
# â­ï¸ UPDATED SPIN â†’ CURVED TRAJECTORY TOWARD PLAYER
# ----------------------------------------------------------
func set_ability_trail(tint: Color, duration: float) -> void:
	ability_trail_color = tint
	ability_trail_time = maxf(ability_trail_time, duration)


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
#func handle_paddle_bounce(paddle: Node2D, collision_point: Vector2) -> void:
	#var paddle_shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape as RectangleShape2D
	#var paddle_width: float = paddle_shape.extents.x * 2.0
	#var offset_x: float = (collision_point.x - paddle.global_position.x) / (paddle_width / 2.0)
	#offset_x = clamp(offset_x, -1.0, 1.0)
#
	#var max_bounce_angle = deg_to_rad(75.0)
	#var bounce_angle = offset_x * max_bounce_angle
	#var new_dir_y = -1.0 if paddle.name == "PlayerPaddle" else 1.0
	#direction = Vector2(sin(bounce_angle), new_dir_y * cos(bounce_angle)).normalized()
func handle_paddle_bounce(paddle: Node2D, collision_point: Vector2) -> void:
	var paddle_shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape as RectangleShape2D
	var paddle_width: float = paddle_shape.extents.x * 2.0

	var offset_x: float = (collision_point.x - paddle.global_position.x) / (paddle_width / 2.0)
	offset_x = clamp(offset_x, -1.0, 1.0)

	var max_bounce_angle = deg_to_rad(75.0)
	var bounce_angle = offset_x * max_bounce_angle

	var new_dir_y = -1.0 if paddle.name == "PlayerPaddle" else 1.0

	direction = Vector2(
		sin(bounce_angle),
		new_dir_y * cos(bounce_angle)
	).normalized()

	# Force separation
	position += direction * 10.0
	
func _emit_paddle_feedback(paddle: Node2D, collision: KinematicCollision2D) -> void:
	var tint := Color.WHITE
	var paddle_rect := paddle.get_node_or_null("CollisionShape2D/ColorRect") as ColorRect
	if paddle_rect:
		tint = paddle_rect.color
		if FeedbackAudio.visual_intensity > 0.01:
			var flash := paddle_rect.create_tween()
			flash.tween_property(paddle_rect, "modulate", Color(1.0 + 0.7 * FeedbackAudio.visual_intensity, 1.0 + 0.7 * FeedbackAudio.visual_intensity, 1.0 + 0.7 * FeedbackAudio.visual_intensity, 1.0), 0.045)
			flash.tween_property(paddle_rect, "modulate", Color.WHITE, 0.11)
	_play_squash(collision.get_normal())
	var game := get_parent()
	if game.has_method("play_collision_feedback"):
		game.play_collision_feedback(collision.get_position(), collision.get_normal(), speed, max_speed, tint, &"paddle")


func _emit_wall_feedback(normal: Vector2) -> void:
	_play_squash(normal)
	var game := get_parent()
	if game.has_method("play_collision_feedback"):
		game.play_collision_feedback(global_position, normal, speed, max_speed, Color(0.35, 0.72, 1.0, 1.0), &"wall")


func _play_squash(normal: Vector2) -> void:
	if ball_sprite == null or FeedbackAudio.visual_intensity <= 0.01:
		return
	if squash_tween and squash_tween.is_running():
		squash_tween.kill()
		ball_sprite.scale = sprite_rest_scale
	var intensity: float = clampf(speed / max_speed, 0.25, 1.0)
	var squash: float = lerpf(0.12, 0.28, intensity) * FeedbackAudio.visual_intensity
	ball_sprite.rotation = normal.normalized().angle()
	ball_sprite.scale = sprite_rest_scale
	squash_tween = create_tween()
	squash_tween.tween_property(ball_sprite, "scale", sprite_rest_scale * Vector2(1.0 + squash, 1.0 - squash * 0.55), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(ball_sprite, "scale", sprite_rest_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	squash_tween.parallel().tween_property(ball_sprite, "rotation", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_trail():

	var pm := trail_particles.process_material as ParticleProcessMaterial

	if pm == null:
		return

	trail_particles.emitting = FeedbackAudio.visual_intensity > 0.01

	# Emit opposite direction of movement
	pm.direction = Vector3(
		-direction.x,
		-direction.y,
		0
	)

	var dominance_charge: float = clampf(abs(dominance) / float(MAX_DOMINANCE), 0.0, 1.0)
	var speed_charge: float = clampf((speed - base_speed) / maxf(max_speed - base_speed, 1.0), 0.0, 1.0)
	var charge: float = maxf(dominance_charge, speed_charge * 0.6) * FeedbackAudio.visual_intensity

	var base_color : Color

	if ability_trail_time > 0.0:
		base_color = ability_trail_color
	elif dominance >= 0:
		base_color = player_color
	else:
		base_color = cpu_color

	# Start very dark and reach exact paddle color
	var aura_color = Color(
		base_color.r * (0.2 + charge * 0.8),
		base_color.g * (0.2 + charge * 0.8),
		base_color.b * (0.2 + charge * 0.8),
		1.0
	)

	trail_particles.modulate = aura_color

	# Grow trail size
	pm.scale_min = lerpf(0.35, 0.9, charge)
	pm.scale_max = lerpf(0.9, 2.2, charge)

	# Grow trail density
	trail_particles.amount = int(
		lerpf(20.0, 80.0, charge)
	)
	
func pale_color(c: Color) -> Color:
	return c.lerp(Color.WHITE, 0.85)
