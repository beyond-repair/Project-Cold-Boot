extends Node
## District spine + biased Auditor.

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

enum Kernel { FINAL_COMMIT, FORCE_REVERT, KEEP_DRAFTING }

const DISTRICTS := [
	{"id": 1, "name": "Compiler Heights", "threat": 0.9, "blurb": "Where reality is written.", "sable": "Orpheus is listening. Stay unreadable."},
	{"id": 2, "name": "Static Market", "threat": 0.68, "blurb": "Trade in what was.", "sable": "Every memory here has a price. You already paid."},
	{"id": 3, "name": "Ghost Rail", "threat": 0.5, "blurb": "Transit between impossible places.", "sable": "The schedule lies. Trust the seam."},
	{"id": 4, "name": "Rollback District", "threat": 0.7, "blurb": "Break the 47-second cycle.", "sable": "Patterns are cages. Break one variable."},
	{"id": 5, "name": "Dead Repository", "threat": 0.82, "blurb": "Archives of what never was.", "sable": "Wardens restore what you destroy. Be faster."},
	{"id": 6, "name": "The Sink", "threat": 0.95, "blurb": "Where deleted realities go to die.", "sable": "If you fall here, even I can't pull the draft back."}
]

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
var last_path_nodes: Array = []  # nodes used in recent SNAPs
var last_sable_line: String = ""

func _ready() -> void:
	reset_demo()

func get_district() -> Dictionary:
	return DISTRICTS[clamp(current_room - 1, 0, DISTRICTS.size() - 1)]

func get_district_name() -> String:
	return str(get_district().name)

func get_sable_line() -> String:
	return str(get_district().get("sable", "Stay unreadable."))

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
	last_path_nodes.clear()
	last_sable_line = ""
	_load_room(1)
	graph_changed.emit()

func go_to_room(room_id: int) -> void:
	current_room = clamp(room_id, 1, DISTRICTS.size())
	mutation_log.clear()
	edges.clear()
	scanned = false
	sunder_count = 0
	auditor_active = false
	gate_is_open = false
	snap_count = 0
	last_path_nodes.clear()
	_load_room(current_room)
	room_changed.emit(current_room)
	graph_changed.emit()

func next_room() -> void:
	if current_room < DISTRICTS.size():
		go_to_room(current_room + 1)
	else:
		go_to_room(1)

func _load_room(room_id: int) -> void:
	nodes.clear()
	match room_id:
		1:
			_add_node(0, _q(Vector3(-4, 0, 0)), 1, "Orpheus_Lamp")
			_add_node(1, _q(Vector3(-1.5, 0, 2)), 1, "Security_Grid")
			_add_node(2, _q(Vector3(1.5, 0, 1)), 0, "Necro_Spire")
			_add_node(3, _q(Vector3(4, 0, -1)), 1, "Core_Gate")
			_add_node(4, _q(Vector3(0, 0, -3)), 0, "Rule_Terminal")
		2:
			_add_node(0, _q(Vector3(-3, 0, 1)), 0, "Memory_Stall")
			_add_node(1, _q(Vector3(0, 0, 2.5)), 1, "Fixer_Relay")
			_add_node(2, _q(Vector3(3, 0, 0.5)), 0, "Black_Ledger")
			_add_node(3, _q(Vector3(0, 0, -2.5)), 1, "Market_Exit")
			_add_node(4, _q(Vector3(-2, 0, -1)), 0, "Stolen_Anchor")
			_add_node(5, _q(Vector3(2, 0, -1.5)), 1, "Betrayal_Lock")
		3:
			_add_node(0, _q(Vector3(-3.5, 0, 0)), 1, "Platform_A")
			_add_node(1, _q(Vector3(-1, 0, 2)), 0, "Nowhere_Track")
			_add_node(2, _q(Vector3(1.5, 0, 2)), 1, "Yesterday_Car")
			_add_node(3, _q(Vector3(3.5, 0, 0)), 1, "Departure_Gate")
			_add_node(4, _q(Vector3(0, 0, -2.5)), 0, "Schedule_Glitch")
		4:
			_add_node(0, _q(Vector3(-3, 0, 0)), 1, "Loop_Start")
			_add_node(1, _q(Vector3(0, 0, 2)), 1, "Timer_Node")
			_add_node(2, _q(Vector3(3, 0, 0)), 0, "Pattern_Echo")
			_add_node(3, _q(Vector3(0, 0, -2.5)), 1, "Break_Gate")
			_add_node(4, _q(Vector3(-2, 0, -1)), 0, "Reset_Anchor")
			_add_node(5, _q(Vector3(2, 0, -1)), 1, "Persistent_Var")
		5:
			_add_node(0, _q(Vector3(-3.5, 0, 0)), 0, "Archive_Root")
			_add_node(1, _q(Vector3(-1, 0, 2)), 0, "Failed_Timeline")
			_add_node(2, _q(Vector3(1.5, 0, 2)), 1, "Warden_Seal")
			_add_node(3, _q(Vector3(3.5, 0, 0)), 0, "Vault_Gate")
			_add_node(4, _q(Vector3(0, 0, -2.8)), 0, "Erased_Self")
			_add_node(5, _q(Vector3(-2, 0, -1.5)), 0, "Index_Ash")
		6:
			_add_node(0, _q(Vector3(-3.5, 0, 0)), 0, "Collapse_Heart")
			_add_node(1, _q(Vector3(-1, 0, 2)), 0, "Gravity_Fold")
			_add_node(2, _q(Vector3(1.5, 0, 2.2)), 0, "Null_Rib")
			_add_node(3, _q(Vector3(3.5, 0, 0)), 0, "Sink_Gate")
			_add_node(4, _q(Vector3(0, 0, -2.8)), 1, "Last_Vesper")
			_add_node(5, _q(Vector3(-2, 0, -1.5)), 0, "Deleted_Street")
			_add_node(6, _q(Vector3(2, 0, -1.2)), 0, "Unraveled_Mind")

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
		return _reject("Partition integrity failed")
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

