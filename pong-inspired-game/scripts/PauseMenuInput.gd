extends Control


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or event.is_echo() or not event.is_action_pressed("ui_cancel"):
		return
	var game := get_tree().current_scene
	if game and game.has_method("_on_resume_pressed"):
		game._on_resume_pressed()
	get_viewport().set_input_as_handled()
