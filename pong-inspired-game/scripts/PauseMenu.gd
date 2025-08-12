extends Control

var is_paused = false

func _ready():
    hide()  # Hide the pause menu initially

func _process(delta):
    if Input.is_action_just_pressed("ui_cancel") and is_paused:
        resume_game()

func show_menu():
    is_paused = true
    show()  # Show the pause menu

func resume_game():
    is_paused = false
    hide()  # Hide the pause menu
    get_tree().paused = false  # Resume the game

func quit_game():
    get_tree().quit()  # Quit the game

func _on_ResumeButton_pressed():
    resume_game()

func _on_QuitButton_pressed():
    quit_game()