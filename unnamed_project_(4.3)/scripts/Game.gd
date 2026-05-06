extends Node2D

var player1_score: int = 0
var player2_score: int = 0
var is_paused: bool = false
var high_score: int = 0

@onready var background: ColorRect = $ColorRect

func _ready() -> void:
	load_high_score()
	update_score_display()
	_update_background()

	$PauseButton.pressed.connect(_on_pause_button_pressed)
	$PauseButton.process_mode = Node.PROCESS_MODE_ALWAYS


# --------------------------------------------------
# PAUSE
# --------------------------------------------------
func _on_pause_button_pressed() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	$PauseButton.text = "Resume" if is_paused else "Pause"


# --------------------------------------------------
# SCORE
# --------------------------------------------------
func reset_scores() -> void:
	player1_score = 0
	player2_score = 0
	update_score_display()
	_update_background()


func update_score_display() -> void:
	$ScoreLabel.text = str(player1_score) + " : " + str(player2_score)


# --------------------------------------------------
# BALL FINDER
# --------------------------------------------------
func _find_ball_node() -> Node:
	for name in ["Ball", "BallSpin"]:
		if has_node(name):
			return get_node(name)

	var balls := get_tree().get_nodes_in_group("ball")
	if balls.size() > 0:
		return balls[0]

	return null



# --------------------------------------------------
# SCORING
# --------------------------------------------------
func player_scored(player: int) -> void:
	if player == 1:
		player1_score += 1
	else:
		player2_score += 1

	update_score_display()
	check_high_score()
	_update_background()

	if player1_score >= GameState.points_to_win:
		on_player_wins()
		return
	if player2_score >= GameState.points_to_win:
		on_cpu_wins()
		return

	var ball := _find_ball_node()
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()


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


# --------------------------------------------------
# BACKGROUND GRADIENT LOGIC (CORE)
# --------------------------------------------------
func _update_background() -> void:
	var cpu_color: Color = GameState.get_cpu_color(GameState.current_level)
	var player_color: Color = Color("#FF0000")

	var max_score := GameState.points_to_win
	var player_ratio := float(player1_score) / max_score
	var cpu_ratio := float(player2_score) / max_score

	var grad := Gradient.new()
	grad.colors = [
		cpu_color.lerp(Color.BLACK, cpu_ratio),   # Top
		player_color.lerp(Color.BLACK, player_ratio) # Bottom
	]

	var tex := GradientTexture2D.new()
	tex.gradient = grad

	background.texture = tex
