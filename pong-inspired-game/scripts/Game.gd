extends Node2D

var player1_score: int = 0
var player2_score: int = 0
var is_paused: bool = false
var high_score: int = 0

@onready var shockwave = $UI/ShockwaveFX
@onready var pause_button: TextureButton = $UI/HUD/PauseButton
@onready var pause_menu: Control = $UI/PauseMenu
@onready var resume_button: Button = $UI/PauseMenu/CenterContainer/Panel/MenuItems/Resume
@onready var restart_button: Button = $UI/PauseMenu/CenterContainer/Panel/MenuItems/Restart
@onready var level_select_button: Button = $UI/PauseMenu/CenterContainer/Panel/MenuItems/Exit
@onready var main_menu_button: Button = $UI/PauseMenu/CenterContainer/Panel/MenuItems/Home
@onready var score_panel: Control = $UI/HUD/ScorePanel
@onready var player_score_label: Label = $UI/HUD/ScorePanel/Scores/PlayerColumn/PlayerScore
@onready var cpu_score_label: Label = $UI/HUD/ScorePanel/Scores/CPUColumn/CPUScore
@onready var level_label: Label = $UI/HUD/LevelLabel
@onready var victory_banner: PanelContainer = $UI/HUD/VictoryBanner
@onready var victory_message: Label = $UI/HUD/VictoryBanner/Message
@onready var camera: Camera2D = get_node_or_null("Camera2D")

const PaddleExplosionScene = preload("res://scenes/Effects/GPUParticles2D.tscn")
const ImpactBurstScene = preload("res://scenes/Effects/ImpactBurst.tscn")
const ChallengeDirectorScript = preload("res://scripts/ChallengeDirector.gd")
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/LevelSelect.tscn"

@export_range(0.0, 24.0, 0.5) var score_shake_intensity: float = 18.0
@export_range(0.0, 0.5, 0.01) var score_shake_duration: float = 0.24
@export_range(300.0, 1000.0, 25.0) var high_speed_impact_threshold: float = 700.0
@export_range(0.0, 8.0, 0.1) var strong_hit_shake_intensity: float = 2.4
var shake_strength := 0.0
var shake_duration := 0.0
var shake_remaining := 0.0
var _rally_hit_count := 0
var _rally_max_display_active := false
var _rally_counter_label: Label
var _rally_counter_bar: ProgressBar
var _rally_max_timer: Timer
var _rally_drain_tween: Tween


func _ready() -> void:
	load_high_score()
	update_score_display()
	_create_rally_counter()
	level_label.text = "LV. %02d" % GameState.current_level
	if GameState.current_level in [5, 6, 7, 8, 9]:
		var challenge := Node2D.new()
		challenge.name = "ChallengeDirector"
		challenge.set_script(ChallengeDirectorScript)
		add_child(challenge)
	FeedbackAudio.play_level_start()

	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	for button in [resume_button, restart_button, level_select_button, main_menu_button]:
		button.mouse_entered.connect(func(): FeedbackAudio.play_ui("ui_hover"))

	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	pause_button.modulate.a = 0.48
	pause_button.mouse_entered.connect(_on_pause_hover)
	pause_button.mouse_exited.connect(_on_pause_exit)


