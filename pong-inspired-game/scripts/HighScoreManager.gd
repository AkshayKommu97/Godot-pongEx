extends Node

var high_scores = []
var max_scores = 5
var file_path = "user://highscores.json"

func _ready():
    load_high_scores()

func load_high_scores():
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        high_scores = JSON.parse(file.get_as_text()).result
        file.close()
    else:
        high_scores = []

func save_high_scores():
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    file.store_string(JSON.print(high_scores))
    file.close()

func add_score(score):
    high_scores.append(score)
    high_scores.sort()
    high_scores.reverse()
    if high_scores.size() > max_scores:
        high_scores.pop_back()
    save_high_scores()

func get_high_scores():
    return high_scores