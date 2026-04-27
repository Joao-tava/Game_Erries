extends Area2D

signal collected

func _ready() -> void:
	add_to_group("collectibles")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("play_coin_sfx"):
		body.play_coin_sfx()
	collected.emit()
	queue_free()
