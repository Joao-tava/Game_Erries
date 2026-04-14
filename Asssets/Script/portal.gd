extends Area2D

@export var menu_path: String = "res://Asssets/Scenes/title_screen.tscn"

@onready var anim := $AnimatedSprite2D as AnimatedSprite2D

var _triggered: bool = false

func _ready() -> void:
	if anim:
		anim.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return

	# Detecta pelo grupo OU pelo tipo CharacterBody2D
	if not body.is_in_group("player") and not body is CharacterBody2D:
		return

	_triggered = true

	if anim:
		anim.play("idle")
		var frames   := anim.sprite_frames.get_frame_count("idle")
		var fps      := anim.sprite_frames.get_animation_speed("idle")
		var duration := frames / fps
		await get_tree().create_timer(duration).timeout

	get_tree().change_scene_to_file(menu_path)
