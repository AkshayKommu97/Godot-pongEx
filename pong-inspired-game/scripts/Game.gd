extends Node2D

var player1_score: int = 0
var player2_score: int = 0
var is_paused: bool = false
var high_score: int = 0

@onready var shockwave = $UI/ShockwaveFX


func _ready() -> void:
	load_high_score()
	update_score_display()

	$UI/PauseButton.pressed.connect(_on_pause_button_pressed)
	$UI/PauseButton.process_mode = Node.PROCESS_MODE_ALWAYS






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
	var ball_pos := Vector2.ZERO
	if ball:
		ball_pos = ball.global_position
		

	if player == 1:
		player1_score += 1
	else:
		player2_score += 1

	update_score_display()
	check_high_score()
	_trigger_shockwave(player, ball_pos)
# 🕒 Wait 1 second BEFORE doing anything else
	await get_tree().create_timer(1.0).timeout
	if player1_score >= GameState.points_to_win:
		on_player_wins()
		return
	if player2_score >= GameState.points_to_win:
		on_cpu_wins()
		return

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
