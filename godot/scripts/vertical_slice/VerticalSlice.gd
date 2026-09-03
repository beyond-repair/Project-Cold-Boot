extends Node3D
## Vertical Slice — Cycle 5: Visual fidelity pass aligned to locked art.

@onready var status_label: Label = $UI/StatusLabel
@onready var help_label: Label = $UI/HelpLabel
@onready var hash_label: Label = $UI/HashLabel
@onready var objective_label: Label = $UI/ObjectiveLabel
@onready var history_label: Label = $UI/HistoryLabel
@onready var kernel_label: Label = $UI/KernelLabel
@onready var room_label: Label = $UI/RoomLabel
@onready var node_container: Node3D = $GraphNodes
@onready var edge_container: Node3D = $GraphEdges
@onready var auditor_mesh: MeshInstance3D = $Auditor
@onready var sable_mesh: MeshInstance3D = $Sable
@onready var bleed_seam: MeshInstance3D = $BleedSeam
@onready var win_panel: Control = $UI/WinPanel
@onready var pause_panel: Control = $UI/PausePanel
@onready var cam_main: Camera3D = $Camera3D
@onready var cam_l0: Camera3D = $DualLayerViewports/SubViewport_Layer0/Camera3D_L0
@onready var cam_l1: Camera3D = $DualLayerViewports/SubViewport_Layer1/Camera3D_L1
@onready var floor_mesh: MeshInstance3D = $Floor

var selected_node: int = -1
var node_meshes: Dictionary = {}
var demo_complete: bool = false
var paused: bool = false
var show_history: bool = true

func _ready() -> void:
	GameState.graph_changed.connect(_rebuild_visuals)
	GameState.scan_activated.connect(_on_scan)
	GameState.snap_created.connect(_on_snap)
	GameState.sunder_executed.connect(_on_sunder)
	GameState.auditor_intervened.connect(_on_auditor)
	GameState.frame_committed.connect(_on_committed)
	GameState.validation_failed.connect(_on_validation_failed)
	GameState.demo_won.connect(_on_win)
	GameState.room_changed.connect(_on_room_changed)
	GameState.kernel_changed.connect(_on_kernel_changed)
	win_panel.visible = false
	pause_panel.visible = false
	history_label.visible = show_history
	_apply_atmosphere()
	_rebuild_visuals()
	_update_objective()
	_update_kernel_ui()
	_update_room_ui()
	_update_ui("Press E to SCAN. Art direction locked to reference images.")
	help_label.text = "E=SCAN LMB=SNAP SPACE=SUNDER R=Reset Esc=Pause H=History | 1/2/3=Kernel N=NextRoom"

func _apply_atmosphere() -> void:
	# Dark wet cyber-noir / gothic base matching reference
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.03, 0.03, 0.05)
	floor_mat.metallic = 0.7
	floor_mat.roughness = 0.25
	floor_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	floor_mesh.material_override = floor_mat

	# Auditor — dark suit + glitch emission (reference look)
	var aud_mat := StandardMaterial3D.new()
	aud_mat.albedo_color = Color(0.06, 0.06, 0.08)
	aud_mat.metallic = 0.4
	aud_mat.roughness = 0.55
	aud_mat.emission_enabled = true
	aud_mat.emission = Color(0.35, 0.05, 0.55)
	aud_mat.emission_energy_multiplier = 1.8
	auditor_mesh.material_override = aud_mat

	# Sable — corrupted-code violet
	var sable_mat := StandardMaterial3D.new()
	sable_mat.albedo_color = Color(0.09, 0.03, 0.14)
	sable_mat.emission_enabled = true
	sable_mat.emission = Color(0.6, 0.2, 0.95)
	sable_mat.emission_energy_multiplier = 2.4
	sable_mesh.material_override = sable_mat

	# Bleed seam — bright violet lightning matching reference
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.7, 0.25, 1.0)
	seam_mat.emission_enabled = true
	seam_mat.emission = Color(0.85, 0.35, 1.0)
	seam_mat.emission_energy_multiplier = 8.0
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bleed_seam.material_override = seam_mat

