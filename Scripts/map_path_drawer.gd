class_name MapPathDrawer
extends Node2D

@export var line_color: Color = Color(0.8, 0.8, 0.8, 0.5)
@export var line_width: float = 3.0
@export var dash_length: float = 10.0

func _draw():
	var stage_nodes = get_parent()
	if not stage_nodes:
		return

	var drawn_connections = {}

	for node_a in stage_nodes.get_children():
		if not node_a is StageNode:
			continue

		for connection_name in node_a.connections:
			var connection_key = _get_connection_key(node_a.name, connection_name)
			if drawn_connections.has(connection_key):
				continue

			for node_b in stage_nodes.get_children():
				if node_b is StageNode and node_b.name == connection_name:
					_draw_dashed_line(node_a.position, node_b.position)
					drawn_connections[connection_key] = true

func _draw_dashed_line(start: Vector2, end: Vector2):
	var distance = start.distance_to(end)
	var direction = (end - start).normalized()
	var num_dashes = int(distance / dash_length)

	for i in range(num_dashes):
		var dash_start = start + direction * (i * dash_length * 2)
		var dash_end = dash_start + direction * dash_length
		draw_line(dash_start, dash_end, line_color, line_width, true)

func _get_connection_key(name_a: String, name_b: String) -> String:
	if name_a < name_b:
		return name_a + "_" + name_b
	else:
		return name_b + "_" + name_a
