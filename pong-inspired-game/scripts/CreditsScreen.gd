extends Control

const REGULAR_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Regular.ttf")
const BOLD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")
const ICON_DIR := "res://assets/Icons/kenney_game-icons/PNG/White/1x/"

var _ending_credits := false


func _ready() -> void:
	_ending_credits = GameState.show_final_credits
	GameState.show_final_credits = false
	_build_credits()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_go_to_menu()


func _build_credits() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := _make_label("THANKS FOR PLAYING" if _ending_credits else "ABOUT", 19 if _ending_credits else 23, BOLD_FONT, Color(0.93, 0.97, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 66
	layout.add_child(title)
	if _ending_credits:
		var final_studio := _make_label("— MITSORA STUDIO", 10, BOLD_FONT, Color(0.2, 0.88, 1.0))
		final_studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(final_studio)

	var emblem := HBoxContainer.new()
	emblem.alignment = BoxContainer.ALIGNMENT_CENTER
	emblem.add_theme_constant_override("separation", 18)
	layout.add_child(emblem)
	_add_paddle(emblem, Color(0.16, 0.9, 1.0))
	var ball := ColorRect.new()
	ball.color = Color(1.0, 0.95, 0.8)
	ball.custom_minimum_size = Vector2(16, 16)
	ball.size = Vector2(16, 16)
	ball.rotation = deg_to_rad(45.0)
	emblem.add_child(ball)
	_add_paddle(emblem, Color(1.0, 0.26, 0.23))

	if not _ending_credits:
		var studio_label := _make_label("DEVELOPED BY", 9, REGULAR_FONT, Color(0.2, 0.88, 1.0))
		studio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(studio_label)
		var studio_name := _make_label("MITSORA STUDIO", 17, BOLD_FONT, Color(0.96, 0.98, 1.0))
		studio_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(studio_name)

	var divider := ColorRect.new()
	divider.color = Color(0.18, 0.54, 0.84, 0.72)
	divider.custom_minimum_size = Vector2(170, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(divider)

	var details := _make_label("BUILT WITH GODOT\n\nGAME DESIGN  •  CODE  •  AUDIO", 8, REGULAR_FONT, Color(0.66, 0.77, 0.93))
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.y = 70
	layout.add_child(details)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 28
	layout.add_child(spacer)

	var back := Button.new()
	back.text = "BACK TO MENU"
	back.icon = _load_icon("return.png")
	back.expand_icon = true
	back.custom_minimum_size = Vector2(260, 48)
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_font_override("font", REGULAR_FONT)
	back.add_theme_font_size_override("font_size", 9)
	back.add_theme_color_override("font_color", Color(0.84, 0.92, 1.0))
	back.add_theme_color_override("font_hover_color", Color.WHITE)
	back.add_theme_stylebox_override("normal", _button_style(false))
	back.add_theme_stylebox_override("hover", _button_style(true))
	back.add_theme_stylebox_override("focus", _button_style(true))
	back.pressed.connect(_go_to_menu)
	back.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
	back.call_deferred("grab_focus")
	layout.add_child(back)


func _add_paddle(parent: HBoxContainer, tint: Color) -> void:
	var paddle := ColorRect.new()
	paddle.color = tint
	paddle.custom_minimum_size = Vector2(8, 38)
	paddle.size = Vector2(8, 38)
	parent.add_child(paddle)


func _make_label(value: String, font_size: int, font: FontFile, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _load_icon(icon_file: String) -> Texture2D:
	var source := load(ICON_DIR + icon_file) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.resize(20, 20, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _button_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.14, 0.29, 0.97) if is_hovered else Color(0.02, 0.05, 0.15, 0.88)
	style.border_color = Color(0.18, 0.86, 1.0, 1.0) if is_hovered else Color(0.16, 0.34, 0.58, 0.72)
	style.set_border_width_all(2 if is_hovered else 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	return style


func _go_to_menu() -> void:
	FeedbackAudio.play_ui("ui_press")
	await Transition.transition_to("res://scenes/MainMenu.tscn")
