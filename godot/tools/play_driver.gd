extends SceneTree
## Scripted playthrough of the real scenes with real input events.
## Boots MainMenu, presses Play, then drives VerticalSlice through all six
## districts with key presses and mouse clicks on the projected node spheres.
## Also exercises Esc pause/unpause, F5/F9 save/load, R reset, wrong-path SUNDER.
## Run windowed (screenshots) or headless:
##   godot --path godot -s res://tools/play_driver.gd -- [--shots=/tmp/dir]
## Exit 0 = every check passed.

var _fail: PackedStringArray = []
var _pass := 0
var _shots := ""
var gs: Node
var vs: Node

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots = a.substr(8)
	_run.call_deferred()

func ok(c: bool, m: String) -> void:
	if c:
		_pass += 1
		print("PASS: ", m)
	else:
		_fail.append(m)
		print("FAIL: ", m)

func frames(n: int = 3) -> void:
	for i in n:
		await process_frame

func key(code: Key) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = p
		root.push_input(e, true)
		await frames(2)

func click_node(id: int) -> void:
	# Spheres are rebuilt on every graph change; let physics register them,
	# as a human's reaction time always does.
	for i in 3:
		await physics_frame
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var p: Vector2 = cam.unproject_position(vs.vis_pos(id))
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	root.push_input(mm, true)
	await frames(2)
	for pr in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p
		e.global_position = p
		e.pressed = pr
		root.push_input(e, true)
		await frames(3)

func shot(name: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	await frames(4)
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shots)
	img.save_png("%s/%s.png" % [_shots, name])

func status() -> String:
	return vs.status_label.text

func clear_room(path: Array, label: String) -> void:
	await key(KEY_E)
	ok(gs.scanned, "%s: SCAN reveals graph" % label)
	for i in range(path.size() - 1):
		await click_node(path[i])
		await click_node(path[i + 1])
	await key(KEY_SPACE)
	if not gs.gate_is_open and gs.null_walker_fired:
		# Dead Repository / The Sink: the Null Walker strips one edge. Re-draw it.
		ok(status() == "Path incomplete.", "%s: Null Walker break reads 'Path incomplete.'" % label)
		for i in range(path.size() - 1):
			await click_node(path[i])
			await click_node(path[i + 1])
		await key(KEY_SPACE)
	ok(gs.null_walker_fired == (gs.current_room >= 5), "%s: Null Walker fires only in rooms 5-6" % label)
	ok(gs.gate_is_open, "%s: path %s + SUNDER opens gate (status '%s')" % [label, str(path), status()])
	for e in vs.edge_container.get_children():
		ok(absf(e.global_transform.basis.y.normalized().y) < 0.2, "%s: edge beam lies flat between spheres" % label)
		break
	ok(vs.win_panel.visible, "%s: win panel shows" % label)
	ok(vs.room_label.text.contains("Cleared %d" % gs.rooms_completed), "%s: HUD cleared count is current (%d)" % [label, gs.rooms_completed])

func _run() -> void:
	print("=== Project Cold Boot play_driver (", DisplayServer.get_name(), ") ===")
	gs = root.get_node("/root/GameState")
	change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	await frames(10)
	ok(current_scene != null and current_scene.name == "MainMenu", "boots MainMenu")
	await shot("00_menu")
	current_scene.get_node("PlayButton").pressed.emit()
	await frames(15)
	vs = current_scene
	ok(vs != null and vs.name == "VerticalSlice", "Play enters VerticalSlice")
	await shot("01_room1_start")

	# Click before SCAN is refused.
	await click_node(0)
	ok(status() == "SCAN first.", "click before SCAN says 'SCAN first.'")

	# Pause and unpause.
	await key(KEY_ESCAPE)
	ok(paused and vs.pause_panel.visible, "Esc pauses")
	await key(KEY_ESCAPE)
	ok(not paused and not vs.pause_panel.visible, "Esc again unpauses")
	if paused:
		paused = false

	# Wrong path: SUNDER with an edge that misses the gate.
	await key(KEY_E)
	await click_node(0)
	await click_node(1)
	ok(gs.edges.size() == 1, "room 1: click-click SNAP makes one edge (edges=%d)" % gs.edges.size())
	await key(KEY_SPACE)
	ok(not gs.gate_is_open, "room 1: SUNDER without a path keeps the gate shut")
	ok(status() == "Path incomplete.", "room 1: incomplete SUNDER says so (status '%s')" % status())
	await click_node(1)
	await click_node(3)
	await key(KEY_SPACE)
	ok(gs.gate_is_open, "room 1: 0→1→3 + SUNDER opens gate (status '%s', locked=%s)" % [status(), str(gs.nodes.map(func(n): return n.locked))])
	await shot("02_room1_win")
	await key(KEY_N)
	ok(gs.current_room == 2 and not vs.win_panel.visible, "N advances to room 2")

	# Save mid-room, reset, load.
	await key(KEY_E)
	await click_node(0)
	await click_node(1)
	var saved_edges: int = gs.edges.size()
	await key(KEY_F5)
	ok(status() == "Saved.", "F5 saves")
	await key(KEY_R)
	ok(gs.current_room == 1 and gs.edges.is_empty(), "R resets the run")
	await key(KEY_F9)
	ok(status() == "Loaded.", "F9 loads (status '%s')" % status())
	ok(gs.current_room == 2 and gs.edges.size() == saved_edges and gs.scanned, "load restores room 2, scan, edges (room=%d edges=%d)" % [gs.current_room, gs.edges.size()])
	await click_node(1)
	await click_node(3)
	await key(KEY_SPACE)
	ok(gs.gate_is_open, "room 2: finish after load (status '%s')" % status())
	await key(KEY_N)

	# Rooms 3–6.
	for r in [3, 4, 5, 6]:
		ok(gs.current_room == r, "now in room %d" % r)
		var path := [0, 1, 2, 3]
		await clear_room(path, "room %d" % r)
		await shot("%02d_room%d_win" % [r, r])
		await key(KEY_N)
	ok(gs.current_room == 1, "N after The Sink wraps to room 1")
	ok(gs.rooms_completed >= 6, "rooms_completed counts all six (=%d)" % gs.rooms_completed)

	print("=== results: %d passed, %d failed ===" % [_pass, _fail.size()])
	for f in _fail:
		print("  FAILED: ", f)
	quit(0 if _fail.is_empty() else 1)
