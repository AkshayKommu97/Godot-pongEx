extends Control

func _ready():
	print("MainMenu: Checking for buttons...")

	var start_button = $UI/StartButton
	var options_button = $UI/OptionsButton
	var quit_button = $UI/QuitButton

	if start_button:
		start_button.pressed.connect(_on_StartButton_pressed)
	else:
		push_error("StartButton node not found!")

	if options_button:
		options_button.pressed.connect(_on_OptionsButton_pressed)
	else:
		push_error("OptionsButton node not found!")

	if quit_button:
		quit_button.pressed.connect(_on_QuitButton_pressed)
	else:
		push_error("QuitButton node not found!")

func _on_StartButton_pressed():
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	print("StartButton pressed")
	# âœ… Load the LevelSelect scene instead of Game directly
	await Transition.transition_to(
		"res://scenes/LevelSelect.tscn"
	)

func _on_OptionsButton_pressed():
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	get_tree().change_scene_to_file("res://scenes/OptionsMenu.tscn")

func _on_QuitButton_pressed():
	FeedbackAudio.play_ui("ui_press")
	get_tree().quit()
