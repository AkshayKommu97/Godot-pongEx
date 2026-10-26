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
		if anim.has_animation("Glow") and FeedbackAudio.visual_intensity > 0.01:
			anim.play("Glow")
		FeedbackAudio.play_bumper()
		var game := get_tree().current_scene
		if game and FeedbackAudio.visual_intensity > 0.01 and game.has_method("play_collision_feedback"):
			game.play_collision_feedback(ball.global_position, (ball.global_position - global_position).normalized(), ball.speed, ball.max_speed, Color(0.0, 1.0, 0.55, 1.0))
		if game and game.has_method("trigger_camera_shake"):
			game.trigger_camera_shake(2.4, 0.1)
