extends Node2D

var player1_score = 0
var player2_score = 0
var is_paused = false
var high_score = 0

func _ready():
	$ScoreLabel.text = "0 : 0"
	$PauseButton.pressed.connect(_on_pause_button_pressed)
	# Set PauseButton to process even when paused
	$PauseButton.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pause_button_pressed():
	is_paused = !is_paused
	get_tree().paused = is_paused
	$PauseButton.text = "Resume" if is_paused else "Pause"

func reset_scores():
	player1_score = 0
	player2_score = 0
	update_score_display()

func update_score_display():
	$ScoreLabel.text = str(player1_score) + " : " + str(player2_score)

func player_scored(player):
	if player == 1:
		player1_score += 1
	else:
		player2_score += 1
	update_score_display()
	check_high_score()
	$Ball.reset_ball()

func check_high_score():
	if player1_score > high_score:
		high_score = player1_score
		save_high_score()

func save_high_score():
	var file = FileAccess.open("user://highscore.txt", FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		file.close()

func load_high_score():
	if FileAccess.file_exists("user://highscore.txt"):
		var file = FileAccess.open("user://highscore.txt", FileAccess.READ)
		if file:
			high_score = file.get_var()
			file.close()
