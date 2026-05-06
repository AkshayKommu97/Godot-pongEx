extends ColorRect

@export var player_color: Color = Color(1, 0, 0)     # Red
@export var enemy_color: Color = Color(0, 0, 1)      # Blue default
@export var max_score: int = 10

func _ready():
	update_gradient(0, 0)

func update_gradient(player_score: int, enemy_score: int):
	var player_fill := float(player_score) / max_score
	var enemy_fill := float(enemy_score) / max_score

	var grad := Gradient.new()

	# Colors from top → bottom
	var colors := [
		enemy_color,                                      # Top
		enemy_color.lerp(Color.BLACK, enemy_fill),        # CPU fill zone
		player_color.lerp(Color.BLACK, player_fill),      # Player fill zone
		player_color                                       # Bottom
	]

	# Offset positions of the gradient points
	var offsets := [
		0.0,
		0.5 - enemy_fill * 0.5,
		0.5 + player_fill * 0.5,
		1.0
	]

	grad.colors = colors
	grad.offsets = offsets

	var tex := GradientTexture2D.new()
	tex.gradient = grad
	self.texture = tex
