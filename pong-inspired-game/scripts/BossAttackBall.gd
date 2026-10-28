extends CharacterBody2D

const BALL_RADIUS := 9.0
const BALL_SPEED := 360.0
const MAX_LIFETIME := 9.0

var direction := Vector2.DOWN
var returned := false
var _lifetime := MAX_LIFETIME
var _director: Node


func _ready() -> void:
	add_to_group("level8_boss_attack")


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		if is_instance_valid(_director) and _director.has_method("on_boss_attack_expired"):
			_director.on_boss_attack_expired(self)
		return

	var collision := move_and_collide(direction * BALL_SPEED * delta)
	if collision:
		var collider := collision.get_collider()
		if collider is Node2D and collider.name == "PlayerPaddle" and not returned:
			returned = true
			var paddle_half_width := 40.0
			var offset := clampf((global_position.x - collider.global_position.x) / paddle_half_width, -1.0, 1.0)
			direction = Vector2(offset * 0.95, -1.0).normalized()
			global_position += direction * 2.0
			queue_redraw()
		else:
			direction = direction.bounce(collision.get_normal()).normalized()
			global_position += direction * 1.5

	var viewport_size := get_viewport_rect().size
	if global_position.x < BALL_RADIUS:
		global_position.x = BALL_RADIUS
		direction.x = absf(direction.x)
	elif global_position.x > viewport_size.x - BALL_RADIUS:
		global_position.x = viewport_size.x - BALL_RADIUS
		direction.x = -absf(direction.x)

	if global_position.y > viewport_size.y + BALL_RADIUS:
		if is_instance_valid(_director) and _director.has_method("on_boss_attack_missed"):
			_director.on_boss_attack_missed(self)
	elif global_position.y < -BALL_RADIUS:
		if is_instance_valid(_director) and _director.has_method("on_boss_attack_expired"):
			_director.on_boss_attack_expired(self)


func _draw() -> void:
	var core_color := Color(1.0, 0.08, 0.12, 1.0) if not returned else Color(1.0, 0.48, 0.12, 1.0)
	draw_circle(Vector2.ZERO, BALL_RADIUS + 4.0, Color(core_color.r, core_color.g * 0.15, core_color.b * 0.15, 0.28))
	draw_circle(Vector2.ZERO, BALL_RADIUS, core_color)
	draw_circle(Vector2(-2.5, -2.5), 2.4, Color(1.0, 0.9, 0.82, 0.95))
	draw_arc(Vector2.ZERO, BALL_RADIUS + 2.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.52, 0.9), 1.5, true)
