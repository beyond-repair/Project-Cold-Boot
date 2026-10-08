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
## Node tags are 2D labels on the HUD layer, placed in screen space so they
## never overlap each other, other spheres or the HUD, and beams pass under
## their dark backing instead of through the text.
var tag_layer: Control
var tag_rects: Dictionary = {}    # node id -> Rect2 (screen space)
var tag_circles: Dictionary = {}  # node id -> Vector3(x, y, radius) of the sphere on screen
const TAG_FONT_SIZE := 15
const TAG_GAP := 5.0
const SAVE_PATH := "user://coldboot_run.save"
## Spheres and beams sit this far above y=0 so the floor slab (top at y=0.1)
## does not bury the beams or cut the spheres in half.
const NODE_LIFT := 0.45

func vis_pos(id: int) -> Vector3:
	return GameState.get_node_pos(id) + Vector3(0, NODE_LIFT, 0)

func _ready() -> void:
	# Esc pauses the tree; this node must keep receiving input so Esc can unpause.
	# Gameplay is gated by `paused` in _process and _unhandled_input instead.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.graph_changed.connect(_rebuild_visuals)
	GameState.scan_activated.connect(func(): bleed_seam.visible = true)
	# The SNAP readout is written by _do_snap in click order (with any Auditor
	# lock from the same commit appended), not from the snap_created signal.
	GameState.sunder_executed.connect(func(_c): _update_ui("SUNDER: gate open." if GameState.gate_is_open else "Path incomplete. Link 0 to 3, then SUNDER."))
	GameState.auditor_intervened.connect(_on_auditor)
	GameState.frame_committed.connect(_on_committed)
	GameState.validation_failed.connect(func(r): _update_ui("Reject: %s" % r))
	GameState.demo_won.connect(_on_win)
	GameState.room_changed.connect(_on_room_changed)
	GameState.kernel_changed.connect(func(_n): _update_kernel_ui(); _clear_selection(); _update_ui("Kernel switched: the Auditor locks a node on SNAP #%d." % (GameState.get_auditor_lock_threshold() + 1)))
	GameState.null_walker_stirred.connect(func(m): _update_ui(m))
	GameState.rollback_tick.connect(_on_rollback_tick)
	win_panel.visible = false
	pause_panel.visible = false
	history_label.visible = show_history
	_apply_atmosphere()
	_setup_compositor()
	_setup_tag_layer()
	_rebuild_visuals()
	_update_all()
	_set_history()
	_update_ui("Press E to SCAN.")
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
	# Both layer viewports render the same graph world (own_world_3d off) through
	# cameras with the Necropolis / Vesper environments, at the window's size.
	# With their own empty worlds the compositor painted over the graph and the
	# player could not see anything to SNAP.
	_fit_layer_viewports()
	get_viewport().size_changed.connect(_fit_layer_viewports)
	compositor_mat = ShaderMaterial.new()
	compositor_mat.shader = shader
	# A ViewportTexture built with viewport_path at runtime never binds to its
	# SubViewport, so the shader sampled the missing-texture fallback (solid
	# magenta). get_texture() returns the bound render target.
	var tex0: ViewportTexture = sv_l0.get_texture()
	var tex1: ViewportTexture = sv_l1.get_texture()
	compositor_mat.set_shader_parameter("layer0_tex", tex0)
	compositor_mat.set_shader_parameter("layer1_tex", tex1)
	compositor_mat.set_shader_parameter("bleed_intensity", 0.12 + GameState.get_district().threat * 0.1)
	compositor_mat.set_shader_parameter("violet_seam", Color(0.82, 0.35, 1.0))
	compositor_rect.material = compositor_mat

