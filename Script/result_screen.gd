extends CanvasLayer

signal back_requested

@export var menu_path: String = "res://Asssets/Scenes/title_screen.tscn"

var elapsed_time: float = 0.0
var ranking: String = "F"
var phase_name: String = ""
var collect_count: int = 0
var total_collects: int = 0

var panel: PanelContainer
var ranking_label: Label
var time_label: Label
var phase_label: Label
var collect_label: Label
var continue_button: Button

var _is_initializing: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Busca os nós com segurança
	panel = $Panel as PanelContainer
	ranking_label = $Panel/VBox/RankingLabel as Label
	time_label = $Panel/VBox/TimeLabel as Label
	phase_label = $Panel/VBox/PhaseLabel as Label
	collect_label = $Panel/VBox/CollectLabel as Label
	continue_button = $Panel/VBox/ContinueButton as Button

	_update_display()

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		# Garante que o botão possa ser clicado mesmo com o jogo pausado
		continue_button.process_mode = Node.PROCESS_MODE_ALWAYS

	# Previne múltiplas instanciações
	if _is_initializing:
		queue_free()
		return
	_is_initializing = true

	get_tree().paused = true

	# Sonic Mania Style: Slide in animation
	if panel:
		panel.position.x = 1000
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "position:x", 0, 0.5)

func _update_display() -> void:
	if ranking_label:
		ranking_label.text = ranking

	if time_label:
		var mins    = int(elapsed_time) / 60
		var secs    = int(elapsed_time) % 60
		var millis  = int((elapsed_time - floor(elapsed_time)) * 100)
		time_label.text = "%02d:%02d.%02d" % [mins, secs, millis]

	if phase_label:
		if phase_name != "":
			var short = phase_name.get_file()
			phase_label.text = short
			phase_label.visible = true
		else:
			phase_label.visible = false

	if collect_label:
		if total_collects > 0:
			collect_label.text = "COLETÁVEIS: %d / %d" % [collect_count, total_collects]
			collect_label.visible = true
		else:
			collect_label.visible = false

func _on_continue_pressed() -> void:
	_continue_to_menu()

func _input(event: InputEvent) -> void:
	# Captura cliques mesmo com o jogo pausado
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_continue_to_menu()

func _continue_to_menu() -> void:
	if continue_button:
		continue_button.disabled = true

	# Despausa o jogo antes de trocar de cena
	get_tree().paused = false

	# Pequeno delay para garantir que o pause foi processado
	await get_tree().process_frame

	# Remove a tela de resultado antes de trocar de cena
	queue_free()

	# Troca para a tela de título
	get_tree().change_scene_to_file(menu_path)