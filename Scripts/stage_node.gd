class_name StageNode
extends Area2D

@export var stage_name:  String        = "HELLO WORLD"
@export var scene_path:  String        = ""
@export var biome:       String        = "floresta"
@export var connections: Array[String] = []

@onready var sprite    = $Sprite2D
@onready var label     = $Label
@onready var lock_icon = $LockIcon

enum State { LOCKED, AVAILABLE, CURRENT, CLEARED }
var current_state: State = State.LOCKED
var base_scale:    float = 1.5

signal button_pressed

func _ready() -> void:
	label.text     = stage_name
	input_pickable = true

	if not has_node("CollisionShape2D"):
		var shape       = CircleShape2D.new()
		shape.radius    = 25
		var collision   = CollisionShape2D.new()
		collision.shape = shape
		collision.name  = "CollisionShape2D"
		add_child(collision)

	# ESSA linha faltava: conecta o sinal input_event ao handler
	input_event.connect(_on_area_input_event)

	set_state(State.LOCKED)

# ── Estado visual ─────────────────────────────────────────────
func set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.LOCKED:
			modulate = Color(0.4, 0.4, 0.4)
			if lock_icon: lock_icon.visible = true
			if sprite:    sprite.modulate   = Color(0.4, 0.4, 0.4)
			_set_scale(base_scale)
		State.AVAILABLE:
			modulate = Color(1, 1, 1)
			if lock_icon: lock_icon.visible = false
			if sprite:    sprite.modulate   = Color(1, 1, 1)
			_set_scale(base_scale)
		State.CURRENT:
			modulate = Color(1.3, 1.3, 1.0)
			if lock_icon: lock_icon.visible = false
			if sprite:    sprite.modulate   = Color(1.3, 1.3, 1.0)
			_set_scale(base_scale * 1.2)
		State.CLEARED:
			modulate = Color(1, 1, 1)
			if lock_icon: lock_icon.visible = false
			if sprite:    sprite.modulate   = Color(1, 1, 1)
			_set_scale(base_scale)
	queue_redraw()

func _set_scale(new_scale: float) -> void:
	if sprite:
		sprite.scale = Vector2(new_scale, new_scale)

# ── Fallback visual ───────────────────────────────────────────
func _draw() -> void:
	if sprite and sprite.texture:
		return
	var color := Color.WHITE
	match current_state:
		State.LOCKED:    color = Color(0.3, 0.3, 0.3)
		State.AVAILABLE: color = Color(0.4, 0.8, 0.4)
		State.CURRENT:   color = Color(1.0, 1.0, 0.4)
		State.CLEARED:   color = Color(0.4, 0.6, 1.0)
	draw_circle(Vector2.ZERO, 20, color)
	draw_circle(Vector2.ZERO, 20, color.lightened(0.2), false, 3)

# ── Input ─────────────────────────────────────────────────────
func _on_area_input_event(_viewport, event: InputEvent, _shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		button_pressed.emit()