func _fit_layer_viewports() -> void:
	var sz := Vector2i(get_viewport().get_visible_rect().size)
	if sz.x > 0 and sz.y > 0:
		sv_l0.size = sz
		sv_l1.size = sz

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
	# Translucent violet: at full emission the seam was an opaque white wall that
	# hid the centre node and cut through the win panel.
	var seam_mat := StandardMaterial3D.new()
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	seam_mat.albedo_color = Color(0.85, 0.35, 1.0, 0.3)
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
					_update_all()
					_update_ui("Press E to SCAN.")
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
		_set_history()
		_update_ui("Run reset to district 1. Press E to SCAN.")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_node(event.position)

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
	GameState.set_kernel(int(data.get("current_kernel", 0)))
	GameState.rooms_completed = int(data.get("rooms_completed", 0))
	GameState.scanned = bool(data.get("scanned", false))
	GameState.gate_is_open = bool(data.get("gate_is_open", false))
	# JSON gives untyped arrays and float numbers; GameState's arrays are typed
	# Array[Dictionary] and the graph code compares integer ids.
	var edges: Array[Dictionary] = []
	for e in data.get("edges", []):
		if typeof(e) == TYPE_DICTIONARY:
			edges.append({"from": int(e.get("from", 0)), "to": int(e.get("to", 0)), "strength": float(e.get("strength", 1.0)), "corrupted": bool(e.get("corrupted", false))})
	GameState.edges = edges
	var hist: Array[Dictionary] = []
	for r in data.get("history", []):
		if typeof(r) == TYPE_DICTIONARY:
			hist.append({"frame": int(r.get("frame", 0)), "seq": int(r.get("seq", 0)), "priority": int(r.get("priority", 0)), "op": str(r.get("op", "")), "node": int(r.get("node", -1)), "edge": int(r.get("edge", -1)), "payload": []})
	GameState.history = hist
	GameState.snap_count = edges.size()
	GameState.last_path_nodes = []
	for id in data.get("last_path", []):
		GameState.last_path_nodes.append(int(id))
	var locked: Array = []
	for id in data.get("nodes_locked", []):
		locked.append(int(id))
	for n in GameState.nodes:
		n.locked = n.id in locked
		n.revealed = GameState.scanned
	GameState.auditor_active = not locked.is_empty()
	if GameState.gate_is_open and GameState.nodes.size() > 3 and not str(GameState.nodes[3].label).ends_with("_OPEN"):
		GameState.nodes[3]["label"] = str(GameState.nodes[3].label) + "_OPEN"
	selected_node = -1
	demo_complete = GameState.gate_is_open
	auditor_mesh.visible = GameState.auditor_active
	sable_mesh.visible = GameState.gate_is_open
	win_panel.visible = GameState.gate_is_open
	bleed_seam.visible = GameState.scanned
	GameState.graph_changed.emit()
	_update_all()
	_set_history()
	_update_ui("Loaded.")

func _do_scan() -> void:
	if GameState.scanned:
		return
	GameState.begin_frame()
	GameState.log_mutation("SCAN", 0, -1, [], 0)
	if GameState.commit_frame():
		_clear_selection()
		_set_bleed(0.3 + GameState.get_district().threat * 0.35)
		_update_ui("SCAN: graph revealed. Click two nodes to SNAP them.")
		_update_objective()
		_update_hash_ui()

func _try_select_node(screen_pos: Vector2) -> void:
	if not GameState.scanned:
		_update_ui("SCAN first.")
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * 100.0))
	if result.is_empty():
		return
	var c = result.collider
	if c and c.has_meta("node_id"):
		var id: int = c.get_meta("node_id")
		if GameState.nodes[id].locked:
			_update_ui("Node %d is Auditor-locked: it takes no new SNAPs." % id)
			return
		if selected_node == -1:
			selected_node = id
			_update_ui("Selected [%d] %s. Click a second node to SNAP." % [id, str(GameState.nodes[id].label).replace("_", " ")])
			_rebuild_visuals()
		elif selected_node != id:
			var from_id := selected_node
			selected_node = -1
			_do_snap(from_id, id)
			_rebuild_visuals()
		else:
			selected_node = -1
			_update_ui("Deselected [%d]." % id)
			_rebuild_visuals()

func _do_snap(a: int, b: int) -> void:
	# a = first click, b = second click; the readout keeps that order.
	var edges_before := GameState.edges.size()
	var auditor_before := GameState.auditor_active
	var walker_before := GameState.null_walker_fired
	var lock_target := -1
	GameState.begin_frame()
	GameState.log_mutation("SNAP", a, b, [], 0)
	if GameState.snap_count >= GameState.get_auditor_lock_threshold() and not GameState.auditor_active:
		lock_target = GameState.pick_auditor_lock_target()
		if lock_target >= 0:
			GameState.log_mutation("AUD_LOCK", lock_target, -1, [], 2)
	if GameState.commit_frame():
		var parts: PackedStringArray = []
		if GameState.edges.size() > edges_before or GameState.null_walker_fired != walker_before:
			parts.append("SNAP %d → %d" % [a, b])
		else:
			parts.append("%d and %d are already linked." % [a, b])
		if GameState.auditor_active and not auditor_before and lock_target >= 0:
			parts.append(_lock_text(lock_target))
		if GameState.null_walker_fired and not walker_before:
			parts.append("NULL WALKER removed an edge.")
		_update_ui(" | ".join(parts))
		_update_objective()