func _create_rally_counter() -> void:
	var hud: Control = $UI/HUD
	var panel := PanelContainer.new()
	panel.name = "RallyHitCounter"
	panel.anchor_left = 0.35
	panel.anchor_top = 0.605
	panel.anchor_right = 0.67
	panel.anchor_bottom = 0.655
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.025, 0.065, 0.62)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1.0, 0.16, 0.2, 0.38)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	_rally_counter_label = Label.new()
	_rally_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rally_counter_label.add_theme_font_override("font", load("res://assets/fonts/Syncopate/Syncopate-Bold.ttf"))
	_rally_counter_label.add_theme_font_size_override("font_size", 6)
	_rally_counter_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.58, 0.82))
	_rally_counter_label.text = "HITS 00 / 10"
	column.add_child(_rally_counter_label)
	_rally_counter_bar = ProgressBar.new()
	_rally_counter_bar.custom_minimum_size = Vector2(100.0, 4.0)
	_rally_counter_bar.min_value = 0.0
	_rally_counter_bar.max_value = 10.0
	_rally_counter_bar.show_percentage = false
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color(0.12, 0.035, 0.065, 0.92)
	bar_background.corner_radius_top_left = 2
	bar_background.corner_radius_top_right = 2
	bar_background.corner_radius_bottom_left = 2
	bar_background.corner_radius_bottom_right = 2
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(1.0, 0.12, 0.2, 0.95)
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	_rally_counter_bar.add_theme_stylebox_override("background", bar_background)
	_rally_counter_bar.add_theme_stylebox_override("fill", bar_fill)
	column.add_child(_rally_counter_bar)
	hud.add_child(panel)
	_rally_max_timer = Timer.new()
	_rally_max_timer.one_shot = true
	_rally_max_timer.timeout.connect(_clear_rally_max_feedback)
	add_child(_rally_max_timer)
	_rally_counter_bar.value = 0.0


func update_rally_hit_counter(hit_count: int) -> void:
	var previous_count := _rally_hit_count
	_rally_hit_count = clampi(hit_count, 0, 10)
	if _rally_hit_count > previous_count:
		FeedbackAudio.play_meter_rise(float(_rally_hit_count) / 10.0)
	if _rally_hit_count >= 10:
		_rally_max_display_active = true
		_rally_counter_label.text = "MAX POWER"
		_rally_counter_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34, 1.0))
		_rally_counter_bar.add_theme_stylebox_override("fill", _rally_counter_max_fill())
		_rally_counter_bar.value = 10.0
		_rally_counter_label.scale = Vector2.ONE
		create_tween().tween_property(_rally_counter_label, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_rally_max_timer.start(0.85)
		return
	if _rally_max_display_active and _rally_hit_count == 0:
		return
	_rally_counter_bar.value = float(_rally_hit_count)
	if not _rally_max_display_active:
		_rally_counter_label.text = "HITS %02d / 10" % _rally_hit_count
		_rally_counter_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.58, 0.82))
		if _rally_hit_count == 0:
			_rally_counter_bar.add_theme_stylebox_override("fill", _rally_counter_normal_fill())


func _rally_counter_normal_fill() -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.12, 0.2, 0.95)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	return fill


func _rally_counter_max_fill() -> StyleBoxFlat:
	var fill := _rally_counter_normal_fill()
	fill.bg_color = Color(1.0, 0.52, 0.12, 1.0)
	return fill


func _clear_rally_max_feedback() -> void:
	_rally_max_display_active = false
	create_tween().tween_property(_rally_counter_label, "scale", Vector2.ONE, 0.12)
	if _rally_hit_count >= 10:
		_rally_counter_label.text = "HITS 10 / 10"
		_rally_counter_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.58, 0.92))
	else:
		update_rally_hit_counter(_rally_hit_count)


