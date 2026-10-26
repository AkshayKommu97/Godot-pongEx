extends Control

@onready var volume_slider: HSlider = $Center/Panel/Options/VolumeSlider
@onready var shake_toggle: CheckButton = $Center/Panel/Options/ShakeToggle
@onready var effects_slider: HSlider = $Center/Panel/Options/EffectsSlider
@onready var options_box: VBoxContainer = $Center/Panel/Options
@onready var back_button: Button = $Center/Panel/Options/BackButton
var _sliders: Dictionary = {}
var _mute_buttons: Dictionary = {}

func _ready() -> void:
	_add_bus_row("MASTER", "Master", FeedbackAudio.master_volume, FeedbackAudio.master_muted)
	_add_bus_row("MUSIC", "Music", FeedbackAudio.music_volume, FeedbackAudio.music_muted)
	_add_bus_row("SFX", "SFX", FeedbackAudio.effects_volume, FeedbackAudio.effects_muted)
	_add_bus_row("UI", "UI", FeedbackAudio.ui_volume, FeedbackAudio.ui_muted)
	$Center/Panel/Options/VolumeLabel.visible = false
	volume_slider.visible = false
	shake_toggle.button_pressed = FeedbackAudio.screen_shake_enabled
	shake_toggle.toggled.connect(FeedbackAudio.set_screen_shake_enabled)
	effects_slider.value = FeedbackAudio.visual_intensity * 100.0
	effects_slider.value_changed.connect(_on_effects_changed)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))
	back_button.call_deferred("grab_focus")

func _add_bus_row(label_text: String, bus: String, initial: float, muted: bool) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 28
	row.add_theme_constant_override("separation", 5)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 54
	label.add_theme_font_size_override("font_size", 8)
	row.add_child(label)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 100
	slider.value = initial * 100.0
	slider.value_changed.connect(func(value: float): FeedbackAudio.set_bus_volume(bus, value / 100.0))
	row.add_child(slider)
	var mute := CheckButton.new()
	mute.text = "M"
	mute.button_pressed = muted
	mute.tooltip_text = "Mute " + label_text
	mute.toggled.connect(func(value: bool): FeedbackAudio.set_bus_muted(bus, value))
	row.add_child(mute)
	options_box.add_child(row)
	options_box.move_child(row, options_box.get_children().find($Center/Panel/Options/VolumeLabel))
	_sliders[bus] = slider
	_mute_buttons[bus] = mute

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		FeedbackAudio.play_ui("ui_press")
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_volume_changed(value: float) -> void:
	FeedbackAudio.set_effects_volume(value / 100.0)
	if _sliders.has("SFX"):
		_sliders["SFX"].value = value

func _on_effects_changed(value: float) -> void:
	FeedbackAudio.set_visual_intensity(value / 100.0)

func _on_back_pressed() -> void:
	FeedbackAudio.play_transition()
	await Transition.transition_to("res://scenes/MainMenu.tscn")