func _do_sunder() -> void:
	_clear_selection()
	if GameState.edges.is_empty():
		_update_ui("Nothing to SUNDER. SCAN, then SNAP a path 0 → 3." if not GameState.scanned else "Nothing to SUNDER. SNAP a path 0 → 3 first.")
		return
	GameState.begin_frame()
	GameState.log_mutation("SUNDER", 0, -1, [], 0)
	if GameState.commit_frame():
		_update_objective()

## What a lock does (GameState): SNAPs touching a locked node are refused,
## but edges it already has stay and still count for the 0 → 3 path.
func _lock_text(id: int) -> String:
	return "AUDITOR locked node %d: no new SNAPs to it (its links still count)." % id

func _on_auditor() -> void:
	auditor_mesh.visible = true

func _on_rollback_tick(s: int) -> void:
	if s <= 0:
		# GameState has just wiped this district's edges (the 47 s pattern cage).
		_clear_selection()
		_update_ui("ROLLBACK: the 47s loop reset. Your SNAPs were wiped; the timer restarts.")
	_update_hash_ui.call_deferred()

func _clear_selection() -> void:
	if selected_node != -1:
		selected_node = -1
		_rebuild_visuals()

func _on_win() -> void:
	demo_complete = true
	_update_room_ui()
	_update_hash_ui()
	sable_mesh.visible = true
	win_panel.visible = true
	_set_bleed(0.75)
	var line := GameState.last_sable_line
	# The Sable line lives on the win panel only.
	_update_ui("SUNDER: gate open.")
	var wl = win_panel.get_node_or_null("WinLabel")
	if wl:
		wl.text = "%s REWRITTEN\nSable: \"%s\"\nN = next | F5 = save" % [GameState.get_district_name(), line]

func _on_room_changed(_id: int) -> void:
	_update_all()
	bleed_seam.visible = false

func _on_committed(_f: int, _h: int) -> void:
	_update_hash_ui()
	_set_history()

## The frame hash is a signed 64-bit int; fold it to 32 bits of hex for display.
static func short_hash(h: int) -> String:
	return "%08x" % ((h ^ (h >> 32)) & 0xFFFFFFFF)

## One line, rebuilt from state on every commit, tick, reset, load and N, so a
## stale Rollback readout can never survive leaving district 4.
func _update_hash_ui() -> void:
	var parts: PackedStringArray = []
	if GameState.is_rollback_district() and not GameState.gate_is_open:
		if GameState.scanned:
			parts.append("ROLLBACK %ds" % GameState.rollback_left)
		else:
			parts.append("ROLLBACK %ds (starts at SCAN)" % GameState.rollback_left)
	parts.append("Log hash %s" % (short_hash(GameState.last_hash) if GameState.frame_id > 0 else "--------"))
	parts.append("Edges %d" % GameState.edges.size())
	hash_label.text = " | ".join(parts)

func _set_history() -> void:
	history_label.text = "History:\n" + GameState.get_history_summary()
	# Shrink the backing panel back to the text after a reset.
	history_label.size = Vector2.ZERO

func _update_ui(msg: String) -> void:
	status_label.text = msg

func _update_objective() -> void:
	if GameState.gate_is_open:
		objective_label.text = "Objective complete."
	else:
		objective_label.text = "Objective: link 0 (START) to 3 (GATE), then SPACE to SUNDER."

func _update_kernel_ui() -> void:
	kernel_label.text = "Kernel: %s" % GameState.get_kernel_name()

func _update_room_ui() -> void:
	var d = GameState.get_district()
	room_label.text = "%s (%d/6): %s\nThreat %d%% | Cleared %d | Intel: %s" % [d.name, GameState.current_room, d.blurb, int(d.threat * 100), GameState.rooms_completed, GameState.get_intel()]

