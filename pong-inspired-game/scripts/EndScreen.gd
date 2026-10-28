extends Control

var final_score: int = 0
var high_score: int = 0

func _ready() -> void:
	var file := FileAccess.open("user://highscore.txt", FileAccess.READ)
	if file:
		high_score = int(file.get_var())
		file.close()
	update_score_display()

func update_score_display() -> void:
	$FinalScoreLabel.text = "Final Score: " + str(final_score)
	$HighScoreLabel.text = "High Score: " + str(high_score)

func on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_EndScreen_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
