extends Node2D

var pause_menu: CanvasLayer
var options_scene: PackedScene
var current_options: Control = null
var _game_manager: Node = null

func _ready() -> void:
	options_scene = preload("res://Asssets/Scenes/options_screen.tscn")

	# Só cria uma vez — usa grupo como sentinel
	if get_tree().get_first_node_in_group("game_manager") == null:
		_game_manager = preload("res://Asssets/Script/game_manager.gd").new()
		_game_manager.name = "GameManager"
		_game_manager.add_to_group("game_manager")
		add_child(_game_manager)

	# Pause menu: verifica se já existe antes de criar
	if get_tree().get_first_node_in_group("pause_menu_root") == null:
		pause_menu = preload("res://Asssets/Scenes/pause_menu.tscn").instantiate()
		pause_menu.add_to_group("pause_menu_root")
		pause_menu.resume_requested.connect(_on_resume)
		pause_menu.options_requested.connect(_on_options_from_pause)
		pause_menu.quit_requested.connect(_on_quit_to_menu)
		add_child(pause_menu)
		pause_menu.close()
	else:
		pause_menu = get_tree().get_first_node_in_group("pause_menu_root")

func _on_resume() -> void:
	pass

func _on_options_from_pause() -> void:
	current_options = options_scene.instantiate()
	current_options.back_requested.connect(_on_options_back)
	add_child(current_options)

func _on_options_back() -> void:
	if current_options != null:
		current_options.queue_free()
		current_options = null
	if pause_menu != null:
		pause_menu.restore()

func _on_quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Asssets/Scenes/title_screen.tscn")
