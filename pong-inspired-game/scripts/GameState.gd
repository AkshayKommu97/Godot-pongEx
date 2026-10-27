extends Node

const LEVEL_COUNT: int = 10
const SAVE_FILE: String = "user://save_data.save"

const LEVEL_ABILITIES: Dictionary = {
	1: "Speed reset",
	2: "Pinball bumpers",
	3: "Elastic Guard",
	4: "Curved shot",
	5: "Gravity Furnace",
	6: "Control Breaker",
	7: "Neon Bumper",
	8: "Phantom Protocol",
	9: "Portal Gauntlet",
	10: "Maximum Velocity"
}

var unlocked_levels: int = 1
var current_level: int = 1
var points_to_win: int = 5

# One palette is shared by the level cards and the CPU paddle.
var level_colors: Dictionary = {
	1: Color(0.0, 0.0, 1.0),
	2: Color(0.0, 1.0, 0.0),
	3: Color(1.0, 1.0, 0.0),
	4: Color(1.0, 0.5, 0.0),
	5: Color(1.0, 0.0, 1.0),
	6: Color(0.0, 1.0, 1.0),
	7: Color(0.5, 0.0, 1.0),
	8: Color(0.8, 0.8, 0.8),
	9: Color(0.4, 0.2, 0.1),
	10: Color(1.0, 1.0, 1.0)
}


func _ready() -> void:
	load_progress()


func unlock_next_level() -> void:
	if unlocked_levels < LEVEL_COUNT:
		unlocked_levels += 1
		save_progress()


func get_cpu_color(level: int) -> Color:
	return level_colors.get(level, Color.WHITE)


func get_level_ability(level: int) -> String:
	return str(LEVEL_ABILITIES.get(level, "Challenge"))


func save_progress() -> void:
	var data := {
		"unlocked_levels": unlocked_levels,
		"current_level": current_level,
		"points_to_win": points_to_win
	}
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		file.close()
		if data is Dictionary:
			if data.has("unlocked_levels"):
				unlocked_levels = int(data["unlocked_levels"])
			if data.has("current_level"):
				current_level = int(data["current_level"])
			if data.has("points_to_win"):
				points_to_win = int(data["points_to_win"])


func reset_game() -> void:
	unlocked_levels = 1
	current_level = 1
	points_to_win = 5
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
	if FileAccess.file_exists("user://highscore.txt"):
		DirAccess.remove_absolute("user://highscore.txt")
	save_progress()
