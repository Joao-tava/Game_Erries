extends Control

signal back_requested

@onready var volume_slider := $Panel/VBox/VolumeRow/VolumeSlider as HSlider
@onready var volume_label  := $Panel/VBox/VolumeRow/VolLabel     as Label
@onready var res_option    := $Panel/VBox/ResRow/ResOption        as OptionButton
@onready var back_button    := $Panel/VBox/BackButton as Button

const RESOLUTIONS := [
	[1280, 720],
	[1920, 1080],
	[1600, 900],
	[1366, 768],
]

func _ready() -> void:
	_load_settings()
	volume_slider.value_changed.connect(_on_volume_changed)
	res_option.item_selected.connect(_on_resolution_selected)
	back_button.pressed.connect(_on_back_pressed)

	# Sonic Mania Style: Slide in animation
	position.x = 1000 # Start off-screen
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", 0, 0.5)

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		volume_slider.value = cfg.get_value("audio", "volume", 1.0)
	else:
		volume_slider.value = 1.0
	_update_volume_label(volume_slider.value)

	var current_res = DisplayServer.window_get_size()
	var found = -1
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i][0] == current_res.x and RESOLUTIONS[i][1] == current_res.y:
			found = i
			break

	res_option.clear()
	for r in RESOLUTIONS:
		res_option.add_item("%dx%d" % [r[0], r[1]])
	res_option.selected = found if found >= 0 else 0

func _on_volume_changed(value: float) -> void:
	_update_volume_label(value)
	_save_audio_settings(value)
	var db = linear_to_db(value) if value > 0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _update_volume_label(v: float) -> void:
	volume_label.text = str(int(v * 100)) + "%"

func _save_audio_settings(volume: float) -> void:
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("audio", "volume", volume)
	cfg.save("user://settings.cfg")

func _on_resolution_selected(index: int) -> void:
	var w = RESOLUTIONS[index][0]
	var h = RESOLUTIONS[index][1]
	DisplayServer.window_set_size(Vector2i(w, h))

func _on_back_pressed() -> void:
	# Slide out animation
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", 1000, 0.3)
	await tween.finished
	back_requested.emit()
