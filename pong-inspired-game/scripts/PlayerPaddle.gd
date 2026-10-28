extends CharacterBody2D

@export var speed = 400.0
@export var ball_speed_increase = 30.0
@export var max_ball_speed = 800.0

var _mouse_control_active := false
var _mouse_target_x := 180.0


func _ready() -> void:
	$CollisionShape2D/ColorRect.color = Color(1, 0, 0)  # pure red


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_target_x = get_global_mouse_position().x
		_mouse_control_active = true
	elif event is InputEventKey and event.pressed:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_mouse_control_active = false


func _physics_process(delta: float) -> void:
	var reverse_input := false
	if GameState.current_level == 6 or GameState.current_level == 10:
		var director: Node = get_parent().get_node_or_null("ChallengeDirector")
		if director and director.has_method("is_control_reversed"):
			reverse_input = director.is_control_reversed()

	var keyboard_dir = Input.get_axis(
		"ui_left",
		"ui_right"
	)
	if reverse_input:
		keyboard_dir *= -1.0

	if keyboard_dir != 0:
		global_position.x += keyboard_dir * speed * delta
	elif _mouse_control_active:
		global_position.x = move_toward(
			global_position.x,
			get_viewport_rect().size.x - _mouse_target_x if reverse_input else _mouse_target_x,
			1200.0 * delta
		)

	global_position.x = clamp(
		global_position.x,
		40,
		get_viewport_rect().size.x - 40
	)

	global_position.y = 700
