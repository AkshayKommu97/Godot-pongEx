extends CharacterBody2D

@export var speed: float = 300.0
@export var follow_distance: float = 10.0
@export var smoothness: float = 8.0
@export var edge_safety_margin: float = 15.0


func _ready() -> void:
	var level: int = clampi(GameState.current_level, 1, GameState.LEVEL_COUNT)
	$CollisionShape2D/ColorRect.color = GameState.get_cpu_color(level)


func _physics_process(delta: float) -> void:
	var ball := get_node_or_null("../Ball") as Node2D
	if ball:
		var target_x: float = ball.position.x
		position.x = lerpf(position.x, target_x, smoothness * delta)

		if (position.x < edge_safety_margin and ball.position.x < position.x) or \
			(position.x > get_viewport_rect().size.x - edge_safety_margin and ball.position.x > position.x):
			position.x = clampf(position.x, edge_safety_margin, get_viewport_rect().size.x - edge_safety_margin)

		position.x = clampf(position.x, 30.0, get_viewport_rect().size.x - 30.0)
		position.y = 20.0


func get_paddle_type() -> int:
	return GameState.current_level
