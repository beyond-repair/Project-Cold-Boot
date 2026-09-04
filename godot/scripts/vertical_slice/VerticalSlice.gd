extends Node3D
## Completeness pass UI: threat, rollback timer, null walker, intel.

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
@onready var sv_l0: SubViewport = $DualLayerViewports/SubViewport_Layer0
@onready var sv_l1: SubViewport = $DualLayerViewports/SubViewport_Layer1
@onready var compositor_rect: ColorRect = $UI/CompositorRect
@onready var floor_mesh: MeshInstance3D = $Floor

var selected_node: int = -1
var demo_complete: bool = false
var paused: bool = false
var show_history: bool = true
var compositor_mat: ShaderMaterial
var rollback_accum: float = 0.0
const SAVE_PATH := "user://coldboot_run.save"

func _ready() -> void:
	GameState.graph_changed.connect(_rebuild_visuals)
	GameState.scan_activated.connect(func(): bleed_seam.visible = true)
	GameState.snap_created.connect(func(a, b): _update_ui("SNAP %d → %d" % [a, b]))
	GameState.sunder_executed.connect(func(_c): _update_ui("Gate open." if GameState.gate_is_open else "Path incomplete."))
	GameState.auditor_intervened.connect(_on_auditor)
	GameState.frame_committed.connect(_on_committed)
	GameState.validation_failed.connect(func(r): _update_ui("Reject: %s" % r))
	GameState.demo_won.connect(_on_win)
	GameState.room_changed.connect(_on_room_changed)
	GameState.kernel_changed.connect(func(n): _update_kernel_ui(); _update_ui("Kernel: %s" % n))
	GameState.null_walker_stirred.connect(func(m): _update_ui(m))
	GameState.rollback_tick.connect(func(s): hash_label.text = "ROLLBACK %ds | %s" % [s, GameState.get_district_name()])
	win_panel.visible = false
	pause_panel.visible = false
	history_label.visible = show_history
	_apply_atmosphere()
	_setup_compositor()
	_rebuild_visuals()
	_update_all()
	_update_ui("%s. E = SCAN. Intel: %s" % [GameState.get_district_name(), GameState.get_intel()])
	help_label.text = "E SCAN | LMB SNAP | SPACE SUNDER | R Reset | Esc Pause | H History | 1/2/3 Kernel | N Next | F5/F9 Save/Load"

func _process(delta: float) -> void:
	if cam_main and cam_l0 and cam_l1:
		cam_l0.global_transform = cam_main.global_transform
		cam_l1.global_transform = cam_main.global_transform
	if paused or demo_complete:
		return
	if GameState.is_rollback_district() and GameState.scanned and not GameState.gate_is_open:
		rollback_accum += delta
		if rollback_accum >= 1.0:
			rollback_accum = 0.0
			GameState.tick_rollback(1.0)

func _setup_compositor() -> void:
	if compositor_rect == null:
		return
	var shader := load("res://shaders/domain_warp_compositor.gdshader") as Shader
	if shader == null:
		return
	compositor_mat = ShaderMaterial.new()
	compositor_mat.shader = shader
	var tex0 := ViewportTexture.new()
	tex0.viewport_path = sv_l0.get_path()
	var tex1 := ViewportTexture.new()
	tex1.viewport_path = sv_l1.get_path()
	compositor_mat.set_shader_parameter("layer0_tex", tex0)
	compositor_mat.set_shader_parameter("layer1_tex", tex1)
	compositor_mat.set_shader_parameter("bleed_intensity", 0.12 + GameState.get_district().threat * 0.1)
	compositor_mat.set_shader_parameter("violet_seam", Color(0.82, 0.35, 1.0))
	compositor_rect.material = compositor_mat

func _set_bleed(amount: float) -> void:
	if compositor_mat:
		compositor_mat.set_shader_parameter("bleed_intensity", clamp(amount, 0.0, 1.0))

