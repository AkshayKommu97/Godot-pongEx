extends CharacterBody2D

@export var speed = 300.0
@export var follow_distance = 10.0
@export var smoothness = 8.0  # Higher = smoother but slower reaction

func _physics_process(delta):
	var ball = get_node_or_null("../Ball")
	if ball:
		# Smoothly move toward the ball's X position
		var target_x = ball.position.x
		position.x = lerp(position.x, target_x, smoothness * delta)
		
		# Keep paddle within screen bounds
		position.x = clamp(position.x, 40, get_viewport_rect().size.x - 40)
		
		# Lock Y position
		position.y = 50
