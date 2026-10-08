# Project Cold Boot — QA completion pass

**Date:** 2026-10-08 (America/New_York)
**Branch:** `fix/coldboot-playtest-pass`
**Scope:** the existing Claim-0 vertical slice (main menu, six districts, SCAN → SNAP → SUNDER, kernels, Auditor lock, Rollback timer, Null Walker, F5/F9 save). No new mechanics.
**Status:** IN PROGRESS. Every district clears with real input events on the real scenes. A first human mouse-and-keyboard session (2026-10-08) found seven HUD and readability bugs, all fixed below. Still open: a second human pass to confirm the fixes, and a Vulkan (Forward+) render check.

## How this was run

```bash
# Godot 4.2.2 (project target). 4.7.2 passed the earlier 47-check driver; not re-run for the hand-playtest slice.
godot --headless --path godot -s res://tools/smoke_test.gd          # 28/28
godot --headless --path godot -s res://tools/play_driver.gd         # 123/123
# Windowed on the real renderer, with screenshots (this box has no Vulkan,
# so it uses the GL compatibility renderer on Mesa llvmpipe):
godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
      --resolution 1280x720 -s res://tools/play_driver.gd -- --shots=/tmp/shots   # 123/123
python3 -m unittest discover -s tests                               # 5/5
```

`godot/tools/play_driver.gd` is new. It boots `MainMenu`, presses **Enter the Manuscript**, and plays `VerticalSlice` by pushing real key and mouse events into the viewport. Clicks land on each sphere's projected screen position and go through the game's own raycast picking. It covers: click before SCAN, Esc pause and unpause, a wrong path plus SUNDER, a two-hop path through an Auditor lock, N to the next district, F5 mid-room then R then F9, the Rollback district, the Null Walker breaking a path in districts 5 and 6 (and the re-draw), and N after The Sink wrapping to district 1 with all six cleared. Since the hand playtest it also covers: SPACE with no SNAPs, SUNDER dropping a pending selection, the SNAP readout in click order, the Auditor lock message, the Rollback timer running out, R and F9 refreshing the Rollback line, the short hex log hash, each HUD fact shown once, and node tags not overlapping each other or any sphere in all six districts.

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

## Hand playtest 2026-10-08

A person played the build on the desktop (windowed, GL compatibility, 1280×720) with a real mouse and keyboard. They cleared districts 1–4 with 0 missed clicks. Esc pause, F5, R and F9 all worked. What they reported, and what changed:

| # | Finding | Root cause | Fix |
|---|---------|------------|-----|
| H1 | After **R**, the top-right line still read `ROLLBACK 27s \| Rollback District` on Compiler Heights. | Only the Rollback tick wrote that line. Commits outside district 4 skipped it, and R, F9 and N never rebuilt it. | One `_update_hash_ui()` builds the line from state. It runs on every commit, tick, R, F9, N and win. The district name moved off that line. Driver checks R from district 4, F9 back into it, and N out of it. |
| H2 | The objective appeared twice on entry (`Compiler Heights. E = SCAN…` and `Compiler Heights: 0 → 3 then SUNDER…`). After a clear, `X clear. Sable: …` appeared twice. | The status line, objective line, room line and win panel each restated the district, intel or Sable line. | Each line has one job. Status is events and the next step (`Press E to SCAN.`). Objective is the rule (`link 0 (START) to 3 (GATE), then SPACE to SUNDER`). The district line holds the name, blurb, threat, cleared count and intel. The Sable line appears only on the win panel. Threat is no longer repeated on the hash line. The driver asserts that the district name and Sable line each appear once. |
| H3 | Node tags collided. `1 Security Grid LOCKED` sat on `0 Orpheus Lamp START`. In Ghost Rail, `1 Nowhere Track` and `2 Yesterday Car LOCKED` merged into one line. Beams ran through the text. | Fixed-offset `Label3D` billboards: wide 40 px text centred over each sphere, with nothing to keep them apart. | Tags are now small 2D labels on the HUD layer with a dark backing and an accent edge (violet, red when LOCKED, green when open, amber when selected). Each tag is placed in screen space around its sphere, away from other tags, other spheres, the HUD column, the footer and the win panel. The width for LOCKED is reserved so tags do not move when a lock fires. Beams pass under the backing. The driver asserts that no tag overlaps another tag or a sphere in all six districts, both after SCAN and after the clear. |
| H4 | The SNAP readout showed `SNAP 1 → 0` after the player clicked 0 then 1. | The format string was already in click order, and the reversed string could not be reproduced with clean clicks. The likely cause: a pending selection survived SUNDER, SCAN, kernel switches and Rollback expiry, so the next click completed a pair with the old node first. Also, an Auditor lock in the same commit overwrote the SNAP readout. | `_do_snap` writes the readout from the two clicks, with any lock or Null Walker message from the same commit added after it. SUNDER, SCAN, kernel switches and Rollback expiry clear a pending selection. The driver checks the readout for every SNAP, including a second-node-first `3 → 1`, and checks that SUNDER drops a pending selection. |
| H5 | The footer hints and the grey History list were hard to read on the purple. | Grey text (0.55) with no backing over the moving bleed. | Footer: a full-width dark strip with light lavender text. History: a dark violet-edged panel sized to its text, with light text. All HUD lines have a thin dark outline. The palette is unchanged. |
| H6 | `Hash -6529713557505234271` looked like debug output. | The raw signed 64-bit frame hash was printed. | The hash is computed the same way. It is shown as `Log hash 22b8e6bc` (64 bits XOR-folded to 32-bit hex). The driver asserts the format. |
| H7 | `AUDITOR lock (bias active).` explained nothing. | The message described the targeting bias, not the effect. In `GameState`, a SNAP that touches a locked node is refused, but the edges the node already has stay and still count for the 0 → 3 path. | The message now reads: `AUDITOR locked node N: no new SNAPs to it (its links still count).` Clicking a locked node says `Node N is Auditor-locked: it takes no new SNAPs.` The rule is unchanged. |