func _animate_rally_meter_drain() -> void:
	if not is_instance_valid(_rally_counter_bar):
		return
	FeedbackAudio.play_meter_drain()
	if _rally_drain_tween and _rally_drain_tween.is_running():
		_rally_drain_tween.kill()
	if is_instance_valid(_rally_max_timer):
		_rally_max_timer.stop()
	_rally_max_display_active = false
	_rally_hit_count = 0
	_rally_counter_label.text = "POINT // CHARGE DRAIN"
	_rally_counter_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34, 1.0))
	_rally_counter_label.modulate.a = 1.0
	_rally_counter_bar.modulate.a = 1.0
	_rally_drain_tween = create_tween()
	_rally_drain_tween.tween_property(_rally_counter_bar, "value", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_rally_drain_tween.parallel().tween_property(_rally_counter_bar, "modulate:a", 0.35, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_rally_drain_tween.parallel().tween_property(_rally_counter_label, "modulate:a", 0.35, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_rally_drain_tween.chain().tween_property(_rally_counter_label, "modulate:a", 1.0, 0.14)
	_rally_drain_tween.tween_callback(func() -> void:
		_rally_counter_bar.modulate.a = 1.0
		_rally_counter_label.modulate.a = 1.0
		update_rally_hit_counter(0)
	)


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		FeedbackAudio.unlock_audio()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			_on_resume_pressed()
		else:
			_on_pause_button_pressed()
		get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	FeedbackAudio.play_ui("resume")
	_set_paused(false)
	pause_button.grab_focus()


func _on_restart_pressed() -> void:
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	_set_paused(false)
	await Transition.transition_to("res://levels/Level_%d.tscn" % GameState.current_level)


func _on_level_select_pressed() -> void:
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	_set_paused(false)
	await Transition.transition_to(LEVEL_SELECT_SCENE)


func _on_main_menu_pressed() -> void:
	FeedbackAudio.play_ui("ui_select")
	FeedbackAudio.play_transition()
	_set_paused(false)
	await Transition.transition_to(MAIN_MENU_SCENE)


func _on_pause_hover() -> void:
	pause_button.create_tween().tween_property(pause_button, "modulate:a", 0.95, 0.15)


func _on_pause_exit() -> void:
	pause_button.create_tween().tween_property(pause_button, "modulate:a", 0.48, 0.15)


func _on_pause_button_pressed() -> void:
	FeedbackAudio.play_ui("pause" if not is_paused else "resume")
	_set_paused(not is_paused)


func _set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	pause_button.visible = not value
	if value:
		pause_menu.visible = true
		pause_menu.pivot_offset = pause_menu.size * 0.5
		pause_menu.scale = Vector2(0.975, 0.975)
		pause_menu.modulate.a = 0.0
		var open_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		open_tween.set_parallel(true)
		open_tween.tween_property(pause_menu, "modulate:a", 1.0, 0.16)
		open_tween.tween_property(pause_menu, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		resume_button.call_deferred("grab_focus")
	else:
		var close_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		close_tween.set_parallel(true)
		close_tween.tween_property(pause_menu, "modulate:a", 0.0, 0.12)
		close_tween.tween_property(pause_menu, "scale", Vector2(0.985, 0.985), 0.12)
		close_tween.finished.connect(func() -> void:
			if not is_paused:
				pause_menu.visible = false
		)


func _process(delta: float) -> void:
	if camera == null:
		return
	if shake_remaining > 0.0:
		shake_remaining = maxf(0.0, shake_remaining - delta)
		var envelope: float = shake_remaining / maxf(shake_duration, 0.001)
		var current_intensity: float = shake_strength * envelope
		camera.offset = Vector2(randf_range(-current_intensity, current_intensity), randf_range(-current_intensity, current_intensity))
	else:
		camera.offset = Vector2.ZERO
		shake_strength = 0.0
		shake_duration = 0.0


func trigger_camera_shake(intensity: float, duration: float) -> void:
	if camera == null or intensity <= 0.0 or duration <= 0.0 or not FeedbackAudio.screen_shake_enabled:
		return
	shake_strength = maxf(shake_strength, intensity * FeedbackAudio.visual_intensity)
	shake_duration = maxf(shake_duration, duration)
	shake_remaining = maxf(shake_remaining, duration)


func reset_scores() -> void:
	player1_score = 0
	player2_score = 0
	update_score_display()


func update_score_display(scored_player: int = 0) -> void:
	player_score_label.text = str(player1_score)
	cpu_score_label.text = str(player2_score)
	if scored_player == 1:
		_animate_score(player_score_label)
	elif scored_player == 2:
		_animate_score(cpu_score_label)


func _animate_score(label: Label) -> void:
	if FeedbackAudio.visual_intensity <= 0.01:
		label.scale = Vector2.ONE
		label.modulate = Color.WHITE
		score_panel.scale = Vector2.ONE
		score_panel.modulate = Color.WHITE
		return
	label.pivot_offset = label.size * 0.5
	var cpu_accent: Color = GameState.get_cpu_color(GameState.current_level).lightened(0.2)
	var accent: Color = Color(0.35, 0.88, 1.0, 1.0) if label == player_score_label else cpu_accent
	accent = Color.WHITE.lerp(accent, FeedbackAudio.visual_intensity)
	label.modulate = accent
	score_panel.pivot_offset = score_panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color.WHITE, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_panel, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_panel, "modulate", accent, 0.1)
	tween.chain().tween_property(score_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(score_panel, "modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func play_ability_feedback(ability_id: int, point: Vector2, normal: Vector2, impact_speed: float, ball: Node2D) -> void:
	if FeedbackAudio.visual_intensity > 0.01:
		var burst := ImpactBurstScene.instantiate()
		get_tree().current_scene.add_child(burst)
		var intensity := clampf(impact_speed / 1000.0, 0.25, 1.0) * FeedbackAudio.visual_intensity
		burst.emit_ability(point, normal, intensity, GameState.get_cpu_color(ability_id), ability_id)
	FeedbackAudio.play_ability(ability_id, impact_speed / 1000.0)
	if ability_id == 4 and FeedbackAudio.visual_intensity > 0.01 and ball.has_method("set_ability_trail"):
		ball.set_ability_trail(GameState.get_cpu_color(ability_id), 1.0)

func play_collision_feedback(point: Vector2, normal: Vector2, impact_speed: float, max_impact_speed: float, tint: Color, kind: StringName = &"paddle") -> void:
	if FeedbackAudio.visual_intensity > 0.01:
		var burst := ImpactBurstScene.instantiate()
		get_tree().current_scene.add_child(burst)
		var intensity := clampf(impact_speed / max_impact_speed, 0.25, 1.0) * FeedbackAudio.visual_intensity
		burst.emit_impact(point, normal, intensity, tint)
	FeedbackAudio.play_hit(impact_speed / max_impact_speed, kind)
	if impact_speed >= high_speed_impact_threshold:
		trigger_camera_shake(strong_hit_shake_intensity, 0.1)


func _find_ball_node() -> Node:
	for node_name in ["Ball", "BallSpin"]:
		if has_node(node_name):
			return get_node(node_name)
	var balls := get_tree().get_nodes_in_group("ball")
	return balls[0] if not balls.is_empty() else null


func player_scored(player: int) -> void:
	var challenge: Node = get_node_or_null("ChallengeDirector")
	if challenge:
		challenge.reset_round()
	var ball := _find_ball_node()
	var exploded_paddle: CharacterBody2D = null
	var ball_pos: Vector2 = ball.global_position if ball else Vector2.ZERO
	if player == 1:
		_animate_rally_meter_drain()
		player1_score += 1
		exploded_paddle = $CPUPaddle
	else:
		player2_score += 1
		exploded_paddle = $PlayerPaddle
	disable_paddle(exploded_paddle)
	if FeedbackAudio.visual_intensity > 0.05:
		spawn_paddle_explosion(exploded_paddle)
	update_score_display(player)
	check_high_score()
	_trigger_shockwave(player, ball_pos)
	FeedbackAudio.play_score(player)
	trigger_camera_shake(score_shake_intensity, score_shake_duration)
	await get_tree().create_timer(1.0).timeout
	if player1_score >= GameState.points_to_win:
		on_player_wins()
		return
	if player2_score >= GameState.points_to_win:
		on_cpu_wins()
		return
	if exploded_paddle:
		enable_paddle(exploded_paddle)
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()


func try_player_point(scoring_ball: CharacterBody2D) -> void:
	if scoring_ball == null or scoring_ball.get("player_point_claimed"):
		return
	if GameState.current_level == 7:
		scoring_ball.reset_ball()
		return
	if GameState.current_level == 9 or GameState.current_level == 10:
		if int(scoring_ball.get("hit_count")) < 10:
			var challenge := get_node_or_null("ChallengeDirector")
			if challenge:
				challenge._set_notice("METER NOT FULL // 10 HITS TO SCORE", 1.0)
			scoring_ball.reset_ball()
			return
	var challenge: Node = get_node_or_null("ChallengeDirector")
	if challenge and not challenge.can_score_player_point(scoring_ball):
		challenge._set_notice(challenge.rejected_point_message(), 1.5)
		if scoring_ball and scoring_ball.has_method("reset_ball"):
			scoring_ball.reset_ball()
		return
	scoring_ball.set("player_point_claimed", true)
	player_scored(1)


func _trigger_shockwave(_scorer: int, ball_pos: Vector2) -> void:
	if shockwave and FeedbackAudio.visual_intensity > 0.08:
		shockwave.trigger_shockwave(ball_pos)


func check_high_score() -> void:
	if player1_score > high_score:
		high_score = player1_score
		save_high_score()


func save_high_score() -> void:
	var file := FileAccess.open("user://highscore.txt", FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		file.close()


func load_high_score() -> void:
	if not FileAccess.file_exists("user://highscore.txt"):
		return
	var file := FileAccess.open("user://highscore.txt", FileAccess.READ)
	if file:
		high_score = file.get_var()
		file.close()


func on_player_wins() -> void:
	if GameState.current_level == GameState.unlocked_levels:
		GameState.unlock_next_level()
	_show_victory_feedback("LEVEL CLEARED")
	await get_tree().create_timer(1.0).timeout
	if GameState.current_level == GameState.LEVEL_COUNT:
		GameState.show_final_credits = true
		await Transition.transition_to("res://scenes/CreditsScreen.tscn")
		return
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func on_cpu_wins() -> void:
	_show_victory_feedback("CPU WINS")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _show_victory_feedback(message: String) -> void:
	if message == "LEVEL CLEARED":
		FeedbackAudio.play_victory()
		FeedbackAudio.play_level_complete()
	else:
		FeedbackAudio.play_score(2)
	victory_message.text = message
	victory_banner.visible = true
	if FeedbackAudio.visual_intensity <= 0.01:
		victory_banner.scale = Vector2.ONE
		victory_banner.modulate = Color.WHITE
		return
	victory_banner.pivot_offset = victory_banner.size * 0.5
	victory_banner.scale = Vector2.ONE * lerpf(0.98, 0.9, FeedbackAudio.visual_intensity)
	victory_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(victory_banner, "modulate:a", 1.0, 0.24)
	tween.tween_property(victory_banner, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	trigger_camera_shake(3.0, 0.16)
	play_collision_feedback(get_viewport_rect().size * 0.5, Vector2.UP, 600.0, 1000.0, Color(0.35, 0.8, 1.0, 1.0))

func spawn_paddle_explosion(paddle: Node2D) -> void:
	var explosion = PaddleExplosionScene.instantiate()
	get_tree().current_scene.add_child(explosion)
	var color := Color.WHITE
	var color_rect := paddle.get_node_or_null("CollisionShape2D/ColorRect")
	if color_rect:
		color = color_rect.color
	explosion.explode(paddle.global_position, color)


func disable_paddle(paddle: CharacterBody2D) -> void:
	paddle.visible = false
	paddle.set_process(false)
	paddle.set_physics_process(false)
	var collision := paddle.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true


func enable_paddle(paddle: CharacterBody2D) -> void:
	paddle.visible = true
	paddle.set_process(true)
	paddle.set_physics_process(true)
	var collision := paddle.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = false