func _node_degree(id: int) -> int:
	var d := 0
	for e in edges:
		if e.from == id or e.to == id:
			d += 1
	return d

## Biased Auditor target: centrality + path memory + Layer-0 + avoid 0/3 endpoints if possible
func pick_auditor_lock_target() -> int:
	var best_id := -1
	var best_score := -1.0
	var threat: float = float(get_district().threat)
	for n in nodes:
		var id: int = n.id
		if n.locked:
			continue
		if id == 0 or id == 3:
			continue  # don't hard-lock start/exit; force re-route around hubs
		var score := 0.0
		score += float(_node_degree(id)) * 2.0
		if id in last_path_nodes:
			score += 3.0
		if int(n.layer) == 0:
			score += 1.5 * threat  # Necropolis pressure
		else:
			score += 0.5
		# Kernel weight: Final Commit prefers hubs harder
		if current_kernel == Kernel.FINAL_COMMIT:
			score += float(_node_degree(id))
		elif current_kernel == Kernel.KEEP_DRAFTING:
			score *= 0.75
		if score > best_score:
			best_score = score
			best_id = id
	if best_id < 0 and nodes.size() > 2:
		best_id = 1
	return best_id

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
			if from_id not in last_path_nodes:
				last_path_nodes.append(from_id)
			if to_id not in last_path_nodes:
				last_path_nodes.append(to_id)
			if last_path_nodes.size() > 12:
				last_path_nodes.pop_front()
			snap_created.emit(from_id, to_id)
		"SUNDER":
			var chain: Array = []
			for e in edges:
				if not e.corrupted:
					chain.append(e)
			sunder_count += 1
			sunder_executed.emit(chain)
			if _has_path(0, 3):
				nodes[3]["label"] = str(nodes[3].label) + "_OPEN"
				gate_is_open = true
				last_sable_line = get_sable_line()
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
	# Higher district threat → slightly earlier intervention
	var base := 1
	match current_kernel:
		Kernel.FINAL_COMMIT: base = 1
		Kernel.FORCE_REVERT: base = 2
		Kernel.KEEP_DRAFTING: base = 3
	var threat: float = float(get_district().threat)
	if threat >= 0.85 and base > 1:
		base -= 1
	return max(1, base)

func get_room_objective() -> String:
	var d = get_district()
	return "%s: connect 0 → 3, then SUNDER — %s" % [d.name, d.blurb]
