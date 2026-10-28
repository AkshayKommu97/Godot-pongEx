extends Node2D
const HUD_FONT: FontFile = preload("res://assets/fonts/Syncopate/Syncopate-Bold.ttf")
const LEVEL_7_BUMPER_SIZES: Array[Vector2] = [Vector2(82.0, 18.0), Vector2(64.0, 18.0), Vector2(48.0, 18.0), Vector2(34.0, 18.0), Vector2(20.0, 20.0)]
const LEVEL_7_BUMPER_GAP := 12.0
const BOSS_ATTACK_BALL_SCRIPT = preload("res://scripts/BossAttackBall.gd")
@export_range(10.0, 60.0, 1.0) var portal_exit_angle_min := 20.0
@export_range(20.0, 70.0, 1.0) var portal_exit_angle_max := 55.0
var level_id := 0
var elapsed := 0.0
var notice_text := ""
var notice_left := 0.0
var reverse_warning := 0.0
var reverse_left := 0.0
var _reverse_just_armed := false
var _previous_gate_y: Dictionary = {}
var _gravity_charge := false
var _rally_flip := false
var _portal_positions: Array[Vector2] = [Vector2(82.0, 285.0), Vector2(278.0, 435.0)]
var _portal_flash_left := 0.0
var _portal_flash_position := Vector2.ZERO
var _hud: Label
var _well_x := 180.0
var _level7_bumper_rects: Array[Rect2] = []
var _level7_bumper_active: Array[bool] = []
var _level7_respawn_left := 0.0
var _level8_core: Area2D
var _level8_core_exposed := false
var _level8_attack_cooldown := 1.4
var _level8_attack_ball: CharacterBody2D
func _ready() -> void:
	level_id = GameState.current_level
	z_index = -1
	var canvas := CanvasLayer.new(); canvas.layer = 9; add_child(canvas)
	_hud = Label.new(); _hud.anchor_right = 1.0; _hud.offset_top = 148; _hud.offset_bottom = 172
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud.add_theme_font_override("font", HUD_FONT); _hud.add_theme_font_size_override("font_size", 8)
	_hud.add_theme_color_override("font_color", GameState.get_cpu_color(level_id).lightened(0.35)); _hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; canvas.add_child(_hud)
	if level_id == 8: _setup_level8_boss()
	if level_id == 9: _create_portals()
	if level_id == 7: _create_level7_scoring_bumpers()
	_set_notice(_title(), 1.7)
func _title() -> String:
	match level_id:
		5: return "GRAVITY FURNACE"
		6: return "CONTROL BREAKER"
		7: return "NEON BUMPER"
		8: return "CORE BREAKER"
		9: return "PORTAL GAUNTLET"
	return ""
func _process(delta: float) -> void:
	elapsed += delta; notice_left = maxf(0, notice_left-delta)
	_portal_flash_left = maxf(0.0, _portal_flash_left - delta)
	if _level7_respawn_left > 0.0:
		_level7_respawn_left = maxf(0.0, _level7_respawn_left - delta)
		if _level7_respawn_left == 0.0 and level_id == 7:
			_create_level7_scoring_bumpers()
	if level_id == 8:
		_process_level8_boss(delta)
	if reverse_warning>0:
		reverse_warning=maxf(0,reverse_warning-delta)
		if reverse_warning==0 and _reverse_just_armed: reverse_left=1.65; _reverse_just_armed=false; _set_notice("CONTROLS REVERSED",reverse_left)
	else: reverse_left=maxf(0,reverse_left-delta)
	_update_hud(); queue_redraw()
func _update_hud() -> void:
	if reverse_warning>0: _hud.text="CONTROL FLIP IN %.1f" % reverse_warning
	elif reverse_left>0: _hud.text="REVERSED // %.1f" % reverse_left
	elif level_id==5: _hud.text="CORE CHARGED // SCORE" if _gravity_charge else "PASS THE MOVING CORE // SCORE"
	elif level_id==6: _hud.text="RETURN DURING CONTROL FLIP"
	elif level_id==7: _hud.text="HIT THE NEON BUMPER TO SCORE"
	elif level_id==8: _hud.text = "CORE OPEN // RETURN THE RED BALL" if _level8_core_exposed else "BOSS ATTACK // RETURN IT TO THE CORE"
	elif level_id==9:
		var main_ball := get_parent().get_node_or_null("Ball")
		_hud.text = "PORTALS // %d / 10 HITS" % mini(main_ball.hit_count, 10) if main_ball else "PORTALS // SCORE AT 10 HITS"
	elif notice_left>0: _hud.text=notice_text
	else: _hud.text=_title()
	_hud.modulate.a=0.9
