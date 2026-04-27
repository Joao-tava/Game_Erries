extends Control

@onready var start_button := $MenuContainer/VBox/StartButton as Button
@onready var chapters_button := $MenuContainer/VBox/ChaptersButton as Button
@onready var options_button := $MenuContainer/VBox/OptionsButton as Button
@onready var quit_button := $MenuContainer/VBox/QuitButton as Button
@onready var options_screen := $OptionsScreen
@onready var bgm_music := $BgmMusic as AudioStreamPlayer

@onready var cursor_start := $MenuContainer/CursorStart as Label
@onready var cursor_chapters := $MenuContainer/CursorChapters as Label
@onready var cursor_options := $MenuContainer/CursorOptions as Label
@onready var cursor_quit := $MenuContainer/CursorQuit as Label

var buttons := []
var cursors := []

func _ready() -> void:
	buttons = [start_button, chapters_button, options_button, quit_button]
	cursors = [cursor_start, cursor_chapters, cursor_options, cursor_quit]

	start_button.pressed.connect(_on_start_pressed)
	chapters_button.pressed.connect(_on_chapters_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	options_screen.back_requested.connect(_on_options_back)

	options_screen.visible = false
	_setup_buttons()

	# Esconde todos os cursors inicialmente, mostra apenas o primeiro
	_update_cursor_visibility(0)

	# Inicia a música de fundo
	bgm_music.play()

func _setup_buttons() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.pivot_offset = btn.size / 2
		btn.scale = Vector2(0.95, 0.95)
		btn.mouse_entered.connect(_on_button_hover.bind(i, true))
		btn.mouse_exited.connect(_on_button_hover.bind(i, false))
		btn.focus_entered.connect(_on_button_focus.bind(i))

func _on_button_hover(index: int, is_hovered: bool) -> void:
	var btn = buttons[index]
	var target_scale = Vector2(1.05, 1.05) if is_hovered else Vector2(0.95, 0.95)
	var target_color = Color(0.85, 0.2, 0.2, 1) if is_hovered else Color(1, 1, 1, 1)

	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.2)
	tween.parallel().tween_property(btn, "modulate", target_color, 0.2)

	if is_hovered:
		_update_cursor_visibility(index)

func _on_button_focus(index: int) -> void:
	_update_cursor_visibility(index)

func _update_cursor_visibility(active_index: int) -> void:
	for i in range(cursors.size()):
		cursors[i].visible = (i == active_index)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Asssets/Scenes/world_map.tscn")

func _on_chapters_pressed() -> void:
	# Implementar tela de seleção de capítulos
	pass

func _on_options_pressed() -> void:
	options_screen.visible = true

func _on_options_back() -> void:
	options_screen.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
