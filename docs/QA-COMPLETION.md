# Project Cold Boot — QA completion pass

**Date:** 2026-10-08 (America/New_York)
**Branch:** `fix/coldboot-playtest-pass`
**Scope:** the existing Claim-0 vertical slice (main menu, six districts, SCAN → SNAP → SUNDER, kernels, Auditor lock, Rollback timer, Null Walker, F5/F9 save). No new mechanics.
**Status:** IN PROGRESS — every district clears with real input events on the real scenes and the board is now visible; a human mouse-and-keyboard session and a Vulkan (Forward+) render check are still open.

## How this was run

```bash
# Godot 4.2.2 (project target). 4.7.2 also passes the driver.
godot --headless --path godot -s res://tools/smoke_test.gd          # 28/28
godot --headless --path godot -s res://tools/play_driver.gd         # 47/47
# Windowed on the real renderer, with screenshots (this box has no Vulkan,
# so it uses the GL compatibility renderer on Mesa llvmpipe):
godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
      --resolution 1280x720 -s res://tools/play_driver.gd -- --shots=/tmp/shots   # 47/47
python3 -m unittest discover -s tests                               # 5/5
```

`godot/tools/play_driver.gd` is new. It boots `MainMenu`, presses **Enter the Manuscript**, and plays `VerticalSlice` by pushing real key and mouse events into the viewport. Clicks land on each sphere's projected screen position and go through the game's own raycast picking. It covers: click before SCAN, Esc pause and unpause, a wrong path plus SUNDER, a two-hop path through an Auditor lock, N to the next district, F5 mid-room then R then F9, the Rollback district, the Null Walker breaking a path in districts 5 and 6 (and the re-draw), and N after The Sink wrapping to district 1 with all six cleared.

## Bugs fixed

| # | Bug | Reproduction | Root cause | Fix |
|---|-----|--------------|------------|-----|
| 1 | **Esc soft-locked the game.** Pause could never be undone. | Esc, then Esc. The tree stays paused, and every key is ignored. | `get_tree().paused = true` also paused `VerticalSlice`, the only node that listens for Esc. | `VerticalSlice` runs with `PROCESS_MODE_ALWAYS`. Gameplay is still gated by its own `paused` flag. |
| 2 | **F9 load crashed.** | F5, R, F9: `Invalid set index 'edges' ... with value of type 'Array'`. Nothing restored. | JSON gives untyped arrays of floats; `GameState.edges` and `history` are `Array[Dictionary]`. | Load rebuilds typed arrays with integer ids, restores the kernel through `set_kernel`, the lock / Auditor state, the gate's open label, the seam, and the history text. |
| 3 | **The board was invisible.** A player saw a full-screen magenta wash with white contours and no spheres to click. | Any windowed launch before this pass. | The compositor `ColorRect` paints the whole screen opaquely from two layer viewports. Its `ViewportTexture`s were built with `viewport_path` at runtime and never bound (missing-texture magenta). The two layer viewports also had `own_world_3d`, so even bound they would have rendered empty worlds. | Use `SubViewport.get_texture()`. The layer viewports share the graph world, with the Necropolis / Vesper environments moved onto their cameras, and are sized to the window. |
| 4 | **SNAP beams never showed.** | `look_at` errors `Node not inside tree` on every edge. | `look_at` before `add_child`, and the beams sat at y=0 inside the floor slab (top at y=0.1), which also cut every sphere in half. | Add, then orient. Spheres and beams sit 0.45 above the floor. |
| 5 | **Seam and bleed clipped to white.** A white wall cut through the board and the win panel, and hid the centre node. | Screenshots after fix 3. | Emission ×8 on the seam mesh and an additive ×4.5 seam in the shader on an LDR target. | Seam mesh is translucent violet. The shader blends toward violet instead of adding. Look is unchanged in kind: violet electrical tear. |
| 6 | **The objective says "0 → 3" but nothing was numbered**, and a selected node looked like any other. | Play any district. | No labels. | Each sphere has a billboard tag: number, name, START / GATE / LOCKED. The selected sphere and tag glow amber. Clicking it again deselects. |
| 7 | **"Cleared" lagged one behind** on the win screen. | Clear district 1: HUD says `Cleared 0`. | `rooms_completed` was incremented after `demo_won`, and the room HUD was not refreshed on win. | Increment before the signals; refresh the room line on win. |
| 8 | HUD overlap and panel placement. | History header drew over the intel line; the win panel covered the solved graph. | Fixed offsets. | History moved down 26 px; win panel moved to the bottom centre. |

Click picking now uses the click event's own position rather than `get_mouse_position()`.

## Played (scripted, real events, windowed)

| District | Result |
|----------|--------|
| 1 Compiler Heights | Wrong path then SUNDER → `Path incomplete.`; 0→1→3 with Auditor lock on node 1 → gate open |
| 2 Static Market | Scan + one SNAP, F5, R (back to district 1), F9 → district 2 restored with the edge; finished after load |
| 3 Ghost Rail | 0→1→2→3, clear |
| 4 Rollback District | Rollback timer counts on the HUD (`ROLLBACK 42s`); cleared before reset |
| 5 Dead Repository | Null Walker removed an edge → `Path incomplete.`; redrawn → clear |
| 6 The Sink | Same as 5 → clear; N wraps to district 1, six cleared |

Screenshots: `docs/images/qa/room1_start.png`, `docs/images/qa/room6_win.png`.

## Still open

1. **Human session.** Real mouse and keyboard on the desktop, judging readability and feel. The driver uses real `InputEvent`s through the viewport, but not a person.
2. **Forward+ / Vulkan render.** This box has no Vulkan driver. Fixes 3 and 5 were checked on the GL compatibility renderer only.
3. **Puzzle depth (design call, not changed).** Any two nodes can be SNAPped, and the Auditor never locks 0 or 3, so a direct 0→3 SNAP clears every district. Constraining SNAPs would be new design.
4. **R resets the whole run** to district 1 (by design in `reset_demo`). There is no "restart this district".
5. Volume and sensitivity sliders are not persisted between launches. There is no audio in the slice.

## Status

**IN PROGRESS.** Not `COMPLETE — PLAYTEST VERIFIED`.
