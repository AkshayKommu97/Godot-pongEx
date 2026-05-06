extends CharacterBody2D

@export var speed = 300.0
@export var follow_distance = 10.0
@export var smoothness = 8.0  # Higher = smoother but slower reaction
@export var edge_safety_margin = 15.0  # How far paddle stays from wall to avoid trapping ball

# Colors for each level (index starts at 1)
var level_colors = [
	Color(0, 0, 1),     # Level 1 - Blue
	Color(0, 1, 0),     # Level 2 - Green
	Color(1, 1, 0),     # Level 3 - Yellow
	Color(1, 0.5, 0),   # Level 4 - Orange
	Color(1, 0, 1),     # Level 5 - Magenta
	Color(0, 1, 1),     # Level 6 - Cyan
	Color(0.5, 0, 1),   # Level 7 - Purple
	Color(0.8, 0.8, 0.8), # Level 8 - Light Gray
	Color(0.4, 0.2, 0.1), # Level 9 - Brown
	Color(1, 1, 1)      # Level 10 - White
]

func _ready():
	# Clamp level in case something's off
	var lvl = clamp(GameState.current_level, 1, level_colors.size())
	$CollisionShape2D/ColorRect.color = level_colors[lvl - 1]

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
		position.y = 20

func get_paddle_type() -> int:
	return GameState.current_level
