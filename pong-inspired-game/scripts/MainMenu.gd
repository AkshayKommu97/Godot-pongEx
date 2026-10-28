extends Control

const REGULAR_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Regular.ttf")
const BOLD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")
const HIGHLIGHT_SHADER: Shader = preload("res://shaders/highlight.gdshader")
const LEVEL_SELECT_SCENE := "res://scenes/LevelSelect.tscn"
const CREDITS_SCENE := "res://scenes/CreditsScreen.tscn"
const GALLERY_SCENE := "res://scenes/GalleryScreen.tscn"
const ICON_DIR := "res://assets/Icons/kenney_game-icons/PNG/White/1x/"

var _button_list: Array[Button] = []


func _ready() -> void:
	_build_menu()


func _build_menu() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)

	var logo_area := Control.new()
	logo_area.custom_minimum_size = Vector2(0, 176)
	logo_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(logo_area)

	var logo_glow := Panel.new()
	logo_glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo_glow.position = Vector2(-138, -42)
	logo_glow.size = Vector2(276, 84)
	logo_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_glow.material = _create_highlight_material()
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.75, 0.52, 0.15, 0.84)
	glow_style.corner_radius_top_left = 20
	glow_style.corner_radius_top_right = 20
	glow_style.corner_radius_bottom_left = 20
	glow_style.corner_radius_bottom_right = 20
	logo_glow.add_theme_stylebox_override("panel", glow_style)
	logo_area.add_child(logo_glow)

	var title_row := HBoxContainer.new()
	title_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title_row.position = Vector2(-130, -34)
	title_row.size = Vector2(260, 68)
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 2)
	logo_area.add_child(title_row)

	var title := _make_label("PONG", 39, BOLD_FONT, Color(0.94, 0.97, 1.0))
	title_row.add_child(title)
	var ex := _make_label("EX", 17, BOLD_FONT, Color(0.25, 0.92, 1.0))
	ex.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_row.add_child(ex)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.custom_minimum_size.x = 276
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(menu)
	_add_menu_button(menu, "PLAY", "forward.png", _on_play_pressed, true)
	_add_menu_button(menu, "BALL GALLERY", "trophy.png", _on_gallery_pressed)
	_add_menu_button(menu, "OPTIONS", "gear.png", _on_options_pressed)
	_add_menu_button(menu, "ABOUT", "information.png", _on_about_pressed)
	_add_menu_button(menu, "QUIT", "exitLeft.png", _on_quit_pressed)

	var footer := _make_label("BUILT FOR THE ARCADE", 7, REGULAR_FONT, Color(0.38, 0.54, 0.76, 0.85))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.custom_minimum_size.y = 30
	layout.add_child(footer)

	if not _button_list.is_empty():
		_button_list[0].call_deferred("grab_focus")


func _create_highlight_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = HIGHLIGHT_SHADER
	material.set_shader_parameter("Line_Smoothness", 0.045)
	material.set_shader_parameter("Line_Width", 0.09)
	material.set_shader_parameter("Brightness", 3.0)
	material.set_shader_parameter("Rotation_deg", 30.0)
	material.set_shader_parameter("Distortion", 1.8)
	material.set_shader_parameter("Speed", 0.7)
	material.set_shader_parameter("Position", 0.0)
	material.set_shader_parameter("Position_Min", 0.25)
	material.set_shader_parameter("Position_Max", 0.5)
	material.set_shader_parameter("Alpha", 1.0)
	return material


func _make_label(value: String, font_size: int, font: FontFile, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_menu_button(parent: VBoxContainer, title: String, icon_file: String, pressed_action: Callable, is_primary := false) -> void:
	var button := Button.new()
	button.text = title
	button.icon = _load_icon(icon_file)
	button.expand_icon = true
	button.custom_minimum_size = Vector2(276, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", REGULAR_FONT)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.53))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.02, 0.05, 0.15, 0.88), Color(0.16, 0.34, 0.58, 0.72), 1))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.04, 0.14, 0.29, 0.97), Color(0.18, 0.86, 1.0, 1.0), 2))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.04, 0.14, 0.29, 0.97), Color(0.18, 0.86, 1.0, 1.0), 2))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.24, 0.13, 0.05, 0.96), Color(1.0, 0.62, 0.2, 1.0), 2))
	if is_primary:
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_font_override("font", BOLD_FONT)
	button.pressed.connect(pressed_action)
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))
	button.focus_entered.connect(_on_button_focus.bind(button))
	button.focus_exited.connect(_on_button_exit.bind(button))
	parent.add_child(button)
	_button_list.append(button)


func _load_icon(icon_file: String) -> Texture2D:
	var source := load(ICON_DIR + icon_file) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.resize(20, 20, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _button_style(fill: Color, stroke: Color, stroke_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(stroke_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _on_button_hover(button: Button) -> void:
	FeedbackAudio.play_ui("ui_hover")
	_animate_button(button, 1.025)


func _on_button_focus(button: Button) -> void:
	FeedbackAudio.play_ui("ui_hover")
	_animate_button(button, 1.02)


func _on_button_exit(button: Button) -> void:
	_animate_button(button, 1.0)


func _animate_button(button: Button, target_scale: float) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_play_pressed() -> void:
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	await Transition.transition_to("res://scenes/LevelSelect.tscn")


func _on_options_pressed() -> void:
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	await Transition.transition_to("res://scenes/OptionsMenu.tscn")


func _on_gallery_pressed() -> void:
	FeedbackAudio.play_ui("ui_select")
	await Transition.transition_to(GALLERY_SCENE)


func _on_about_pressed() -> void:
	GameState.show_final_credits = false
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	await Transition.transition_to(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	FeedbackAudio.play_ui("ui_press")
	get_tree().quit()
