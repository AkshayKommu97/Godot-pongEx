extends CharacterBody2D

@export var speed: float = 300.0
@export var follow_distance: float = 10.0
@export var smoothness: float = 8.0
@export var edge_safety_margin: float = 15.0

var _yellow_shape: RectangleShape2D
var _yellow_visual: ColorRect
var _yellow_standard_width := 79.5
var _yellow_full_width := 0.0
var _yellow_width := 79.5
var _yellow_tween: Tween
var _yellow_regrow_timer: Timer

var yellow_width: float:
	get:
		return _yellow_width
	set(value):
		_yellow_width = value
		if is_instance_valid(_yellow_shape):
			_yellow_shape.size.x = value
		if is_instance_valid(_yellow_visual):
			_yellow_visual.offset_left = -value * 0.5
			_yellow_visual.offset_right = value * 0.5


func _ready() -> void:
	var level: int = clampi(GameState.current_level, 1, GameState.LEVEL_COUNT)
	$CollisionShape2D/ColorRect.color = GameState.get_cpu_color(level)
	if level == 3:
		_setup_yellow_paddle()


func _setup_yellow_paddle() -> void:
	var collision := $CollisionShape2D as CollisionShape2D
	var source_shape := collision.shape as RectangleShape2D
	if source_shape == null:
		push_error("Level 3 CPU paddle requires a RectangleShape2D")
		return
	# Level scenes share this resource with the player paddle; isolate the CPU copy.
	_yellow_shape = source_shape.duplicate() as RectangleShape2D
	collision.shape = _yellow_shape
	_yellow_standard_width = _yellow_shape.size.x
	_yellow_visual = $CollisionShape2D/ColorRect as ColorRect
	_yellow_full_width = maxf(_yellow_standard_width, get_viewport_rect().size.x - edge_safety_margin * 2.0)
	yellow_width = _yellow_full_width
	_yellow_regrow_timer = Timer.new()
	_yellow_regrow_timer.one_shot = true
	_yellow_regrow_timer.wait_time = 3.0
	_yellow_regrow_timer.timeout.connect(_on_yellow_regrow_timeout)
	add_child(_yellow_regrow_timer)


func trigger_yellow_shrink() -> void:
	if GameState.current_level != 3 or not is_instance_valid(_yellow_shape):
		return
	if _yellow_tween and _yellow_tween.is_running():
		_yellow_tween.kill()
	_yellow_regrow_timer.stop()
	_yellow_tween = create_tween()
	_yellow_tween.tween_property(self, "yellow_width", _yellow_standard_width, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_yellow_tween.tween_callback(_start_yellow_regrow_timer)


func _start_yellow_regrow_timer() -> void:
	if is_instance_valid(_yellow_regrow_timer):
		_yellow_regrow_timer.start(3.0)


func _on_yellow_regrow_timeout() -> void:
	if GameState.current_level != 3 or not is_instance_valid(_yellow_shape):
		return
	if _yellow_tween and _yellow_tween.is_running():
		_yellow_tween.kill()
	_yellow_tween = create_tween()
	_yellow_tween.tween_property(self, "yellow_width", _yellow_full_width, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	var ball := get_node_or_null("../Ball") as Node2D
	if ball:
		var target_x: float = ball.position.x
		var tracking := smoothness
		var director: Node = get_parent().get_node_or_null("ChallengeDirector")
		if director:
			if director.has_method("cpu_target_x"):
				target_x = director.cpu_target_x(ball)
			if director.has_method("cpu_smoothness"):
				tracking = director.cpu_smoothness()
		position.x = lerpf(position.x, target_x, tracking * delta)

		if (position.x < edge_safety_margin and ball.position.x < position.x) or \
			(position.x > get_viewport_rect().size.x - edge_safety_margin and ball.position.x > position.x):
			position.x = clampf(position.x, edge_safety_margin, get_viewport_rect().size.x - edge_safety_margin)

		var half_width := _yellow_width * 0.5 if GameState.current_level == 3 else 30.0
		position.x = clampf(position.x, half_width, get_viewport_rect().size.x - half_width)
		position.y = 62.0 if GameState.current_level == 7 else 20.0


func get_paddle_type() -> int:
	return GameState.current_level
