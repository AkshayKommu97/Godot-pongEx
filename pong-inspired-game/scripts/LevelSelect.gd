extends Control

@onready var vbox: VBoxContainer = $VBoxContainer

func _ready() -> void:
	# Create buttons for each level
	for i in range(1, 11):
		var button: Button = Button.new()
		button.text = "Level %d" % i
		
		# Lock levels beyond unlocked_levels
		button.disabled = i > GameState.unlocked_levels
		
		# Add lock icon if locked
		if i > GameState.unlocked_levels:
			button.text += " 🔒"
		
		# Connect pressed signal with level number
		button.pressed.connect(_on_level_button_pressed.bind(i))
		
		vbox.add_child(button)

func _on_level_button_pressed(level_num: int) -> void:
	# Set current level in GameState
	GameState.current_level = level_num
	
	# Load the actual game scene for that level
	var level_path = "res://levels/Level_%d.tscn" % level_num
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		push_error("Level file not found: " + level_path)
