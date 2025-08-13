extends Node

# Number of levels unlocked (starts at 1)
var unlocked_levels: int = 1
var current_level: int = 1

# How many points needed to win a level
var points_to_win: int = 10

# Save file path
const SAVE_FILE := "user://save_data.save"

func _ready() -> void:
	load_progress()

func unlock_next_level() -> void:
	if unlocked_levels < 10:
		unlocked_levels += 1
		save_progress()

func save_progress() -> void:
	var data = {
		"unlocked_levels": unlocked_levels
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if "unlocked_levels" in data:
			unlocked_levels = data["unlocked_levels"]