func _apply_atmosphere() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.03, 0.03, 0.05)
	floor_mat.metallic = 0.75
	floor_mat.roughness = 0.22
	floor_mesh.material_override = floor_mat
	for pair in [[auditor_mesh, Color(0.35, 0.05, 0.55)], [sable_mesh, Color(0.6, 0.2, 0.95)]]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.07, 0.05, 0.1)
		mat.emission_enabled = true
		mat.emission = pair[1]
		mat.emission_energy_multiplier = 2.0
		pair[0].material_override = mat
	var seam_mat := StandardMaterial3D.new()
	seam_mat.emission_enabled = true
	seam_mat.emission = Color(0.85, 0.35, 1.0)
	seam_mat.emission_energy_multiplier = 8.0
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bleed_seam.material_override = seam_mat

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		paused = not paused
		pause_panel.visible = paused
		get_tree().paused = paused
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
					GameState.next_room()
					demo_complete = false
					auditor_mesh.visible = false
					sable_mesh.visible = false
					win_panel.visible = false
					selected_node = -1
					_set_bleed(0.12 + GameState.get_district().threat * 0.12)
					_update_ui("%s | %s" % [GameState.get_district_name(), GameState.get_intel()])
				return
			KEY_F5:
				_save_run()
				return
			KEY_F9:
				_load_run()
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
		GameState.reset_demo()
		selected_node = -1
		demo_complete = false
		auditor_mesh.visible = false
		sable_mesh.visible = false
		win_panel.visible = false
		bleed_seam.visible = false
		_set_bleed(0.15)
		_update_all()
		_update_ui("Reset.")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_node()

func _save_run() -> void:
	var data := {"current_room": GameState.current_room, "current_kernel": GameState.current_kernel, "rooms_completed": GameState.rooms_completed, "scanned": GameState.scanned, "gate_is_open": GameState.gate_is_open, "edges": GameState.edges.duplicate(true), "history": GameState.history.duplicate(true), "nodes_locked": [], "last_path": GameState.last_path_nodes.duplicate()}
	for n in GameState.nodes:
		if n.locked: data.nodes_locked.append(n.id)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		_update_ui("Saved.")

func _load_run() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	GameState.go_to_room(int(data.get("current_room", 1)))
	GameState.current_kernel = int(data.get("current_kernel", 0))
	GameState.rooms_completed = int(data.get("rooms_completed", 0))
	GameState.scanned = bool(data.get("scanned", false))
	GameState.gate_is_open = bool(data.get("gate_is_open", false))
	GameState.edges = data.get("edges", [])
	GameState.history = data.get("history", [])
	GameState.last_path_nodes = data.get("last_path", [])
	var locked: Array = data.get("nodes_locked", [])
	for n in GameState.nodes:
		n.locked = n.id in locked
		n.revealed = GameState.scanned
	demo_complete = GameState.gate_is_open
	sable_mesh.visible = GameState.gate_is_open
	win_panel.visible = GameState.gate_is_open
	GameState.graph_changed.emit()
	_update_all()
	_update_ui("Loaded.")

func _do_scan() -> void:
	if GameState.scanned:
		return
	GameState.begin_frame()
	GameState.log_mutation("SCAN", 0, -1, [], 0)
	if GameState.commit_frame():
		_set_bleed(0.3 + GameState.get_district().threat * 0.35)
		_update_ui("SCAN | Threat %d%%" % int(GameState.get_district().threat * 100))
		_update_objective()

func _try_select_node() -> void:
	if not GameState.scanned:
		_update_ui("SCAN first.")
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(get_viewport().get_mouse_position())
	var dir := cam.project_ray_normal(get_viewport().get_mouse_position())
	var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * 100.0))
	if result.is_empty():
		return
	var c = result.collider
	if c and c.has_meta("node_id"):
		var id: int = c.get_meta("node_id")
		if GameState.nodes[id].locked:
			_update_ui("Locked [%d]." % id)
			return
		if selected_node == -1:
			selected_node = id
			_update_ui("Selected [%d] %s" % [id, GameState.nodes[id].label])
		elif selected_node != id:
			_do_snap(selected_node, id)
			selected_node = -1

