extends Control

@onready var start_button := $VBox/StartButton as Button
@onready var options_button := $VBox/OptionsButton as Button
@onready var quit_button := $VBox/QuitButton as Button
@onready var options_screen := $OptionsScreen
@onready var bgm_music := $BgmMusic as AudioStreamPlayer

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	options_screen.back_requested.connect(_on_options_back)

	options_screen.visible = false
	_setup_buttons()

	# Inicia a música de fundo
	bgm_music.play()

func _setup_buttons() -> void:
	# Configura o pivot no centro de cada botão para animação de escala
	for btn in [start_button, options_button, quit_button]:
		btn.pivot_offset = btn.size / 2
		btn.scale = Vector2(0.9, 0.9)
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))

func _on_button_hover(btn: Button, is_hovered: bool) -> void:
	var target_scale = Vector2(1.1, 1.1) if is_hovered else Vector2(0.9, 0.9)
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Asssets/Scenes/Areas/area_1.tscn")

func _on_options_pressed() -> void:
	options_screen.visible = true

func _on_options_back() -> void:
	options_screen.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
