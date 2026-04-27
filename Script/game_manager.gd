extends Node

# ── Sinais ────────────────────────────────────────────────────
signal collectible_collected(count: int)
signal time_updated(elapsed: float)

# ── Estado ───────────────────────────────────────────────────
var collect_count:  int   = 0
var total_collects: int   = 0
var elapsed_time:   float = 0.0
var current_phase:  String = ""

# ── Ranking por fase ──────────────────────────────────────────
# Cada fase define seus próprios limites de tempo (em segundos)
# para as notas S, A, B, C, D, F
var _phase_thresholds: Dictionary = {
	"":      [30.0, 60.0, 90.0, 120.0, 180.0],  # fallback / default
}

func _ready() -> void:
	collect_count = 0
	elapsed_time  = 0.0

func update_time(delta: float) -> void:
	elapsed_time += delta
	time_updated.emit(elapsed_time)

func add_collect() -> void:
	collect_count += 1
	collectible_collected.emit(collect_count)

func get_formatted_time() -> String:
	var mins    = int(elapsed_time) / 60
	var secs    = int(elapsed_time) % 60
	var millis  = int((elapsed_time - floor(elapsed_time)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]

func get_ranking() -> String:
	var thresholds = _phase_thresholds.get(current_phase, _phase_thresholds[""])
	var s = thresholds[0]
	var a = thresholds[1]
	var b = thresholds[2]
	var c = thresholds[3]
	var d = thresholds[4]

	if elapsed_time <= s:
		return "S"
	elif elapsed_time <= a:
		return "A"
	elif elapsed_time <= b:
		return "B"
	elif elapsed_time <= c:
		return "C"
	elif elapsed_time <= d:
		return "D"
	else:
		return "F"

func register_phase(phase_name: String, thresholds: Array) -> void:
	_phase_thresholds[phase_name] = thresholds

func set_current_phase(phase_name: String) -> void:
	current_phase = phase_name

func reset_phase() -> void:
	collect_count  = 0
	elapsed_time   = 0.0
	current_phase  = ""