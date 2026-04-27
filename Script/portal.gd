extends Area2D

@export var menu_path: String = "res://Asssets/Scenes/title_screen.tscn"
@export var result_scene: String = "res://Asssets/Scenes/result_screen.tscn"

@onready var anim := $AnimatedSprite2D as AnimatedSprite2D

var _triggered: bool = false

func _ready() -> void:
	if anim:
		anim.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return

	if not (body.is_in_group("player") or body is CharacterBody2D):
		return

	_triggered = true

	if anim:
		anim.play("idle")
		var frames   := anim.sprite_frames.get_frame_count("idle")
		var fps      := anim.sprite_frames.get_animation_speed("idle")
		var duration := frames / fps
		await get_tree().create_timer(duration).timeout

	_show_ranking_result()

func _show_ranking_result() -> void:
	# Pause o jogo ANTES de instanciar a tela de resultado
	get_tree().paused = true

	var game_manager = get_tree().get_first_node_in_group("game_manager")

	var elapsed: float = 0.0
	var rank: String = "F"
	var phase: String = ""
	var collect_count: int = 0
	var total_collects: int = 0

	if game_manager:
		elapsed = game_manager.elapsed_time
		rank = game_manager.get_ranking()
		if get_tree().current_scene and "scene_file_path" in get_tree().current_scene:
			phase = get_tree().current_scene.scene_file_path
		collect_count = game_manager.collect_count if "collect_count" in game_manager else 0
		total_collects = game_manager.total_collects if "total_collects" in game_manager else 0

	var result_scene_res = load(result_scene)
	if result_scene_res:
		var instance = result_scene_res.instantiate()
		instance.elapsed_time = elapsed
		instance.ranking = rank
		instance.phase_name = phase
		instance.collect_count = collect_count
		instance.total_collects = total_collects
		get_tree().root.add_child(instance)