func _process(_delta: float) -> void:
	if cam_main and cam_l0 and cam_l1:
		cam_l0.global_transform = cam_main.global_transform
		cam_l1.global_transform = cam_main.global_transform

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_toggle_pause()
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H:
				show_history = not show_history
				history_label.visible = show_history
				return
			KEY_1:
				GameState.set_kernel(GameState.Kernel.FINAL_COMMIT)
				return
			KEY_2:
				GameState.set_kernel(GameState.Kernel.FORCE_REVERT)
				return
			KEY_3:
				GameState.set_kernel(GameState.Kernel.KEEP_DRAFTING)
				return
			KEY_N:
				if demo_complete or GameState.gate_is_open:
					var next_room = 2 if GameState.current_room == 1 else 1
					GameState.go_to_room(next_room)
					demo_complete = false
					auditor_mesh.visible = false
					sable_mesh.visible = false
					win_panel.visible = false
					selected_node = -1
					_update_ui("Entered Room %d. Press E to SCAN." % next_room)
				return
	if paused:
		return
	if demo_complete and not event.is_action_pressed("reset_demo"):
		return
	if event.is_action_pressed("scan"):
		_do_scan()
	elif event.is_action_pressed("sunder"):
		_do_sunder()
	elif event.is_action_pressed("reset_demo"):
		_reset()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_node()

func _toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused
	get_tree().paused = paused

func _reset() -> void:
	GameState.reset_demo()
	selected_node = -1
	demo_complete = false
	auditor_mesh.visible = false
	sable_mesh.visible = false
	win_panel.visible = false
	bleed_seam.visible = false
	_update_ui("Demo reset. Press E to SCAN.")
	_update_objective()
	_update_history()
	_update_room_ui()

func _do_scan() -> void:
	if GameState.scanned:
		_update_ui("Already scanned. Draw SNAP links.")
		return
	GameState.begin_frame()
	GameState.log_mutation("SCAN", 0, -1, [], 0)
	if not GameState.commit_frame():
		_update_ui("SCAN rejected: %s" % GameState.last_reject_reason)
		return
	_update_ui("SCAN complete. Violet anchors revealed. Click two to SNAP.")
	_update_objective()
	_update_history()

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
		if GameState.nodes[id].locked:
			_update_ui("Node %d locked by Auditor. Adapt." % id)
			return
		if selected_node == -1:
			selected_node = id
			_update_ui("Selected [%d] %s" % [id, GameState.nodes[id].label])
		elif selected_node != id:
			_do_snap(selected_node, id)
			selected_node = -1

func _do_snap(from_id: int, to_id: int) -> void:
	GameState.begin_frame()
	GameState.log_mutation("SNAP", from_id, to_id, [], 0)
	var threshold = GameState.get_auditor_lock_threshold()
	if GameState.snap_count >= threshold and not GameState.auditor_active:
		var lock_target = 2 if GameState.nodes.size() > 2 else 1
		GameState.log_mutation("AUD_LOCK", lock_target, -1, [], 2)
	if not GameState.commit_frame():
		_update_ui("SNAP rejected: %s" % GameState.last_reject_reason)
		return
	_update_objective()
	_update_history()

func _do_sunder() -> void:
	if GameState.edges.is_empty():
		_update_ui("No chains to SUNDER.")
		return
	GameState.begin_frame()
	GameState.log_mutation("SUNDER", 0, -1, [], 0)
	if not GameState.commit_frame():
		_update_ui("SUNDER rejected: %s" % GameState.last_reject_reason)
		return
	_update_objective()
	_update_history()

func _on_scan() -> void:
	bleed_seam.visible = true

func _on_snap(from_id: int, to_id: int) -> void:
	_update_ui("SNAP: %d → %d (violet causal link)" % [from_id, to_id])

func _on_sunder(chain: Array) -> void:
	if GameState.gate_is_open:
		_update_ui("SUNDER resolved. Exit OPEN. Press N for next room.")
	else:
		_update_ui("SUNDER (%d links). Path incomplete." % chain.size())

