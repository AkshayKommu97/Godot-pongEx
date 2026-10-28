extends Control

const LEVEL_COUNT: int = 10
const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const LEVEL_SCENE_PATTERN: String = "res://levels/Level_%d.tscn"

const COLOR_ACCENT: Color = Color(0.22, 0.62, 1.0)
const COLOR_TEXT: Color = Color(0.91, 0.94, 1.0)
const COLOR_MUTED: Color = Color(0.55, 0.62, 0.76)
const COLOR_PANEL: Color = Color(0.035, 0.05, 0.11, 0.96)

const REGULAR_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Regular.ttf")
const BOLD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")

@onready var _card_grid: GridContainer = $Content/Layout/CardScroll/CardGrid
@onready var _unlocked_label: Label = $Content/Layout/Header/UnlockedLabel
@onready var _progress_bar: ProgressBar = $Content/Layout/ProgressBar
@onready var _back_button: Button = $Content/Layout/Header/BackButton

var _transitioning: bool = false


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_back_button.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
	_style_back_button()
	_update_progress()
	_build_level_cards()
	_style_progress_bar()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _update_progress() -> void:
	var unlocked_count: int = clampi(GameState.unlocked_levels, 1, LEVEL_COUNT)
	_unlocked_label.text = "%02d / %02d" % [unlocked_count, LEVEL_COUNT]
	_progress_bar.max_value = LEVEL_COUNT
	_progress_bar.value = unlocked_count


func _build_level_cards() -> void:
	var unlocked_count: int = clampi(GameState.unlocked_levels, 1, LEVEL_COUNT)
	var preferred_level := clampi(GameState.current_level, 1, unlocked_count)
	var preferred_card: Button = null
	var first_available: Button = null

	for level in range(1, LEVEL_COUNT + 1):
		var card: Button = _create_level_card(level, unlocked_count)
		_card_grid.add_child(card)
		if level <= unlocked_count and first_available == null:
			first_available = card
		if level == preferred_level:
			preferred_card = card

	var focus_card := preferred_card if preferred_card != null else first_available
	if focus_card != null:
		focus_card.call_deferred("grab_focus")


func _create_level_card(level: int, unlocked_count: int) -> Button:
	var is_locked: bool = level > unlocked_count
	var ability_name: String = GameState.get_level_ability(level)
	var cpu_color: Color = GameState.get_cpu_color(level)
	var card := Button.new()
	card.name = "LevelCard%02d" % level
	card.custom_minimum_size = Vector2(0, 96)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.disabled = is_locked
	card.tooltip_text = "Locked" if is_locked else "Play Level %d" % level
	card.modulate = Color(0.62, 0.67, 0.79, 1.0) if is_locked else Color.WHITE
	card.add_theme_stylebox_override("normal", _make_card_style(COLOR_PANEL, cpu_color.darkened(0.25)))
	card.add_theme_stylebox_override("hover", _make_card_style(Color(0.07, 0.095, 0.18, 0.98), cpu_color))
	card.add_theme_stylebox_override("focus", _make_card_style(Color(0.07, 0.095, 0.18, 0.98), COLOR_ACCENT))
	card.add_theme_stylebox_override("pressed", _make_card_style(Color(0.11, 0.15, 0.27, 1.0), cpu_color.lightened(0.2)))
	card.add_theme_stylebox_override("disabled", _make_card_style(Color(0.025, 0.033, 0.07, 0.94), cpu_color.darkened(0.45)))

	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 10)
	inset.add_theme_constant_override("margin_top", 8)
	inset.add_theme_constant_override("margin_right", 10)
	inset.add_theme_constant_override("margin_bottom", 8)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inset)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(content)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(top_row)

	var level_label := Label.new()
	level_label.text = "LEVEL %02d" % level
	_style_label(level_label, 9, COLOR_MUTED, true)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(level_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(spacer)

	var lock_label := Label.new()
	lock_label.text = "LOCKED" if is_locked else ""
	_style_label(lock_label, 7, COLOR_MUTED, true)
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(lock_label)

	var ability_row := HBoxContainer.new()
	ability_row.add_theme_constant_override("separation", 8)
	ability_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(ability_row)

	var color_swatch := ColorRect.new()
	color_swatch.custom_minimum_size = Vector2(12, 12)
	color_swatch.color = cpu_color
	color_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_row.add_child(color_swatch)

	var ability_label := Label.new()
	ability_label.text = ability_name
	ability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_label.custom_minimum_size.y = 24
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_label.max_lines_visible = 2
	ability_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_style_label(ability_label, 9, COLOR_TEXT, true)
	ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_row.add_child(ability_label)

	card.pressed.connect(_on_level_pressed.bind(level))
	if not is_locked:
		card.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
		card.focus_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
	return card


func _make_card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 4.0
	style.content_margin_top = 4.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 4.0
	return style


func _style_label(label: Label, font_size: int, color: Color, bold: bool = false) -> void:
	label.add_theme_font_override("font", BOLD_FONT if bold else REGULAR_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _style_back_button() -> void:
	_back_button.tooltip_text = "Return to main menu"
	_back_button.add_theme_font_override("font", BOLD_FONT)
	_back_button.add_theme_font_size_override("font_size", 9)
	_back_button.add_theme_color_override("font_color", COLOR_TEXT)
	_back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_back_button.add_theme_color_override("font_pressed_color", COLOR_ACCENT)
	_back_button.add_theme_stylebox_override("normal", _make_card_style(Color(0.035, 0.05, 0.11, 0.96), Color(0.18, 0.28, 0.46, 1.0)))
	_back_button.add_theme_stylebox_override("hover", _make_card_style(Color(0.07, 0.095, 0.18, 0.98), COLOR_ACCENT))
	_back_button.add_theme_stylebox_override("focus", _make_card_style(Color(0.07, 0.095, 0.18, 0.98), COLOR_ACCENT))
	_back_button.add_theme_stylebox_override("pressed", _make_card_style(Color(0.11, 0.15, 0.27, 1.0), COLOR_ACCENT.lightened(0.2)))
func _style_progress_bar() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.045, 0.06, 0.12, 1.0)
	track.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_ACCENT
	fill.set_corner_radius_all(5)
	_progress_bar.add_theme_stylebox_override("background", track)
	_progress_bar.add_theme_stylebox_override("fill", fill)


func _on_level_pressed(level: int) -> void:
	if _transitioning:
		return
	if level > GameState.unlocked_levels:
		return

	var level_path: String = LEVEL_SCENE_PATTERN % level
	if not ResourceLoader.exists(level_path):
		push_error("Level scene not found: " + level_path)
		return

	_transitioning = true
	FeedbackAudio.unlock_audio()
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	GameState.current_level = level
	await Transition.transition_to(level_path)


func _on_back_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	FeedbackAudio.play_transition()
	await Transition.transition_to(MAIN_MENU_SCENE)