func _set_notice(text: String,duration: float) -> void: notice_text=text; notice_left=duration
func is_control_reversed() -> bool: return reverse_left>0
func on_cpu_return(_ball: CharacterBody2D) -> void:
	if level_id==6 and randf()<0.55: reverse_warning=0.42; _reverse_just_armed=true; _set_notice("CONTROL FLIP IN 0.4",0.42)
func on_player_return(_ball: CharacterBody2D) -> void:
	if level_id==6 and reverse_left>0: _rally_flip=true
func apply_ball_challenge(ball: CharacterBody2D,delta: float) -> void:
	if level_id==5:
		_well_x=180+78*sin(elapsed*0.72); var pull=Vector2(_well_x,360)-ball.position; var dist=pull.length(); var radius=190.0
		if dist<radius: ball.direction=(ball.direction+pull.normalized()*3.4*pow(1-dist/radius,1.4)*delta).normalized()
		if level_id==5 and dist<58: _gravity_charge=true
func _create_portals() -> void:
	for portal_index in range(2):
		var portal := Area2D.new()
		portal.name = "Portal_%d" % (portal_index + 1)
		portal.position = _portal_positions[portal_index]
		portal.collision_layer = 0
		portal.collision_mask = 1
		var collision := CollisionShape2D.new()
		var portal_shape := CircleShape2D.new()
		portal_shape.radius = 28.0
		collision.shape = portal_shape
		portal.add_child(collision)
		portal.body_entered.connect(_on_portal_body_entered.bind(portal_index))
		add_child(portal)

func _on_portal_body_entered(body: Node2D, entry_index: int) -> void:
	if not body.is_in_group("ball") or float(body.get("portal_cooldown")) > 0.0 or bool(body.get("is_echo_ball")):
		return
	var exit_position := _portal_positions[1 - entry_index]
	var angle := deg_to_rad(randf_range(portal_exit_angle_min, portal_exit_angle_max))
	var horizontal_sign := -1.0 if randf() < 0.5 else 1.0
	var exit_direction := Vector2(horizontal_sign * sin(angle), cos(angle)).normalized()
	var kept_speed := float(body.get("speed"))
	body.position = exit_position + exit_direction * 40.0
	body.set("direction", exit_direction)
	body.set("speed", kept_speed)
	body.set("portal_cooldown", 0.55)
	if body.has_method("update_trail"): body.update_trail()
	_portal_flash_position = exit_position
	_portal_flash_left = 0.36
	FeedbackAudio.play_ui("ui_select")
func cpu_target_x(ball: Node2D) -> float:
	if level_id!=9: return ball.position.x
	var direction: Vector2=ball.get("direction"); var speed=float(ball.get("speed"))
	if direction.y>=-0.08: return ball.position.x
	var time=(20.0-ball.position.y)/minf(direction.y*speed,-30); var raw=ball.position.x+direction.x*speed*time; var span=300.0; var fold=fposmod(raw-30,span*2)
	return 30+(fold if fold<=span else span*2-fold)
func cpu_smoothness() -> float: return 10.5 if level_id==9 else 8.0
func can_score_player_point(_ball: CharacterBody2D) -> bool:
	match level_id:
		5: return _gravity_charge
		6: return _rally_flip
		8: return false
		9: return _ball.hit_count >= 10
	return true
func rejected_point_message() -> String:
	match level_id:
		5: return "PASS THROUGH MOVING CORE FIRST"
		6: return "RETURN DURING CONTROL FLIP"
		7: return "HIT THE NEON BUMPER TO SCORE"
		8: return "NORMAL RALLIES CANNOT DAMAGE THE BOSS"
		9: return "METER NOT FULL // 10 HITS TO SCORE"
	return "RALLY RESET"
func _setup_level8_boss() -> void:
	var player := get_parent().get_node_or_null("PlayerPaddle") as CharacterBody2D
	if player:
		# Layer 3 is reserved for boss attacks so they only collide with the player.
		player.collision_layer |= 4
	_level8_core = Area2D.new()
	_level8_core.name = "ExposedCore"
	_level8_core.position = Vector2(180.0, 47.0)
	_level8_core.collision_layer = 0
	_level8_core.collision_mask = 2
	_level8_core.monitoring = true
	var core_shape := CollisionShape2D.new()
	var core_circle := CircleShape2D.new()
	core_circle.radius = 16.0
	core_shape.shape = core_circle
	_level8_core.add_child(core_shape)
	_level8_core.body_entered.connect(_on_level8_core_body_entered)
	add_child(_level8_core)


