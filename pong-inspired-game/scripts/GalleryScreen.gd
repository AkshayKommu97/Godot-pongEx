extends Control

const LEVEL_COUNT := 10
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const REGULAR_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Regular.ttf")
const BOLD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")
const BALL_SKIN = preload("res://scripts/BallSkin.gd")
const BALL_TEXTURE: Texture2D = preload("res://assets/arts/white-circle-svgrepo-com.png")
const ICON_DIR := "res://assets/Icons/kenney_game-icons/PNG/White/1x/"
const COLOR_ACCENT := Color(0.22, 0.62, 1.0)
const COLOR_CLEARED := Color(0.25, 0.92, 0.68)
const COLOR_TEXT := Color(0.91, 0.94, 1.0)
const COLOR_MUTED := Color(0.55, 0.62, 0.76)
const BALL_NAMES: Array[String] = [
	"ION STRIPE", "PINBALL CORE", "ELASTIC SHIELD", "CURVE SPIRAL", "GRAVITY ORBIT",
	"CONTROL SIGIL", "NEON CRYSTAL", "BOSS CORE", "PORTAL RING", "VELOCITY STAR"
]

var _transitioning := false


func _ready() -> void:
	_build_gallery()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_go_back()


func _build_gallery() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 46
	header.add_theme_constant_override("separation", 9)
	layout.add_child(header)

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(58, 40)
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_font_override("font", BOLD_FONT)
	back.add_theme_font_size_override("font_size", 8)
	back.add_theme_color_override("font_color", COLOR_TEXT)
	back.add_theme_color_override("font_hover_color", Color.WHITE)
	back.add_theme_stylebox_override("normal", _panel_style(Color(0.035, 0.05, 0.11, 0.96), Color(0.18, 0.28, 0.46, 1.0)))
	back.add_theme_stylebox_override("hover", _panel_style(Color(0.07, 0.095, 0.18, 0.98), COLOR_ACCENT))
	back.add_theme_stylebox_override("focus", _panel_style(Color(0.07, 0.095, 0.18, 0.98), COLOR_ACCENT))
	back.pressed.connect(_go_back)
	back.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
	header.add_child(back)

	var heading := VBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 1)
	header.add_child(heading)
	var title := _make_label("BALL GALLERY", 16, BOLD_FONT, COLOR_TEXT)
	heading.add_child(title)
	var subtitle := _make_label("WIN LEVELS TO COLLECT", 7, REGULAR_FONT, COLOR_MUTED)
	heading.add_child(subtitle)

	var collected := 0
	for level in range(1, LEVEL_COUNT + 1):
		if GameState.is_level_completed(level):
			collected += 1
	var count := _make_label("%02d / %02d" % [collected, LEVEL_COUNT], 8, BOLD_FONT, COLOR_ACCENT)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(count)

	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 7
	progress.max_value = LEVEL_COUNT
	progress.value = collected
	progress.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.045, 0.06, 0.12, 1.0)
	track.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_ACCENT
	fill.set_corner_radius_all(4)
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	layout.add_child(progress)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 8)
	layout.add_child(grid)
	for level in range(1, LEVEL_COUNT + 1):
		grid.add_child(_create_ball_slot(level))

	var footer := _make_label("CLEAR A LEVEL TO UNLOCK ITS BALL", 7, REGULAR_FONT, COLOR_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.custom_minimum_size.y = 18
	layout.add_child(footer)
	back.call_deferred("grab_focus")


func _create_ball_slot(level: int) -> PanelContainer:
	var is_collected := GameState.is_level_completed(level)
	var tint: Color = GameState.get_cpu_color(level)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 92)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.05, 0.11, 0.96), tint.darkened(0.25) if is_collected else Color(0.15, 0.2, 0.32, 0.85)))

	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 7)
	inset.add_theme_constant_override("margin_top", 7)
	inset.add_theme_constant_override("margin_right", 7)
	inset.add_theme_constant_override("margin_bottom", 7)
	card.add_child(inset)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	inset.add_child(row)

	var preview := TextureRect.new()
	preview.texture = BALL_TEXTURE
	preview.custom_minimum_size = Vector2(36, 36)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if is_collected:
		preview.material = BALL_SKIN.create_material(level)
	else:
		preview.modulate = Color(0.18, 0.23, 0.34, 0.9)
	row.add_child(preview)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 2)
	row.add_child(details)
	var level_label := _make_label("BALL %02d" % level, 7, BOLD_FONT, COLOR_MUTED)
	details.add_child(level_label)
	var name_label := _make_label(BALL_NAMES[level - 1], 8, BOLD_FONT if is_collected else REGULAR_FONT, COLOR_TEXT if is_collected else COLOR_MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_label.custom_minimum_size.y = 22
	details.add_child(name_label)
	var state_label := _make_label("COLLECTED" if is_collected else "WIN LV. %02d" % level, 6, BOLD_FONT, COLOR_CLEARED if is_collected else COLOR_MUTED)
	details.add_child(state_label)
	return card


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _make_label(value: String, font_size: int, font: FontFile, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _go_back() -> void:
	if _transitioning:
		return
	_transitioning = true
	FeedbackAudio.play_transition()
	await Transition.transition_to(MAIN_MENU_SCENE)
