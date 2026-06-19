extends Node

# -------------------------------
# LEVEL & PROGRESSION DATA
# -------------------------------

var unlocked_levels: int = 1
var current_level: int = 1

# How many points needed to win a level
var points_to_win: int = 5   # default

# Save file path
const SAVE_FILE := "user://save_data.save"

# CPU paddle colors for each level
var level_colors := {
	1: Color("#0000FF"), # Blue
	2: Color("#00FF00"), # Green
	3: Color("#FFFF00"), # Yellow
	4: Color("#FFA500"), # Orange
	5: Color("#A52A2A"), # Brown
	6: Color("#FF00FF"), # Magenta
	7: Color("#800080"), # Purple
	8: Color("#D3D3D3"), # Light Gray
	9: Color("#FFFFFF"), # White
	10: Color("#00FFFF") # Cyan
}

# -------------------------------
# AUTLOAD INIT
# -------------------------------
func _ready():
	load_progress()


# -------------------------------
# LEVEL UNLOCKING
# -------------------------------
func unlock_next_level() -> void:
	if unlocked_levels < 10:
		unlocked_levels += 1
		save_progress()


# -------------------------------
# CPU COLOR PER LEVEL
# -------------------------------
func get_cpu_color(level: int) -> Color:
	return level_colors.get(level, Color.WHITE)


# -------------------------------
# SAVE / LOAD
# -------------------------------
func save_progress() -> void:
	var data := {
		"unlocked_levels": unlocked_levels,
		"current_level": current_level,
		"points_to_win": points_to_win
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

		if "current_level" in data:
			current_level = data["current_level"]

		if "points_to_win" in data:
			points_to_win = data["points_to_win"]
			
func reset_game() -> void:
	unlocked_levels = 1
	current_level = 1
	points_to_win = 5

	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)

	if FileAccess.file_exists("user://highscore.txt"):
		DirAccess.remove_absolute("user://highscore.txt")

	save_progress()
