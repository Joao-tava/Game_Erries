extends Control

# Altere para o caminho da sua cena de jogo principal
@export_file("*.tscn") var game_scene_path: String = "res://scenes/main_game.tscn"

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var options_button = $CenterContainer/VBoxContainer/OptionsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	# Conecta os sinais dos botões
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	if game_scene_path == "":
		print("Erro: Caminho da cena principal não configurado!")
		return
	get_tree().change_scene_to_file(game_scene_path)

func _on_options_pressed():
	print("Abrindo menu de opções...")
	# Aqui você pode instanciar sua cena de opções

func _on_quit_pressed():
	get_tree().quit()
