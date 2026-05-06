extends Area2D

@export var bounce_strength: float = 1.5
@onready var glow: PointLight2D = $PointLight2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	#print("Bumper ready at:", position)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	#print("Something hit bumper:", body.name)

	if body.is_in_group("ball"):
		#print("✅ Ball hit bumper!")
		var ball = body

		# Bounce away from bumper
		ball.direction = (ball.position - global_position).normalized()
		ball.speed *= bounce_strength

		# Flash glow
		if anim.has_animation("Glow"):
			anim.play("Glow")
