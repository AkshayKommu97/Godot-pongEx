extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	visible = false
	rect.material.set_shader_parameter("progress", 0.0)

func transition_to(scene_path: String) -> void:

	visible = true

	anim.play("transition_out")

	await anim.animation_finished

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame

	anim.play("transition_in")

	await anim.animation_finished

	visible = false
