extends CanvasLayer

# ── Referências dos nós da HUD ────────────────────────────────
@onready var timer_label   := $Panel/TimerLabel     as Label
@onready var collect_label := $Panel/CollectLabel    as Label

# ── Estado ───────────────────────────────────────────────────
var elapsed_seconds: float = 0.0
var collect_count:  int   = 0
var total_collects: int   = 0

func _ready() -> void:
	await get_tree().process_frame
	_count_and_connect_collectibles()
	_update_labels()
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.elapsed_time = 0.0


# Conta coletáveis e conecta sinais
func _count_and_connect_collectibles() -> void:
	var collects = get_tree().get_nodes_in_group("collectibles")
	total_collects = collects.size()

	for c in collects:
		if c.has_signal("collected") and not c.collected.is_connected(_on_collectable_collected):
			c.collected.connect(_on_collectable_collected)

# Callback quando um coletável é pego
func _on_collectable_collected() -> void:
	collect_count += 1
	_update_labels()

# Formata segundos em MM:SS.ms
func _format_time(seconds: float) -> String:
	var mins    = int(seconds) / 60
	var secs    = int(seconds) % 60
	var millis  = int((seconds - floor(seconds)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]

# Atualiza os labels da HUD
func _update_labels() -> void:
	timer_label.text   = _format_time(elapsed_seconds)
	collect_label.text = "%d / %d" % [collect_count, total_collects]
	
func _process(delta: float) -> void:
	elapsed_seconds += delta
	timer_label.text = _format_time(elapsed_seconds)
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.elapsed_time = elapsed_seconds
