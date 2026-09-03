extends Node
## DLRSE simulation — continued build: 3 rooms.

signal graph_changed
signal frame_committed(frame_id: int, hash: int)
signal validation_failed(reason: String)
signal scan_activated
signal snap_created(from_id: int, to_id: int)
signal sunder_executed(chain: Array)
signal auditor_intervened
signal gate_opened
signal demo_won
signal room_changed(room_id: int)
signal kernel_changed(kernel_name: String)

const QUANT_SCALE := 1000
const MAX_MUTATIONS_PER_FRAME := 16
const MAX_HISTORY := 64
const MAX_ROOM := 3

enum Kernel { FINAL_COMMIT, FORCE_REVERT, KEEP_DRAFTING }

var frame_id: int = 0
var mutation_log: Array[Dictionary] = []
var history: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var scanned: bool = false
var sunder_count: int = 0
var auditor_active: bool = false
var gate_is_open: bool = false
var last_hash: int = 0
var snap_count: int = 0
var last_reject_reason: String = ""
var current_room: int = 1
var current_kernel: Kernel = Kernel.FINAL_COMMIT
var rooms_completed: int = 0

func _ready() -> void:
	reset_demo()

func set_kernel(k: Kernel) -> void:
	current_kernel = k
	var names = ["Final Commit", "Force Revert", "Keep Drafting"]
	kernel_changed.emit(names[k])

func get_kernel_name() -> String:
	match current_kernel:
		Kernel.FINAL_COMMIT: return "Final Commit"
		Kernel.FORCE_REVERT: return "Force Revert"
		Kernel.KEEP_DRAFTING: return "Keep Drafting"
	return "Unknown"

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
	current_room = 1
	rooms_completed = 0
	_load_room(1)
	graph_changed.emit()

func go_to_room(room_id: int) -> void:
	current_room = clamp(room_id, 1, MAX_ROOM)
	mutation_log.clear()
	edges.clear()
	scanned = false
	sunder_count = 0
	auditor_active = false
	gate_is_open = false
	snap_count = 0
	_load_room(current_room)
	room_changed.emit(current_room)
	graph_changed.emit()

func next_room() -> void:
	if current_room < MAX_ROOM:
		go_to_room(current_room + 1)
	else:
		# Loop back for endless practice or stay on 3
		go_to_room(1)

func _load_room(room_id: int) -> void:
	nodes.clear()
	match room_id:
		1:
			_add_node(0, _q(Vector3(-4, 0, 0)), 1, "Vesper_Lamp")
			_add_node(1, _q(Vector3(-1.5, 0, 2)), 1, "Vesper_Conduit")
			_add_node(2, _q(Vector3(1.5, 0, 1)), 0, "Necro_Spire")
			_add_node(3, _q(Vector3(4, 0, -1)), 1, "Vesper_Gate")
			_add_node(4, _q(Vector3(0, 0, -3)), 0, "Necro_Anchor")
		2:
			_add_node(0, _q(Vector3(-3, 0, 1)), 0, "Necro_Root")
			_add_node(1, _q(Vector3(0, 0, 2.5)), 1, "Vesper_Relay")
			_add_node(2, _q(Vector3(3, 0, 0.5)), 0, "Necro_Vault")
			_add_node(3, _q(Vector3(0, 0, -2.5)), 1, "Vesper_Exit")
			_add_node(4, _q(Vector3(-2, 0, -1)), 0, "Necro_Echo")
			_add_node(5, _q(Vector3(2, 0, -1.5)), 1, "Vesper_Lock")
		3:
			# Heavier Necropolis pressure — more Layer 0 nodes
			_add_node(0, _q(Vector3(-3.5, 0, 0)), 0, "Necro_Heart")
			_add_node(1, _q(Vector3(-1, 0, 2)), 0, "Necro_Rib")
			_add_node(2, _q(Vector3(1.5, 0, 2.2)), 1, "Vesper_Spike")
			_add_node(3, _q(Vector3(3.5, 0, 0)), 0, "Necro_Gate")
			_add_node(4, _q(Vector3(0, 0, -2.8)), 1, "Vesper_Thin")
			_add_node(5, _q(Vector3(-2, 0, -1.5)), 0, "Necro_Ash")
			_add_node(6, _q(Vector3(2, 0, -1.2)), 0, "Necro_Seal")

func _q(v: Vector3) -> Vector3i:
	return Vector3i(int(round(v.x * QUANT_SCALE)), int(round(v.y * QUANT_SCALE)), int(round(v.z * QUANT_SCALE)))

func _fq(qi: Vector3i) -> Vector3:
	return Vector3(float(qi.x) / QUANT_SCALE, float(qi.y) / QUANT_SCALE, float(qi.z) / QUANT_SCALE)

func _add_node(id: int, qpos: Vector3i, layer: int, label: String) -> void:
	nodes.append({"id": id, "qpos": qpos, "layer": layer, "label": label, "active": true, "revealed": false, "locked": false, "domain": [1.0, 0.0, 0.0, 0.0]})

func get_node_pos(id: int) -> Vector3:
	if id < 0 or id >= nodes.size():
		return Vector3.ZERO
	return _fq(nodes[id].qpos)

func begin_frame() -> void:
	mutation_log.clear()
	last_reject_reason = ""

func log_mutation(op_type: String, node_id: int, edge_id: int = -1, payload: Array = [], priority: int = 0) -> void:
	mutation_log.append({"frame": frame_id, "seq": mutation_log.size(), "priority": priority, "op": op_type, "node": node_id, "edge": edge_id, "payload": payload})

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
			var target_id := 3
			if _has_path(0, target_id):
				nodes[target_id]["label"] = str(nodes[target_id].label) + "_OPEN"
				gate_is_open = true
				gate_opened.emit()
				demo_won.emit()
				rooms_completed += 1
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
	var h := 0xCB94F00D ^ (current_kernel * 997) ^ (current_room * 131)
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

func get_auditor_lock_threshold() -> int:
	match current_kernel:
		Kernel.FINAL_COMMIT: return 1
		Kernel.FORCE_REVERT: return 2
		Kernel.KEEP_DRAFTING: return 3
	return 1

func get_room_objective() -> String:
	match current_room:
		1: return "Room 1: Connect Lamp (0) to Vesper Gate (3)"
		2: return "Room 2: Connect Necro Root (0) to Vesper Exit (3)"
		3: return "Room 3: Connect Necro Heart (0) to Necro Gate (3) — heavy Layer 0"
	return "Connect 0 to 3, then SUNDER"
