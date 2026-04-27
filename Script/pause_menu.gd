extends CanvasLayer

signal resume_requested
signal options_requested
signal quit_requested

@onready var panel          := $Panel                    as Control
@onready var resume_button  := $Panel/VBox/ResumeButton  as Button
@onready var options_button := $Panel/VBox/OptionsButton as Button
@onready var quit_button    := $Panel/VBox/QuitButton    as Button
@onready var cursor_resume  := $Panel/CursorResume       as Label
@onready var cursor_options := $Panel/CursorOptions      as Label
@onready var cursor_quit    := $Panel/CursorQuit         as Label
@onready var options_screen := $OptionsScreen            as Control

var buttons  := []
var cursors  := []
var _is_closing := false
var _is_opening := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible          = false
	options_screen.visible = false

	buttons = [resume_button, options_button, quit_button]
	cursors = [cursor_resume, cursor_options, cursor_quit]

	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if options_screen.has_signal("back_requested"):
		options_screen.back_requested.connect(_on_options_back)

	_setup_buttons()
	_update_cursor_visibility(0)

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
	var target_color  = Color(0.85, 0.2, 0.2, 1) if is_hovered else Color(1, 1, 1, 1)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if options_screen.visible:
			_on_options_back()
		elif not _is_closing and not _is_opening:
			if panel.visible:
				_on_resume_pressed()
			else:
				restore()

func toggle_pause(paused: bool) -> void:
	if paused:
		_is_closing = false
		_is_opening = true
		panel.visible = paused
		get_tree().paused = true
		panel.pivot_offset = panel.size / 2
		panel.scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.4)
		await tween.finished
		_is_opening = false
		_update_cursor_visibility(0)
	else:
		_is_closing = true
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "scale", Vector2.ZERO, 0.2)
		await tween.finished
		panel.visible = false
		_is_closing = false

func _on_resume_pressed() -> void:
	if _is_closing:
		return
	resume_requested.emit()
	toggle_pause(false)

func _on_options_pressed() -> void:
	panel.visible = false
	options_screen.visible = true
	options_requested.emit()

func _on_options_back() -> void:
	if not options_screen.visible:
		return
	options_screen.visible = false
	panel.visible = true
	_update_cursor_visibility(0)

func _on_quit_pressed() -> void:
	quit_requested.emit()
	toggle_pause(false)
	get_tree().change_scene_to_file("res://Asssets/Scenes/title_screen.tscn")

func close() -> void:
	if panel.visible:
		toggle_pause(false)

func restore() -> void:
	if not panel.visible and not _is_closing and not _is_opening:
		toggle_pause(true)
