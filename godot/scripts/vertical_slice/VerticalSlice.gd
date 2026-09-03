extends Node3D
## Vertical Slice gray-box controller.
## SCAN (E) → SNAP (Left Click nodes) → SUNDER (Space) → Escape when gate opens.

@onready var status_label: Label = $UI/StatusLabel
@onready var help_label: Label = $UI/HelpLabel
@onready var hash_label: Label = $UI/HashLabel
@onready var node_container: Node3D = $GraphNodes
@onready var edge_container: Node3D = $GraphEdges
@onready var auditor_mesh: MeshInstance3D = $Auditor
@onready var sable_mesh: MeshInstance3D = $Sable
@onready var bleed_seam: MeshInstance3D = $BleedSeam

var selected_node: int = -1
var node_meshes: Dictionary = {}
var edge_meshes: Array = []
var demo_complete: bool = false

func _ready() -> void:
	GameState.graph_changed.connect(_rebuild_visuals)
	GameState.scan_activated.connect(_on_scan)
	GameState.snap_created.connect(_on_snap)
	GameState.sunder_executed.connect(_on_sunder)
	GameState.auditor_intervened.connect(_on_auditor)
	GameState.frame_committed.connect(_on_committed)
	GameState.validation_failed.connect(_on_validation_failed)
	_rebuild_visuals()
	_update_ui("Press E to SCAN. Click two nodes to SNAP. Space to SUNDER.")
	help_label.text = "E = SCAN | LMB = SNAP (select two nodes) | SPACE = SUNDER | R = Reset"

func _unhandled_input(event: InputEvent) -> void:
	if demo_complete and not event.is_action_pressed("reset_demo"):
		return
	if event.is_action_pressed("scan"):
		_do_scan()
	elif event.is_action_pressed("sunder"):
		_do_sunder()
	elif event.is_action_pressed("reset_demo"):
		GameState.reset_demo()
		selected_node = -1
		demo_complete = false
		auditor_mesh.visible = false
		sable_mesh.visible = false
		_update_ui("Demo reset. Press E to SCAN.")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_node()

func _do_scan() -> void:
	GameState.begin_frame()
	GameState.log_mutation("SCAN", 0)
	GameState.commit_frame()
	_update_ui("SCAN complete. Nodes revealed. Click two nodes to create a SNAP link.")

func _try_select_node() -> void:
	if not GameState.scanned:
		_update_ui("Scan first (E).")
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var collider = result.collider
	if collider and collider.has_meta("node_id"):
		var id: int = collider.get_meta("node_id")
		if selected_node == -1:
			selected_node = id
			_update_ui("Selected node %d. Click another node to SNAP." % id)
		elif selected_node != id:
			_do_snap(selected_node, id)
			selected_node = -1

func _do_snap(from_id: int, to_id: int) -> void:
	GameState.begin_frame()
	GameState.log_mutation("SNAP", from_id, to_id)
	# Simple Auditor reaction: after 2 edges, lock a middle node
	if GameState.edges.size() == 1:
		GameState.log_mutation("AUD_LOCK", 2)
	GameState.commit_frame()

func _do_sunder() -> void:
	if GameState.edges.is_empty():
		_update_ui("No chains to SUNDER. Create SNAP links first.")
		return
	GameState.begin_frame()
	GameState.log_mutation("SUNDER", 0)
	GameState.commit_frame()

func _on_scan() -> void:
	bleed_seam.visible = true

func _on_snap(from_id: int, to_id: int) -> void:
	_update_ui("SNAP: %d → %d. Build a path from Lamp (0) to Gate (3), then SUNDER." % [from_id, to_id])

func _on_sunder(chain: Array) -> void:
	var gate_open := false
	for n in GameState.nodes:
		if n.id == 3 and n.label.ends_with("OPEN"):
			gate_open = true
	if gate_open:
		demo_complete = true
		sable_mesh.visible = true
		_update_ui("SUNDER resolved. Gate OPEN. Sable acknowledges. Demo complete. Press R to reset.")
	else:
		_update_ui("SUNDER executed (%d links). Connect Lamp (0) to Gate (3) and try again." % chain.size())

func _on_auditor() -> void:
	auditor_mesh.visible = true
	_update_ui("AUDITOR intervened — a node has been locked. Find another path.")

func _on_committed(_fid: int, h: int) -> void:
	hash_label.text = "Frame Hash: %d | Edges: %d | Sunder: %d" % [h, GameState.edges.size(), GameState.sunder_count]

func _on_validation_failed(reason: String) -> void:
	_update_ui("Validation failed: %s" % reason)

func _update_ui(msg: String) -> void:
	status_label.text = msg

func _rebuild_visuals() -> void:
	# Clear old
	for c in node_container.get_children():
		c.queue_free()
	for c in edge_container.get_children():
		c.queue_free()
	node_meshes.clear()
	edge_meshes.clear()

	# Nodes
	for n in GameState.nodes:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.7
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		if n.layer == 0:
			mat.albedo_color = Color(0.4, 0.1, 0.5)  # Necropolis purple-ink
		else:
			mat.albedo_color = Color(0.2, 0.6, 0.9)  # Vesper cyan
		if n.revealed or GameState.scanned:
			mat.emission_enabled = true
			mat.emission = Color(0.7, 0.3, 1.0)
			mat.emission_energy_multiplier = 2.0
		if n.locked:
			mat.albedo_color = Color(0.8, 0.1, 0.1)
			mat.emission = Color(1.0, 0.0, 0.0)
		mi.material_override = mat
		mi.position = n.pos
		node_container.add_child(mi)

		# Collision for clicking
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		col.shape = shape
		body.add_child(col)
		body.set_meta("node_id", n.id)
		mi.add_child(body)
		node_meshes[n.id] = mi

	# Edges
	for e in GameState.edges:
		var from_pos: Vector3 = GameState.nodes[e.from].pos
		var to_pos: Vector3 = GameState.nodes[e.to].pos
		var mi := MeshInstance3D.new()
		var mesh := ImmediateMesh.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.8, 0.3, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.2, 1.0)
		mat.emission_energy_multiplier = 3.0
		if e.corrupted:
			mat.albedo_color = Color(1.0, 0.2, 0.2)
		mi.material_override = mat
		# Simple cylinder between points
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = from_pos.distance_to(to_pos)
		mi.mesh = cyl
		mi.look_at_from_position((from_pos + to_pos) / 2.0, to_pos, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		mi.position = (from_pos + to_pos) / 2.0
		edge_container.add_child(mi)
		edge_meshes.append(mi)
