extends Control

const REGULAR_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Regular.ttf")
const BOLD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")

var _prompt: Label
var _elapsed := 0.0
var _opening := false


func _ready() -> void:
	_build_splash()
	_auto_enter_menu()


func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_prompt):
		_prompt.modulate.a = 0.68 + 0.32 * (0.5 + 0.5 * sin(_elapsed * 3.2))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		_open_menu()
	elif event is InputEventMouseButton and event.pressed:
		_open_menu()
	elif event is InputEventScreenTouch and event.pressed:
		_open_menu()


func _build_splash() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 300
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)

	var logo := Label.new()
	logo.text = "PONG EX"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", BOLD_FONT)
	logo.add_theme_font_size_override("font_size", 36)
	logo.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	content.add_child(logo)

	var subtitle := _make_label("NEON ARCADE", 10, REGULAR_FONT, Color(0.26, 0.86, 1.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	var arena_mark := HBoxContainer.new()
	arena_mark.alignment = BoxContainer.ALIGNMENT_CENTER
	arena_mark.add_theme_constant_override("separation", 26)
	content.add_child(arena_mark)
	_add_paddle_mark(arena_mark, Color(0.15, 0.9, 1.0))
	var ball_mark := ColorRect.new()
	ball_mark.color = Color(1.0, 0.96, 0.84)
	ball_mark.custom_minimum_size = Vector2(18, 18)
	ball_mark.size = Vector2(18, 18)
	ball_mark.rotation = deg_to_rad(45.0)
	arena_mark.add_child(ball_mark)
	_add_paddle_mark(arena_mark, Color(1.0, 0.25, 0.22))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 48
	content.add_child(spacer)

	_prompt = _make_label("TAP / PRESS ANY KEY", 8, REGULAR_FONT, Color(0.74, 0.84, 1.0))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_prompt)


func _add_paddle_mark(parent: HBoxContainer, tint: Color) -> void:
	var paddle := ColorRect.new()
	paddle.color = tint
	paddle.custom_minimum_size = Vector2(9, 46)
	paddle.size = Vector2(9, 46)
	parent.add_child(paddle)


func _make_label(value: String, font_size: int, font: FontFile, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _auto_enter_menu() -> void:
	await get_tree().create_timer(3.5).timeout
	_open_menu()


func _open_menu() -> void:
	if _opening:
		return
	_opening = true
	await Transition.transition_to("res://scenes/MainMenu.tscn")