func _update_all() -> void:
	_update_objective()
	_update_kernel_ui()
	_update_room_ui()
	_update_hash_ui()

func _rebuild_visuals() -> void:
	for c in node_container.get_children():
		c.queue_free()
	for c in edge_container.get_children():
		c.queue_free()
	_rebuild_tags()
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
		if n.id == selected_node:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.85, 0.3)
			mat.emission_energy_multiplier = 4.0
		mi.material_override = mat
		mi.position = vis_pos(n.id)
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
		var a: Vector3 = vis_pos(e.from)
		var b: Vector3 = vis_pos(e.to)
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
		# look_at needs the node in the tree; before add_child it errors and the
		# beam stays a vertical post instead of spanning the two spheres.
		edge_container.add_child(mi)
		mi.position = (a + b) / 2.0
		if a.distance_to(b) > 0.001:
			mi.look_at(mi.global_position + (b - a), Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.FORWARD)
			mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _setup_tag_layer() -> void:
	tag_layer = Control.new()
	tag_layer.name = "NodeTags"
	tag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ui := compositor_rect.get_parent()
	ui.add_child(tag_layer)
	# Above the composited 3D image, below the HUD text and panels.
	ui.move_child(tag_layer, compositor_rect.get_index() + 1)
	get_viewport().size_changed.connect(func(): _layout_tags.call_deferred())

func _tag_text(n: Dictionary, with_lock: bool) -> String:
	var role := ""
	if n.id == 0:
		role = "  START"
	elif n.id == 3:
		role = "  GATE"
	var t := "%d  %s%s" % [n.id, str(n.label).trim_suffix("_OPEN").replace("_", " "), role]
	if with_lock:
		t += "  LOCKED"
	return t

func _rebuild_tags() -> void:
	if tag_layer == null:
		return
	for c in tag_layer.get_children():
		tag_layer.remove_child(c)
		c.queue_free()
	for n in GameState.nodes:
		var lbl := Label.new()
		lbl.name = "Tag%d" % n.id
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", TAG_FONT_SIZE)
		var accent := Color(0.62, 0.32, 0.9)
		var fg := Color(0.95, 0.92, 1.0)
		if n.locked:
			accent = Color(1.0, 0.3, 0.35)
		if str(n.label).ends_with("_OPEN"):
			accent = Color(0.35, 1.0, 0.6)
		if n.id == selected_node:
			accent = Color(1.0, 0.85, 0.3)
			fg = Color(1.0, 0.88, 0.45)
		lbl.add_theme_color_override("font_color", fg)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.015, 0.07, 0.82)
		sb.border_color = accent
		sb.set_border_width_all(1)
		sb.border_width_left = 3
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 7
		sb.content_margin_right = 6
		sb.content_margin_top = 1
		sb.content_margin_bottom = 2
		lbl.add_theme_stylebox_override("normal", sb)
		# Measure with the LOCKED suffix reserved (0 and 3 are never locked) so
		# an Auditor lock does not move tags around mid-puzzle.
		lbl.text = _tag_text(n, n.id != 0 and n.id != 3)
		lbl.set_meta("reserve_size", lbl.get_minimum_size())
		lbl.text = _tag_text(n, n.locked)
		lbl.size = lbl.get_minimum_size()
		lbl.set_meta("node_id", n.id)
		tag_layer.add_child(lbl)
	_layout_tags()

static func _rect_circle_overlap(r: Rect2, c: Vector2, rad: float) -> float:
	var px := clampf(c.x, r.position.x, r.end.x)
	var py := clampf(c.y, r.position.y, r.end.y)
	var d := Vector2(px, py).distance_to(c)
	return maxf(0.0, rad - d)

static func _rect_overlap_area(a: Rect2, b: Rect2) -> float:
	var i := a.intersection(b)
	return i.get_area() if a.intersects(b) else 0.0

