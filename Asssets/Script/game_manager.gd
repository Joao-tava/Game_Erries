extends Node

# ── Sinais ────────────────────────────────────────────────────
signal collectible_collected(count: int)
signal time_updated(elapsed: float)

# ── Estado ───────────────────────────────────────────────────
var collect_count:  int   = 0
var total_collects: int   = 0
var elapsed_time:   float = 0.0

func _ready() -> void:
	# Reseta ao carregar nova cena
	collect_count = 0
	elapsed_time  = 0.0

# Atualiza tempo a cada frame (chamado via _process)
func update_time(delta: float) -> void:
	elapsed_time += delta
	time_updated.emit(elapsed_time)

# Adiciona +1 ao contador de coletáveis
func add_collect() -> void:
	collect_count += 1
	collectible_collected.emit(collect_count)

# Retorna tempo formatado
func get_formatted_time() -> String:
	var mins    = int(elapsed_time) / 60
	var secs    = int(elapsed_time) % 60
	var millis  = int((elapsed_time - floor(elapsed_time)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]
