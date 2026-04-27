extends Control

@onready var stage_nodes = $StageNodes
@onready var hud         = $HUD

# Progresso em memória — carregado uma vez no _ready
var cleared_stages: Array[String] = []

func _ready() -> void:
	_load_progress()
	_connect_stage_nodes()
	_update_available_nodes()

# ── Conexão de sinais ─────────────────────────────────────────
func _connect_stage_nodes() -> void:
	for node in _get_all_nodes():
		node.button_pressed.connect(_on_stage_selected.bind(node))
		node.mouse_entered.connect(_on_node_hover.bind(node))
		node.mouse_exited.connect(_on_node_hover_exit.bind(node))

# ── Hover ─────────────────────────────────────────────────────
func _on_node_hover(node: StageNode) -> void:
	if _is_node_unlocked(node) and hud:
		hud.update_stage_info(node.stage_name)

func _on_node_hover_exit(_node: StageNode) -> void:
	if hud:
		hud.clear_info()

# ── Seleção de fase ───────────────────────────────────────────
func _on_stage_selected(node: StageNode) -> void:
	if _is_node_unlocked(node):
		_enter_stage(node)

func _enter_stage(node: StageNode) -> void:
	if node.scene_path.is_empty():
		print("Cena da fase não definida: " + node.stage_name)
		return
	_save_progress()
	get_tree().change_scene_to_file(node.scene_path)

# ── Estado dos nós ────────────────────────────────────────────
func _update_available_nodes() -> void:
	for node in _get_all_nodes():
		if node.name in cleared_stages:
			node.set_state(StageNode.State.CLEARED)
		elif _is_node_unlocked(node):
			node.set_state(StageNode.State.AVAILABLE)
		else:
			node.set_state(StageNode.State.LOCKED)

func _is_node_unlocked(node: StageNode) -> bool:
	var all_nodes = _get_all_nodes()
	var idx       = all_nodes.find(node)
	if idx == 0:
		return true
	# Desbloqueia se TODOS os nós anteriores foram completados
	for i in range(idx):
		if all_nodes[i].name not in cleared_stages:
			return false
	return true

func _get_all_nodes() -> Array:
	var nodes: Array = []
	for child in stage_nodes.get_children():
		if child is StageNode:
			nodes.append(child)
	return nodes

# ── Salvar / Carregar ─────────────────────────────────────────
const SAVE_PATH = "user://save_data.cfg"

func _save_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "cleared_stages", cleared_stages)
	cfg.save(SAVE_PATH)

func _load_progress() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		cleared_stages = []
		return
	cleared_stages = cfg.get_value("progress", "cleared_stages", [])

# Chamado pela cena de fase ao completar
func mark_cleared(stage_node_name: String) -> void:
	if stage_node_name not in cleared_stages:
		cleared_stages.append(stage_node_name)
	_save_progress()
	_update_available_nodes()
