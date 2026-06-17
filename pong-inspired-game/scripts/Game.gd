extends Node2D

var player1_score: int = 0
var player2_score: int = 0
var is_paused: bool = false
var high_score: int = 0

@onready var shockwave = $UI/ShockwaveFX
const PaddleExplosionScene = preload("res://scenes/Effects/GPUParticles2D.tscn")

@onready var camera: Camera2D = $Camera2D

var shake_strength := 0.0
var shake_decay := 18.0


func _ready() -> void:
	load_high_score()
	update_score_display()

	$UI/PauseButton.pressed.connect(_on_pause_button_pressed)
	$UI/PauseButton.process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta):

	if shake_strength > 0.0:

		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)

	else:
		camera.offset = Vector2.ZERO



# --------------------------------------------------
# PAUSE
# --------------------------------------------------
func _on_pause_button_pressed() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	$UI/PauseButton.text = "Resume" if is_paused else "Pause"


# --------------------------------------------------
# SCORE
# --------------------------------------------------
func reset_scores() -> void:
	player1_score = 0
	player2_score = 0
	update_score_display()


func update_score_display() -> void:
	$UI/ScoreLabel.text = str(player1_score) + " : " + str(player2_score)


# --------------------------------------------------
# BALL FINDER
# --------------------------------------------------
func _find_ball_node() -> Node:
	for node_name in ["Ball", "BallSpin"]:
		if has_node(node_name):
			return get_node(node_name)

	var balls := get_tree().get_nodes_in_group("ball")
	if balls.size() > 0:
		return balls[0]

	return null


# --------------------------------------------------
# SCORING
# --------------------------------------------------
func player_scored(player: int) -> void:
	var ball     := _find_ball_node()
	var exploded_paddle: CharacterBody2D = null
	var ball_pos := Vector2.ZERO
	if ball:
		ball_pos = ball.global_position
		

	if player == 1:
		player1_score += 1
		#spawn_paddle_explosion($CPUPaddle)
		
		exploded_paddle = $CPUPaddle
		disable_paddle(exploded_paddle)
		spawn_paddle_explosion(exploded_paddle)
	else:
		player2_score += 1
		#spawn_paddle_explosion($PlayerPaddle)
		exploded_paddle = $PlayerPaddle
		disable_paddle(exploded_paddle)
		spawn_paddle_explosion(exploded_paddle)

	update_score_display()
	check_high_score()
	_trigger_shockwave(player, ball_pos)
	shake_strength = 18.0
# 🕒 Wait 1 second BEFORE doing anything else
	await get_tree().create_timer(1.0).timeout
	if player1_score >= GameState.points_to_win:
		on_player_wins()
		return
	if player2_score >= GameState.points_to_win:
		on_cpu_wins()
		return
		
	if exploded_paddle:
		enable_paddle(exploded_paddle)
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()



func _trigger_shockwave(scorer: int, ball_pos: Vector2) -> void:
	if shockwave == null:
		return

	#var vp_size := get_viewport_rect().size
#
	#var snap_y : float
	#if scorer == 1:
		#snap_y = 0.0
	#else:
		#snap_y = vp_size.y
#
	#var origin := Vector2(ball_pos.x, snap_y)

	shockwave.trigger_shockwave(ball_pos)

# --------------------------------------------------
# HIGH SCORE
# --------------------------------------------------
func check_high_score() -> void:
	if player1_score > high_score:
		high_score = player1_score
		save_high_score()


func save_high_score() -> void:
	var file := FileAccess.open("user://highscore.txt", FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		file.close()


func load_high_score() -> void:
	if not FileAccess.file_exists("user://highscore.txt"):
		return
	var file := FileAccess.open("user://highscore.txt", FileAccess.READ)
	if file:
		high_score = file.get_var()
		file.close()


# --------------------------------------------------
# WIN STATES
# --------------------------------------------------
func on_player_wins() -> void:
	if GameState.current_level == GameState.unlocked_levels:
		GameState.unlock_next_level()

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func on_cpu_wins() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func spawn_paddle_explosion(paddle: Node2D):

	var explosion = PaddleExplosionScene.instantiate()

	get_tree().current_scene.add_child(explosion)

	var color := Color.WHITE

	var color_rect := paddle.get_node_or_null("CollisionShape2D/ColorRect")

	if color_rect:
		color = color_rect.color

	explosion.explode(paddle.global_position, color)


func disable_paddle(paddle: CharacterBody2D) -> void:
	paddle.visible = false

	paddle.set_process(false)
	paddle.set_physics_process(false)

	var collision := paddle.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true


func enable_paddle(paddle: CharacterBody2D) -> void:
	paddle.visible = true

	paddle.set_process(true)
	paddle.set_physics_process(true)

	var collision := paddle.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = false