func _process_level8_boss(delta: float) -> void:
	var cpu := get_parent().get_node_or_null("CPUPaddle") as Node2D
	if cpu and is_instance_valid(_level8_core):
		_level8_core.position.x = cpu.position.x
	if is_instance_valid(_level8_attack_ball):
		return
	_level8_core_exposed = false
	_level8_attack_cooldown -= delta
	if _level8_attack_cooldown <= 0.0:
		_launch_level8_attack()


func _launch_level8_attack() -> void:
	var cpu := get_parent().get_node_or_null("CPUPaddle") as Node2D
	if cpu == null:
		return
	var attack := CharacterBody2D.new()
	attack.name = "BossAttackBall"
	attack.set_script(BOSS_ATTACK_BALL_SCRIPT)
	attack.position = Vector2(cpu.position.x, 84.0)
	attack.collision_layer = 2
	attack.collision_mask = 4
	var attack_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	attack_shape.shape = circle
	attack.add_child(attack_shape)
	attack.set("_director", self)
	_level8_attack_ball = attack
	_level8_core_exposed = true
	_level8_attack_cooldown = 99.0
	add_child(attack)
	_set_notice("RED ATTACK // RETURN TO EXPOSED CORE", 2.0)
	queue_redraw()


func _on_level8_core_body_entered(body: Node2D) -> void:
	if not _level8_core_exposed or not body.is_in_group("level8_boss_attack") or not bool(body.get("returned")):
		return
	if body != _level8_attack_ball:
		return
	_resolve_level8_attack(body, true)


func on_boss_attack_missed(ball: Node) -> void:
	if ball != _level8_attack_ball:
		return
	_resolve_level8_attack(ball, false)
	var main_ball := get_parent().get_node_or_null("Ball")
	if main_ball:
		main_ball.set("is_stopped", true)
	get_parent().player_scored(2)


func on_boss_attack_expired(ball: Node) -> void:
	if ball == _level8_attack_ball:
		_resolve_level8_attack(ball, false)


func _resolve_level8_attack(ball: Node, hit_core: bool) -> void:
	_level8_attack_ball = null
	_level8_core_exposed = false
	_level8_attack_cooldown = 2.6
	if is_instance_valid(ball):
		ball.queue_free()
	if hit_core:
		var main_ball := get_parent().get_node_or_null("Ball")
		if main_ball:
			main_ball.set("is_stopped", true)
		get_parent().player_scored(1)
	queue_redraw()

func _create_level7_scoring_bumpers() -> void:
	var total_width := LEVEL_7_BUMPER_GAP * float(LEVEL_7_BUMPER_SIZES.size() - 1)
	for size in LEVEL_7_BUMPER_SIZES:
		total_width += size.x
	_level7_bumper_rects.clear()
	_level7_bumper_active.clear()
	for _index in range(LEVEL_7_BUMPER_SIZES.size()):
		_level7_bumper_rects.append(Rect2())
		_level7_bumper_active.append(true)
	var bumper_order: Array[int] = [0, 1, 2, 3, 4]
	bumper_order.shuffle()
	var cursor_x := randf_range(8.0, 360.0 - total_width - 8.0)
	for index in bumper_order:
		var size: Vector2 = LEVEL_7_BUMPER_SIZES[index]
		var min_center_y := 8.0 + size.y * 0.5
		var max_center_y := 44.5 - size.y * 0.5
		var center_y := randf_range(min_center_y, max_center_y)
		var rect := Rect2(Vector2(cursor_x, center_y - size.y * 0.5), size)
		_level7_bumper_rects[index] = rect
		var bumper := StaticBody2D.new()
		bumper.name = "Level7ScoringBumper_%d" % index
		bumper.position = rect.get_center()
		bumper.collision_layer = 1
		bumper.collision_mask = 1
		bumper.add_to_group("level7_scoring_bumper")
		bumper.set_meta("target_index", index)
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = size
		collision.shape = shape
		bumper.add_child(collision)
		add_child(bumper)
		cursor_x += size.x + LEVEL_7_BUMPER_GAP
	_level7_respawn_left = 0.0
	queue_redraw()

