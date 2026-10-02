extends SceneTree
## Headless smoke: load GameState autoload and exercise SCAN → SNAP → SUNDER.
## Run from repo root:
##   godot --headless --path godot -s res://tools/smoke_test.gd
## Exit 0 = all assertions passed; non-zero = failure.

var _failures: PackedStringArray = []
var _passed: int = 0
var _ran: bool = false

func _init() -> void:
	call_deferred("_run")

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: ", msg)
	else:
		_failures.append(msg)
		print("FAIL: ", msg)

func _run() -> void:
	if _ran:
		return
	_ran = true
	print("=== Project Cold Boot smoke_test ===")

	var gs: Node = root.get_node_or_null("/root/GameState")
	_assert(gs != null, "GameState autoload present")
	if gs == null:
		_finish(2)
		return

	# Fresh room 1 graph
	gs.call("reset_demo")
	_assert(int(gs.get("current_room")) == 1, "starts in room 1")
	_assert(int(gs.get("nodes").size()) == 5, "room 1 has 5 nodes")
	_assert(bool(gs.get("scanned")) == false, "not scanned yet")
	_assert(int(gs.get("edges").size()) == 0, "no edges yet")

	# SCAN
	gs.call("begin_frame")
	gs.call("log_mutation", "SCAN", 0, -1, [], 0)
	_assert(bool(gs.call("commit_frame")) == true, "SCAN commit ok")
	_assert(bool(gs.get("scanned")) == true, "scanned after SCAN")
	_assert(bool(gs.get("nodes")[0]["revealed"]) == true, "node 0 revealed")

	# Path 0→1→3 via SNAP (room 1: Orpheus→Security→Core_Gate)
	gs.call("begin_frame")
	gs.call("log_mutation", "SNAP", 0, 1, [], 0)
	_assert(bool(gs.call("commit_frame")) == true, "SNAP 0→1 commit ok")
	_assert(int(gs.get("edges").size()) == 1, "one edge after first SNAP")

	gs.call("begin_frame")
	gs.call("log_mutation", "SNAP", 1, 3, [], 0)
	# Auditor may lock on threshold; still must commit
	_assert(bool(gs.call("commit_frame")) == true, "SNAP 1→3 commit ok")
	_assert(int(gs.get("edges").size()) >= 2, "at least two edges for path 0→3")

	_assert(bool(gs.call("_has_path", 0, 3)) == true, "path 0→3 exists")

	# SUNDER opens gate when path exists
	gs.call("begin_frame")
	gs.call("log_mutation", "SUNDER", 0, -1, [], 0)
	_assert(bool(gs.call("commit_frame")) == true, "SUNDER commit ok")
	_assert(bool(gs.get("gate_is_open")) == true, "gate open after SUNDER")
	_assert(int(gs.get("rooms_completed")) >= 1, "rooms_completed incremented")
	_assert(int(gs.get("last_hash")) != 0, "frame hash non-zero")

	# District / kernel API sanity
	_assert(str(gs.call("get_district_name")) == "Compiler Heights", "district name room 1")
	gs.call("set_kernel", 2)  # KEEP_DRAFTING
	_assert(str(gs.call("get_kernel_name")) == "Keep Drafting", "kernel name Keep Drafting")

	# Room transition
	gs.call("go_to_room", 4)
	_assert(int(gs.get("current_room")) == 4, "go_to_room 4")
	_assert(bool(gs.call("is_rollback_district")) == true, "room 4 is rollback district")
	_assert(bool(gs.get("scanned")) == false, "scan cleared on room change")

	# Main menu + vertical slice scripts parse/load
	var menu_script: Resource = load("res://scripts/main_menu/MainMenu.gd")
	var slice_script: Resource = load("res://scripts/vertical_slice/VerticalSlice.gd")
	var compositor: Resource = load("res://shaders/domain_warp_compositor.gdshader")
	var noise_shader: Resource = load("res://shaders/domain_warp_noise.gdshader")
	_assert(menu_script != null, "MainMenu.gd loads")
	_assert(slice_script != null, "VerticalSlice.gd loads")
	_assert(compositor != null, "domain_warp_compositor.gdshader loads")
	_assert(noise_shader != null, "domain_warp_noise.gdshader loads")

	# Scenes resolve
	var menu_scene: PackedScene = load("res://scenes/main_menu/MainMenu.tscn")
	var slice_scene: PackedScene = load("res://scenes/vertical_slice/VerticalSlice.tscn")
	_assert(menu_scene != null, "MainMenu.tscn loads")
	_assert(slice_scene != null, "VerticalSlice.tscn loads")

	_finish(0 if _failures.is_empty() else 1)

func _finish(code: int) -> void:
	print("=== results: %d passed, %d failed ===" % [_passed, _failures.size()])
	for f in _failures:
		print("  - ", f)
	quit(code)
