extends Node

var high_scores: Array[int] = []
var max_scores: int = 5
var file_path := "user://highscores.json"

func _ready() -> void:
	load_high_scores()

func load_high_scores() -> void:
	high_scores.clear()
	if not FileAccess.file_exists(file_path):
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Array:
		push_warning("Could not parse high score data; starting with an empty list.")
		return
	for score in json.data:
		if score is int or score is float:
			high_scores.append(int(score))

func save_high_scores() -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save high score data.")
		return
	file.store_string(JSON.stringify(high_scores))
	file.close()

func add_score(score: int) -> void:
	high_scores.append(score)
	high_scores.sort()
	high_scores.reverse()
	if high_scores.size() > max_scores:
		high_scores.pop_back()
	save_high_scores()

func get_high_scores() -> Array[int]:
	return high_scores.duplicate()
