extends Control

@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton

func _ready():
	# Garante que o menu começa escondido
	hide()

	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event):
	# Tecla ESC ou Pause para alternar o menu
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" é o padrão para a tecla ESC
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

	if new_pause_state:
		# Pausa o jogo e mostra o menu
		print("Jogo Pausado")
	else:
		# Retoma o jogo e esconde o menu
		print("Jogo Retomado")

func _on_resume_pressed():
	toggle_pause()

func _on_main_menu_pressed():
	# Despausa o jogo antes de mudar de cena, senão o menu principal ficará pausado
	get_tree().paused = false
	# Altere para o caminho da sua cena de Title Screen
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