func hit_level7_bumper(bumper: Node) -> bool:
	if level_id != 7 or not is_instance_valid(bumper) or not bumper.has_meta("target_index"):
		return false
	var index := int(bumper.get_meta("target_index"))
	if index < 0 or index >= _level7_bumper_active.size() or not _level7_bumper_active[index]:
		return false
	_level7_bumper_active[index] = false
	bumper.queue_free()
	var any_remaining := false
	for active in _level7_bumper_active:
		any_remaining = any_remaining or active
	if not any_remaining and get_parent().player1_score + 1 < GameState.points_to_win:
		_level7_respawn_left = 1.1
	queue_redraw()
	return true
func _bits(value: int) -> int: return int(value&1!=0)+int(value&2!=0)
func reset_round() -> void:
	elapsed=0; reverse_warning=0; reverse_left=0; _gravity_charge=false
	_rally_flip=false; _previous_gate_y.clear(); _portal_flash_left=0
func _draw() -> void:
	if level_id==5:
		draw_circle(Vector2(_well_x,360),190,Color(0.95,0.18,0.04,0.045)); draw_arc(Vector2(_well_x,360),190,0,TAU,64,Color(1,0.36,0.12,0.42),2,true); draw_arc(Vector2(_well_x,360),92,0,TAU,48,Color(1,0.67,0.24,0.62),2,true); draw_arc(Vector2(_well_x,360),42,0,TAU,36,Color(1,0.22,0.08,0.9),2.5,true)
	if level_id==7:
		var pulse := 0.72 + 0.18 * sin(elapsed * 4.0)
		var neon_colors: Array[Color] = [Color(0.08, 0.9, 1.0), Color(0.22, 0.55, 1.0), Color(0.68, 0.3, 1.0), Color(1.0, 0.3, 0.72), Color(0.48, 1.0, 0.82)]
		for index in range(_level7_bumper_rects.size()):
			if not _level7_bumper_active[index]:
				continue
			var rect: Rect2 = _level7_bumper_rects[index]
			var tint: Color = neon_colors[index]
			draw_rect(rect, Color(tint.r, tint.g, tint.b, 0.22), true)
			draw_rect(rect, Color(tint.r, tint.g, tint.b, pulse), false, 2.0, true)
			if rect.size.x > 26.0:
				draw_line(Vector2(rect.position.x + 5.0, rect.get_center().y), Vector2(rect.end.x - 5.0, rect.get_center().y), Color(0.9, 0.98, 1.0, pulse), 1.0, true)
	if level_id == 8 and is_instance_valid(_level8_core):
		var core_center := _level8_core.position
		if _level8_core_exposed:
			draw_circle(core_center, 22.0, Color(1.0, 0.08, 0.04, 0.16))
			draw_arc(core_center, 20.0 + 2.0 * sin(elapsed * 8.0), 0.0, TAU, 48, Color(1.0, 0.24, 0.08, 0.95), 3.0, true)
			draw_circle(core_center, 10.0, Color(1.0, 0.52, 0.16, 0.85))
			draw_circle(core_center, 4.0, Color(1.0, 0.94, 0.68, 1.0))
		else:
			draw_circle(core_center, 19.0, Color(0.14, 0.22, 0.38, 0.62))
			draw_arc(core_center, 18.0, 0.0, TAU, 48, Color(0.25, 0.72, 1.0, 0.7), 2.5, true)
			draw_line(core_center + Vector2(-8.0, 0.0), core_center + Vector2(8.0, 0.0), Color(0.54, 0.76, 0.9, 0.8), 2.0, true)
	if level_id==9:
		for i in range(2):
			var center := _portal_positions[i]
			var phase := elapsed * (1.1 if i == 0 else -0.9)
			var pulse := 27.0 + 2.5 * sin(elapsed * 4.0 + float(i))
			var tint := Color(0.08, 0.9, 1.0, 0.84) if i == 0 else Color(0.76, 0.22, 1.0, 0.84)
			draw_circle(center, 20.0, Color(tint.r, tint.g, tint.b, 0.16))
			draw_arc(center, pulse, phase, phase + TAU * 0.72, 48, tint, 3.0, true)
			draw_arc(center, 17.0, -phase, -phase + TAU * 0.48, 36, tint.lightened(0.35), 1.4, true)
		if _portal_flash_left > 0.0:
			var progress := 1.0 - _portal_flash_left / 0.36
			draw_arc(_portal_flash_position, 24.0 + progress * 36.0, 0.0, TAU, 48, Color(0.46, 0.82, 1.0, 1.0 - progress), 2.5, true)