func _do_snap(a: int, b: int) -> void:
	GameState.begin_frame()
	GameState.log_mutation("SNAP", a, b, [], 0)
	if GameState.snap_count >= GameState.get_auditor_lock_threshold() and not GameState.auditor_active:
		var t := GameState.pick_auditor_lock_target()
		if t >= 0:
			GameState.log_mutation("AUD_LOCK", t, -1, [], 2)
	if GameState.commit_frame():
		_update_objective()

func _do_sunder() -> void:
	if GameState.edges.is_empty():
		return
	GameState.begin_frame()
	GameState.log_mutation("SUNDER", 0, -1, [], 0)
	if GameState.commit_frame():
		_update_objective()

func _on_auditor() -> void:
	auditor_mesh.visible = true
	_update_ui("AUDITOR lock (bias active).")

func _on_win() -> void:
	demo_complete = true
	sable_mesh.visible = true
	win_panel.visible = true
	_set_bleed(0.75)
	var line := GameState.last_sable_line
	_update_ui("%s clear. Sable: \"%s\"" % [GameState.get_district_name(), line])
	var wl = win_panel.get_node_or_null("WinLabel")
	if wl:
		wl.text = "%s REWRITTEN\nSable: \"%s\"\nN = next | F5 = save" % [GameState.get_district_name(), line]

func _on_room_changed(_id: int) -> void:
	_update_all()
	bleed_seam.visible = false

func _on_committed(_f: int, h: int) -> void:
	if not GameState.is_rollback_district():
		hash_label.text = "Hash %d | Edges %d | Threat %d%%" % [h, GameState.edges.size(), int(GameState.get_district().threat * 100)]
	history_label.text = "History:\n" + GameState.get_history_summary()

func _update_ui(msg: String) -> void:
	status_label.text = msg

func _update_objective() -> void:
	if not GameState.scanned:
		objective_label.text = GameState.get_room_objective() + " | SCAN"
	elif not GameState.gate_is_open:
		objective_label.text = GameState.get_room_objective() + " | SNAP+SUNDER"
	else:
		objective_label.text = GameState.get_district_name() + " clear"

func _update_kernel_ui() -> void:
	kernel_label.text = "Kernel: %s" % GameState.get_kernel_name()

func _update_room_ui() -> void:
	var d = GameState.get_district()
	room_label.text = "%s (%d/6) | Threat %d%% | Cleared %d\n%s" % [d.name, GameState.current_room, int(d.threat * 100), GameState.rooms_completed, GameState.get_intel()]

func _update_all() -> void:
	_update_objective()
	_update_kernel_ui()
	_update_room_ui()

func _rebuild_visuals() -> void:
	for c in node_container.get_children():
		c.queue_free()
	for c in edge_container.get_children():
		c.queue_free()
	for n in GameState.nodes:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.38
		sphere.height = 0.76
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.06, 0.38) if n.layer == 0 else Color(0.12, 0.35, 0.55)
		if n.revealed or GameState.scanned:
			mat.emission_enabled = true
			mat.emission = Color(0.75, 0.3, 1.0)
			mat.emission_energy_multiplier = 3.5
		if n.locked:
			mat.emission = Color(1.0, 0.15, 0.2)
		if str(n.label).ends_with("_OPEN"):
			mat.emission = Color(0.3, 1.0, 0.55)
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
	for e in GameState.edges:
		var a: Vector3 = GameState.get_node_pos(e.from)
		var b: Vector3 = GameState.get_node_pos(e.to)
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.07
		cyl.bottom_radius = 0.07
		cyl.height = a.distance_to(b)
		mi.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.35, 1.0)
		mat.emission_energy_multiplier = 6.0
		mi.material_override = mat
		mi.position = (a + b) / 2.0
		mi.look_at(b, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		edge_container.add_child(mi)
