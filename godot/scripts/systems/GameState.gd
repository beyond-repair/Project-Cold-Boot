extends Node
## Minimal DLRSE state for vertical slice → expanding toward full game.

signal graph_changed
signal frame_committed(frame_id: int, hash: int)
signal validation_failed(reason: String)
signal scan_activated
signal snap_created(from_id: int, to_id: int)
signal sunder_executed(chain: Array)
signal auditor_intervened
signal gate_opened
signal demo_won

const MAX_NODES := 32
const MAX_EDGES := 64

var frame_id: int = 0
var mutation_log: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var scanned: bool = false
var sunder_count: int = 0
var auditor_active: bool = false
var gate_is_open: bool = false
var last_hash: int = 0
var snap_count: int = 0

func _ready() -> void:
	reset_demo()

func reset_demo() -> void:
	frame_id = 0
	mutation_log.clear()
	nodes.clear()
	edges.clear()
	scanned = false
	sunder_count = 0
	auditor_active = false
	gate_is_open = false
	last_hash = 0
	snap_count = 0
	_add_node(0, Vector3(-4, 0, 0), 1, "Vesper_Lamp")
	_add_node(1, Vector3(-1.5, 0, 2), 1, "Vesper_Conduit")
	_add_node(2, Vector3(1.5, 0, 1), 0, "Necro_Spire")
	_add_node(3, Vector3(4, 0, -1), 1, "Vesper_Gate")
	_add_node(4, Vector3(0, 0, -3), 0, "Necro_Anchor")
	graph_changed.emit()

func _add_node(id: int, pos: Vector3, layer: int, label: String) -> void:
	nodes.append({
		"id": id,
		"pos": pos,
		"layer": layer,
		"label": label,
		"active": true,
		"revealed": false,
		"locked": false,
		"domain": [1.0, 0.0, 0.0, 0.0]
	})

func begin_frame() -> void:
	mutation_log.clear()

func log_mutation(op_type: String, node_id: int, edge_id: int = -1, payload: Array = []) -> void:
	var rec := {
		"frame": frame_id,
		"seq": mutation_log.size(),
		"op": op_type,
		"node": node_id,
		"edge": edge_id,
		"payload": payload
	}
	mutation_log.append(rec)

func commit_frame() -> bool:
	if mutation_log.size() > 16:
		validation_failed.emit("Budget exceeded")
		mutation_log.clear()
		return false
	for rec in mutation_log:
		_apply(rec)
	frame_id += 1
	last_hash = _compute_hash()
	frame_committed.emit(frame_id, last_hash)
	mutation_log.clear()
	graph_changed.emit()
	return true

func _apply(rec: Dictionary) -> void:
	match rec.op:
		"SCAN":
			for n in nodes:
				n.revealed = true
			scanned = true
			scan_activated.emit()
		"SNAP":
			var from_id: int = rec.node
			var to_id: int = rec.edge
			if from_id >= 0 and to_id >= 0 and from_id < nodes.size() and to_id < nodes.size():
				if nodes[from_id].locked or nodes[to_id].locked:
					return
				# Prevent duplicate edges
				for e in edges:
					if (e.from == from_id and e.to == to_id) or (e.from == to_id and e.to == from_id):
						return
				edges.append({"from": from_id, "to": to_id, "strength": 1.0, "corrupted": false})
				snap_count += 1
				snap_created.emit(from_id, to_id)
		"SUNDER":
			var chain: Array = []
			for e in edges:
				if not e.corrupted:
					chain.append(e)
			sunder_count += 1
			sunder_executed.emit(chain)
			if _has_path(0, 3):
				nodes[3]["label"] = "Vesper_Gate_OPEN"
				gate_is_open = true
				gate_opened.emit()
				demo_won.emit()
		"AUD_LOCK":
			var nid: int = rec.node
			if nid >= 0 and nid < nodes.size():
				nodes[nid].locked = true
				auditor_active = true
				auditor_intervened.emit()

func _has_path(from_id: int, to_id: int) -> bool:
	var visited := {}
	var queue := [from_id]
	visited[from_id] = true
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == to_id:
			return true
		for e in edges:
			if e.corrupted:
				continue
			if e.from == current and not visited.has(e.to):
				visited[e.to] = true
				queue.append(e.to)
			elif e.to == current and not visited.has(e.from):
				visited[e.from] = true
				queue.append(e.from)
	return false

func _compute_hash() -> int:
	var h := 0xCB94F00D
	for n in nodes:
		h = (h * 31 + n.id) ^ (n.layer * 17)
		if n.locked:
			h ^= 0xA11D
	for e in edges:
		h = (h * 13 + e.from * 7 + e.to) ^ int(e.strength * 100)
	return h

func get_revealed_nodes() -> Array:
	var out: Array = []
	for n in nodes:
		if n.revealed or scanned:
			out.append(n)
	return out
