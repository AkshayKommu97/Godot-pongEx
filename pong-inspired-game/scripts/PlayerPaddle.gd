extends CharacterBody2D

@export var speed = 400.0
@export var ball_speed_increase = 30.0
@export var max_ball_speed = 800.0



func _ready():
	$CollisionShape2D/ColorRect.color = Color(1, 0, 0)  # pure red



func _physics_process(delta):

	var keyboard_dir = Input.get_axis(
		"ui_left",
		"ui_right"
	)

	if keyboard_dir != 0:
		global_position.x += keyboard_dir * 400.0 * delta
	else:
		global_position.x = move_toward(
			global_position.x,
			get_global_mouse_position().x,
			1200.0 * delta
		)

	global_position.x = clamp(
		global_position.x,
		40,
		get_viewport_rect().size.x - 40
	)

	global_position.y = 700