Optional checks from the brief:

- **Rollback timer expiry (district 4):** the rule worked, with edges wiped and the timer back to 47. But nothing on screen said so, and a pending selection survived. The expiry now says `ROLLBACK: the 47s loop reset…`, clears the selection, and redraws the timer line. Driver covered.
- **Wrong SPACE:** with an invalid path, SPACE already said `Path incomplete.`, which now adds `Link 0 to 3, then SUNDER.` With no SNAPs at all, SPACE silently did nothing. It now says `Nothing to SUNDER…`. Driver covered.

Not changed, by design: any-two-node SNAP (direct 0 → 3 is possible), R resetting the whole run, and the centre seam and drifting pills. Tags and HUD now draw above the seam and pills, so these no longer hide text.

Screenshots after the fixes: `docs/images/qa/room1_start.png` (district 1 after SCAN), `docs/images/qa/room3_ghost_rail_win.png` (Ghost Rail tags, Auditor lock), `docs/images/qa/room6_win.png` (The Sink, seven nodes).

## Played (scripted, real events, windowed)

| District | Result |
|----------|--------|
| 1 Compiler Heights | Wrong path then SUNDER → `Path incomplete.`; 0→1→3 with Auditor lock on node 1 → gate open |
| 2 Static Market | Scan + one SNAP, F5, R (back to district 1), F9 → district 2 restored with the edge; finished after load |
| 3 Ghost Rail | 0→1→2→3, clear |
| 4 Rollback District | Rollback timer counts on the HUD (`ROLLBACK 42s`). The timer is run out: SNAPs wiped, readout restarts. F5, R (the Rollback line clears on Compiler Heights), F9 (it returns). Then cleared. |
| 5 Dead Repository | Null Walker removed an edge → `Path incomplete.`; redrawn → clear |
| 6 The Sink | Same as 5 → clear; N wraps to district 1, six cleared |

Screenshots: `docs/images/qa/room1_start.png`, `docs/images/qa/room3_ghost_rail_win.png`, `docs/images/qa/room6_win.png`.

## Still open

1. **Second human pass.** A person needs to confirm H1–H7 on the desktop: tags readable and apart in all six districts, the HUD lines, contrast, and the SNAP order. The first pass covered districts 1–4 only, so districts 5–6 also need human eyes.
2. **Forward+ / Vulkan render.** This box has no Vulkan driver. Fixes 3 and 5 and the new tag layer were checked on the GL compatibility renderer only.
3. **Puzzle depth (design call, not changed).** Any two nodes can be SNAPped, and the Auditor never locks 0 or 3, so a direct 0→3 SNAP clears every district. Constraining SNAPs would be new design.
4. **R resets the whole run** to district 1 (by design in `reset_demo`). There is no "restart this district".
5. Volume and sensitivity sliders are not persisted between launches. There is no audio in the slice.

## Status

**IN PROGRESS.** Not `COMPLETE — PLAYTEST VERIFIED`.
