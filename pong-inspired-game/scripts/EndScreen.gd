    extends Control

var final_score = 0
var high_score = 0

func _ready():
    # Load high score from HighScoreManager
    high_score = HighScoreManager.load_high_score()
    update_score_display()
    if FileAccess.file_exists("user://highscore.txt"):
        var file = FileAccess.open("user://highscore.txt", FileAccess.READ)
        if file:
            var score = file.get_var()
            $ScoreLabel.text = "High Score: " + str(score)
            file.close()

func update_score_display():
    $FinalScoreLabel.text = "Final Score: " + str(final_score)
    $HighScoreLabel.text = "High Score: " + str(high_score)

func on_restart_button_pressed():
    get_tree().change_scene("res://scenes/Game.tscn")

func on_quit_button_pressed():
    get_tree().quit()

func _on_EndScreen_timeout():
    # Optionally, you can add logic to automatically return to the main menu after a delay
    get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_menu_button_pressed():
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")