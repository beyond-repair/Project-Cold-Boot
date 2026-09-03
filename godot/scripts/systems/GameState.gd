extends Node
## Architecture-aligned DLRSE simulation (Cycle 2).
## Log-only emission → validate → single-writer commit.
## Quantized positions + MutationLog history for replay/debug.

signal graph_changed
signal frame_committed(frame_id: int, hash: int)
signal validation_failed(reason: String)
signal scan_activated
signal snap_created(from_id: int, to_id: int)
signal sunder_executed(chain: Array)
signal auditor_intervened
signal gate_opened
signal demo_won

const QUANT_SCALE := 1000
const MAX_MUTATIONS_PER_FRAME := 16
const MAX_HISTORY := 64

var frame_id: int = 0
var mutation_log: Array[Dictionary] = []
var history: Array[Dictionary] = []          # retained committed records
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var scanned: bool = false
var sunder_count: int = 0
var auditor_active: bool = false
var gate_is_open: bool = false
var last_hash: int = 0
var snap_count: int = 0
var last_reject_reason: String = ""

func _ready() -> void:
	reset_demo()

func reset_demo() -> void:
	frame_id = 0
	mutation_log.clear()
	history.clear()
	nodes.clear()
	edges.clear()
	scanned = false
	sunder_count = 0
	auditor_active = false
	gate_is_open = false
	last_hash = 0
	snap_count = 0
	last_reject_reason = ""
	_add_node(0, _q(Vector3(-4, 0, 0)), 1, "Vesper_Lamp")
	_add_node(1, _q(Vector3(-1.5, 0, 2)), 1, "Vesper_Conduit")
	_add_node(2, _q(Vector3(1.5, 0, 1)), 0, "Necro_Spire")
	_add_node(3, _q(Vector3(4, 0, -1)), 1, "Vesper_Gate")
	_add_node(4, _q(Vector3(0, 0, -3)), 0, "Necro_Anchor")
	graph_changed.emit()

func _q(v: Vector3) -> Vector3i:
	return Vector3i(int(round(v.x * QUANT_SCALE)), int(round(v.y * QUANT_SCALE)), int(round(v.z * QUANT_SCALE)))

func _fq(qi: Vector3i) -> Vector3:
	return Vector3(float(qi.x) / QUANT_SCALE, float(qi.y) / QUANT_SCALE, float(qi.z) / QUANT_SCALE)

func _add_node(id: int, qpos: Vector3i, layer: int, label: String) -> void:
	nodes.append({
		"id": id, "qpos": qpos, "layer": layer, "label": label,
		"active": true, "revealed": false, "locked": false,
		"domain": [1.0, 0.0, 0.0, 0.0]
	})

func get_node_pos(id: int) -> Vector3:
	if id < 0 or id >= nodes.size():
		return Vector3.ZERO
	return _fq(nodes[id].qpos)

func begin_frame() -> void:
	mutation_log.clear()
	last_reject_reason = ""

func log_mutation(op_type: String, node_id: int, edge_id: int = -1, payload: Array = [], priority: int = 0) -> void:
	mutation_log.append({
		"frame": frame_id, "seq": mutation_log.size(), "priority": priority,
		"op": op_type, "node": node_id, "edge": edge_id, "payload": payload
	})

func commit_frame() -> bool:
	if not _validate_budget():
		return _reject("Budget exceeded")
	if not _validate_partitions():
		return _reject("Partition / identity integrity failed")
	if not _validate_graph_sanity():
		return _reject("Graph sanity failed")

	mutation_log.sort_custom(func(a, b):
		if a.priority != b.priority:
			return a.priority < b.priority
		return a.seq < b.seq
	)

	for rec in mutation_log:
		_apply(rec)
		# Retain history for replay / debug
		history.append(rec.duplicate(true))
		if history.size() > MAX_HISTORY:
			history.pop_front()

	frame_id += 1
	last_hash = _compute_hash()
	frame_committed.emit(frame_id, last_hash)
	mutation_log.clear()
	graph_changed.emit()
	return true

func _reject(reason: String) -> bool:
	last_reject_reason = reason
	validation_failed.emit(reason)
	mutation_log.clear()
	return false

func _validate_budget() -> bool:
	return mutation_log.size() <= MAX_MUTATIONS_PER_FRAME

func _validate_partitions() -> bool:
	for rec in mutation_log:
		var nid: int = rec.node
		if nid < -1 or (nid >= 0 and nid >= nodes.size()):
			return false
		if rec.edge >= 0 and rec.edge >= nodes.size():
			return false
	return true

func _validate_graph_sanity() -> bool:
	for rec in mutation_log:
		if rec.op == "SNAP":
			var a: int = rec.node
			var b: int = rec.edge
			if a >= 0 and a < nodes.size() and nodes[a].locked:
				return false
			if b >= 0 and b < nodes.size() and nodes[b].locked:
				return false
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
			if from_id < 0 or to_id < 0 or from_id >= nodes.size() or to_id >= nodes.size():
				return
			if nodes[from_id].locked or nodes[to_id].locked:
				return
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
		h = h ^ (n.qpos.x + n.qpos.y * 3 + n.qpos.z * 7)
		if n.locked:
			h ^= 0xA11D
	for e in edges:
		h = (h * 13 + e.from * 7 + e.to) ^ int(e.strength * 100)
	return h

func get_history_summary() -> String:
	var lines: PackedStringArray = []
	var start = max(0, history.size() - 8)
	for i in range(start, history.size()):
		var r = history[i]
		lines.append("%d:%s n=%d e=%d" % [r.frame, r.op, r.node, r.edge])
	return "\n".join(lines)
