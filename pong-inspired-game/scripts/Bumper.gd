extends Area2D

const IMPACT_SPARK_TEXTURE: Texture2D = preload("res://assets/effects/bumper_spark.svg")

@export var bounce_strength: float = 1.5
@onready var glow: PointLight2D = $PointLight2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var core: Panel = $Core

var _outer_ring: Line2D
var _inner_ring: Line2D
var _spark_burst: CPUParticles2D
var _hit_tween: Tween
var _core_rest_scale := Vector2.ONE

func _ready() -> void:
	#print("Bumper ready at:", position)
	body_entered.connect(_on_body_entered)
	_core_rest_scale = core.scale
	_outer_ring = _make_ring(22.0, 2.4, Color(0.12, 1.0, 0.9, 0.92))
	_inner_ring = _make_ring(17.6, 1.2, Color(0.3, 0.93, 1.0, 0.68))
	_create_spark_burst()

func _on_body_entered(body: Node) -> void:
	#print("Something hit bumper:", body.name)

	if body.is_in_group("ball"):
		var ball = body

		# Bounce away from bumper
		ball.direction = (ball.position - global_position).normalized()
		ball.speed *= bounce_strength
		_play_hit_pulse(ball.speed)

		# Flash glow
		if anim.has_animation("Glow") and FeedbackAudio.visual_intensity > 0.01:
			anim.play("Glow")
		FeedbackAudio.play_bumper()
		var game := get_tree().current_scene
		if game and game.has_method("trigger_camera_shake"):
			game.trigger_camera_shake(2.4, 0.1)

func _make_ring(radius: float, line_width: float, tint: Color) -> Line2D:
	var ring := Line2D.new()
	ring.name = "NeonRing"
	ring.width = line_width
	ring.default_color = tint
	ring.closed = true
	ring.antialiased = true
	for i in range(49):
		var angle := TAU * float(i) / 48.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
	add_child(ring)
	return ring


func _create_spark_burst() -> void:
	_spark_burst = CPUParticles2D.new()
	_spark_burst.name = "ImpactSparks"
	_spark_burst.one_shot = true
	_spark_burst.emitting = false
	_spark_burst.amount = 10
	_spark_burst.lifetime = 0.17
	_spark_burst.explosiveness = 1.0
	_spark_burst.direction = Vector2.UP
	_spark_burst.spread = 180.0
	_spark_burst.initial_velocity_min = 150.0
	_spark_burst.initial_velocity_max = 300.0
	_spark_burst.angular_velocity_min = -900.0
	_spark_burst.angular_velocity_max = 900.0
	_spark_burst.gravity = Vector2(0, 12)
	_spark_burst.damping_min = 0.0
	_spark_burst.damping_max = 12.0
	_spark_burst.scale_amount_min = 0.65
	_spark_burst.scale_amount_max = 1.0
	_spark_burst.color = Color(0.62, 1.0, 0.96, 1.0)
	_spark_burst.texture = IMPACT_SPARK_TEXTURE
	_spark_burst.z_index = 2
	add_child(_spark_burst)


func _play_hit_pulse(hit_speed: float) -> void:
	if FeedbackAudio.visual_intensity <= 0.01:
		return
	var intensity := clampf(hit_speed / 1000.0, 0.35, 1.0)
	_spark_burst.initial_velocity_min = lerpf(130.0, 180.0, intensity)
	_spark_burst.initial_velocity_max = lerpf(240.0, 340.0, intensity)
	_spark_burst.restart()
	_spark_burst.emitting = true
	if _hit_tween and _hit_tween.is_running():
		_hit_tween.kill()
	core.scale = _core_rest_scale
	_outer_ring.scale = Vector2.ONE
	_inner_ring.scale = Vector2.ONE
	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(core, "scale", _core_rest_scale * 1.32, 0.055).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(_outer_ring, "scale", Vector2.ONE * 1.22, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(_inner_ring, "scale", Vector2.ONE * 0.82, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(glow, "energy", 2.2, 0.045)
	_hit_tween.chain().tween_property(core, "scale", _core_rest_scale, 0.17).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(glow, "energy", 0.8, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(_outer_ring, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(_inner_ring, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