## Greedy screen-space placement with a few relaxation passes. Candidates sit
## around each sphere; cost penalises overlapping other tags, other spheres,
## the HUD text column, the footer, the win panel and the screen edge.
func _layout_tags() -> void:
	tag_rects.clear()
	tag_circles.clear()
	if tag_layer == null or cam_main == null or not is_inside_tree():
		return
	var vp := get_viewport().get_visible_rect().size
	var screen := Rect2(Vector2(4, 4), vp - Vector2(8, 8))
	var right := cam_main.global_transform.basis.x
	var labels: Array = []
	for c in tag_layer.get_children():
		if c.has_meta("node_id"):
			labels.append(c)
	for lbl in labels:
		var id: int = lbl.get_meta("node_id")
		var c2 := cam_main.unproject_position(vis_pos(id))
		var edge2 := cam_main.unproject_position(vis_pos(id) + right * 0.38)
		tag_circles[id] = Vector3(c2.x, c2.y, c2.distance_to(edge2))
	var obstacles: Array[Rect2] = [
		Rect2(0, 0, vp.x, 178),                       # status / objective / hash / kernel / district lines
		Rect2(0, 178, 240, 196),                      # History column (8 lines)
		Rect2(0, vp.y - 50, vp.x, 50),                # footer hint bar
		Rect2(vp.x * 0.5 - 245, vp.y - 195, 490, 150),  # win panel
	]
	var chosen: Dictionary = {}
	for pass_i in 4:
		for lbl in labels:
			var id: int = lbl.get_meta("node_id")
			var s: Vector2 = lbl.get_meta("reserve_size")
			var ci: Vector3 = tag_circles[id]
			var c := Vector2(ci.x, ci.y)
			var r := ci.z + TAG_GAP
			var cands: Array[Rect2] = [
				Rect2(c.x - s.x * 0.5, c.y - r - s.y, s.x, s.y),         # above
				Rect2(c.x - s.x * 0.5, c.y + r, s.x, s.y),               # below
				Rect2(c.x + r, c.y - s.y * 0.5, s.x, s.y),               # right
				Rect2(c.x - r - s.x, c.y - s.y * 0.5, s.x, s.y),         # left
				Rect2(c.x - s.x * 0.15, c.y - r - s.y, s.x, s.y),        # above, leaning right
				Rect2(c.x - s.x * 0.85, c.y - r - s.y, s.x, s.y),        # above, leaning left
				Rect2(c.x - s.x * 0.15, c.y + r, s.x, s.y),              # below, leaning right
				Rect2(c.x - s.x * 0.85, c.y + r, s.x, s.y),              # below, leaning left
				Rect2(c.x - s.x * 0.5, c.y - r - s.y * 2.2, s.x, s.y),   # high above
				Rect2(c.x - s.x * 0.5, c.y + r + s.y * 1.2, s.x, s.y),   # low below
			]
			var best := cands[0]
			var best_cost := INF
			for k in cands.size():
				var rc: Rect2 = cands[k]
				var cost := float(k) * 2.0
				for oid in chosen:
					if oid != id:
						cost += _rect_overlap_area(rc.grow(3.0), chosen[oid]) * 40.0
				for oid in tag_circles:
					var oc: Vector3 = tag_circles[oid]
					cost += _rect_circle_overlap(rc.grow(2.0), Vector2(oc.x, oc.y), oc.z) * (400.0 if oid != id else 800.0)
					# A tag must read as belonging to its own sphere, not a neighbour.
					if oid != id and rc.get_center().distance_to(Vector2(oc.x, oc.y)) < rc.get_center().distance_to(c) + 8.0:
						cost += 300.0
				for ob in obstacles:
					cost += _rect_overlap_area(rc, ob) * 8.0
				cost += (rc.get_area() - _rect_overlap_area(rc, screen)) * 50.0
				if cost < best_cost:
					best_cost = cost
					best = rc
			chosen[id] = best
	for lbl in labels:
		var id: int = lbl.get_meta("node_id")
		var rc: Rect2 = chosen[id]
		lbl.size = lbl.get_minimum_size()
		# Keep the actual (possibly shorter) tag on the sphere side of its slot.
		var ci: Vector3 = tag_circles[id]
		var pos := rc.position
		var dx := rc.get_center().x - ci.x
		if dx < -rc.size.x * 0.25:
			pos.x = rc.end.x - lbl.size.x
		elif dx <= rc.size.x * 0.25:
			pos.x = rc.get_center().x - lbl.size.x * 0.5
		lbl.position = pos.round()
		tag_rects[id] = Rect2(lbl.position, lbl.size)
