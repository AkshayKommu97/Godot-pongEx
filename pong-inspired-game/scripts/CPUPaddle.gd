extends CharacterBody2D

@export var speed = 300.0
@export var follow_distance = 10.0
@export var smoothness = 8.0  # Higher = smoother but slower reaction
@export var edge_safety_margin = 15.0  # How far paddle stays from wall to avoid trapping ball

func _physics_process(delta):
	var ball = get_node_or_null("../Ball")
	if ball:
		# Smoothly move toward the ball's X position
		var target_x = ball.position.x
		position.x = lerp(position.x, target_x, smoothness * delta)
		
		# ✅ Avoid hugging the wall when the ball is near paddle edges
		if (position.x < edge_safety_margin and ball.position.x < position.x) or \
		   (position.x > get_viewport_rect().size.x - edge_safety_margin and ball.position.x > position.x):
			# Pull paddle slightly inward
			position.x = clamp(position.x, edge_safety_margin, get_viewport_rect().size.x - edge_safety_margin)

		# Keep paddle within screen bounds
		position.x = clamp(position.x, 30, get_viewport_rect().size.x - 30)
		
		# Lock Y position
		position.y = 50
