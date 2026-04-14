extends Node2D

## Gerencia o pause menu dentro do level.
## O pause menu é instanciado via script e adicionado como CanvasLayer.

var pause_menu: CanvasLayer
var options_scene: PackedScene
var current_options: Control = null

func _ready() -> void:
	options_scene = preload("res://Asssets/Scenes/options_screen.tscn")

	pause_menu = preload("res://Asssets/Scenes/pause_menu.tscn").instantiate()
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.options_requested.connect(_on_options_from_pause)
	pause_menu.quit_requested.connect(_on_quit_to_menu)
	add_child(pause_menu)
	pause_menu.close()  # começa fechado

func _on_resume() -> void:
	# Apenas notificação — o pause_menu já chamou close() e despausou
	pass

func _on_options_from_pause() -> void:
	# Abre a tela de opções sobre o jogo pausado
	current_options = options_scene.instantiate()
	current_options.back_requested.connect(_on_options_back)
	add_child(current_options)

func _on_options_back() -> void:
	if current_options != null:
		current_options.queue_free()
		current_options = null
	# Restaura o pause menu no estado aberto
	if pause_menu != null:
		pause_menu.restore()

func _on_quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Asssets/Scenes/title_screen.tscn")
