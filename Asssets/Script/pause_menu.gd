extends CanvasLayer

signal resume_requested
signal options_requested
signal quit_requested

@onready var panel := $Panel as Control
@onready var resume_button := $Panel/VBox/ResumeButton as Button
@onready var options_button := $Panel/VBox/OptionsButton as Button
@onready var quit_button := $Panel/VBox/QuitButton as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_setup_buttons()

func _setup_buttons() -> void:
	for btn in [resume_button, options_button, quit_button]:
		btn.pivot_offset = btn.size / 2
		btn.scale = Vector2(0.9, 0.9)
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))

func _on_button_hover(btn: Button, is_hovered: bool) -> void:
	var target_scale = Vector2(1.1, 1.1) if is_hovered else Vector2(0.9, 0.9)
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if panel.visible:
			_on_resume_pressed()
		else:
			toggle_pause(true)

func toggle_pause(paused: bool) -> void:
	panel.visible = paused
	get_tree().paused = paused

	if paused:
		panel.pivot_offset = panel.size / 2
		panel.scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.4)
	else:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "scale", Vector2.ZERO, 0.2)
		await tween.finished
		panel.visible = false

func _on_resume_pressed() -> void:
	resume_requested.emit()
	toggle_pause(false)

func _on_options_pressed() -> void:
	options_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

func close() -> void:
	if panel.visible:
		toggle_pause(false)

func restore() -> void:
	if not panel.visible:
		toggle_pause(true)