func _on_auditor() -> void:
	auditor_mesh.visible = true
	_update_ui("AUDITOR lock (Kernel: %s). Stay unreadable." % GameState.get_kernel_name())

func _on_win() -> void:
	demo_complete = true
	sable_mesh.visible = true
	win_panel.visible = true
	_update_ui("Room %d rewritten. Sable acknowledges. N = next room." % GameState.current_room)

func _on_room_changed(_room_id: int) -> void:
	_update_room_ui()
	bleed_seam.visible = false

func _on_kernel_changed(kernel_name: String) -> void:
	_update_kernel_ui()
	_update_ui("Kernel: %s" % kernel_name)

func _on_committed(_fid: int, h: int) -> void:
	hash_label.text = "Hash: %d | Edges: %d | Sunders: %d | Frame: %d" % [h, GameState.edges.size(), GameState.sunder_count, _fid]
	_update_history()

func _on_validation_failed(reason: String) -> void:
	_update_ui("Validation failed: %s" % reason)

func _update_ui(msg: String) -> void:
	status_label.text = msg

func _update_objective() -> void:
	if not GameState.scanned:
		objective_label.text = "Objective: SCAN the room (E)"
	elif not GameState.gate_is_open:
		objective_label.text = "Objective: Connect node 0 to exit with SNAP, then SUNDER"
	else:
		objective_label.text = "Objective: Room complete — Press N for next room"

func _update_history() -> void:
	history_label.text = "History:\n" + GameState.get_history_summary()

func _update_kernel_ui() -> void:
	kernel_label.text = "Kernel: %s (1/2/3)" % GameState.get_kernel_name()

func _update_room_ui() -> void:
	room_label.text = "Room: %d | Completed: %d" % [GameState.current_room, GameState.rooms_completed]

func _rebuild_visuals() -> void:
	for c in node_container.get_children():
		c.queue_free()
	for c in edge_container.get_children():
		c.queue_free()
	node_meshes.clear()

	for n in GameState.nodes:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.38
		sphere.height = 0.76
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		# Layer colors locked to art: Necropolis = deep ink purple, Vesper = cyan-teal
		if n.layer == 0:
			mat.albedo_color = Color(0.28, 0.06, 0.38)
		else:
			mat.albedo_color = Color(0.12, 0.35, 0.55)
		mat.metallic = 0.35
		mat.roughness = 0.3
		if n.revealed or GameState.scanned:
			mat.emission_enabled = true
			mat.emission = Color(0.75, 0.3, 1.0)  # signature violet causal energy
			mat.emission_energy_multiplier = 3.5
		if n.locked:
			mat.albedo_color = Color(0.55, 0.08, 0.1)
			mat.emission = Color(1.0, 0.15, 0.2)
			mat.emission_energy_multiplier = 4.0
		if str(n.label).ends_with("_OPEN"):
			mat.albedo_color = Color(0.15, 0.7, 0.35)
			mat.emission = Color(0.3, 1.0, 0.55)
			mat.emission_energy_multiplier = 3.0
		mi.material_override = mat
		mi.position = GameState.get_node_pos(n.id)
		node_container.add_child(mi)

		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.48
		col.shape = shape
		body.add_child(col)
		body.set_meta("node_id", n.id)
		mi.add_child(body)
		node_meshes[n.id] = mi

	for e in GameState.edges:
		var from_pos: Vector3 = GameState.get_node_pos(e.from)
		var to_pos: Vector3 = GameState.get_node_pos(e.to)
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.07
		cyl.bottom_radius = 0.07
		cyl.height = from_pos.distance_to(to_pos)
		mi.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.9, 0.4, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.35, 1.0)  # strong violet chain matching reference SNAP
		mat.emission_energy_multiplier = 6.0
		if e.corrupted:
			mat.albedo_color = Color(1.0, 0.25, 0.3)
			mat.emission = Color(1.0, 0.2, 0.25)
		mi.material_override = mat
		mi.position = (from_pos + to_pos) / 2.0
		mi.look_at(to_pos, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		edge_container.add_child(mi)
