# Project Cold Boot — QA completion pass

**Date:** 2026-10-08 (America/New_York)
**Branch:** `fix/coldboot-playtest-pass`
**Scope:** the existing Claim-0 vertical slice (main menu, six districts, SCAN → SNAP → SUNDER, kernels, Auditor lock, Rollback timer, Null Walker, F5/F9 save). No new mechanics.
**Status:** IN PROGRESS. Every district clears with real input events on the real scenes. Two human mouse-and-keyboard sessions (2026-10-08) found HUD, save/load and readability bugs (H1–H7, then P1–P11), all fixed below. Still open: a short third human pass to confirm the P-fixes on screen, and a Vulkan (Forward+) render check.

## How this was run

```bash
# Godot 4.2.2 (project target). 4.7.2 passed the earlier 47-check driver; not re-run for the hand-playtest slice.
godot --headless --path godot -s res://tools/smoke_test.gd          # 28/28
godot --headless --path godot -s res://tools/play_driver.gd         # 211/211
# Windowed on the real renderer, with screenshots (this box has no Vulkan,
# so it uses the GL compatibility renderer on Mesa llvmpipe):
godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
      --resolution 1280x720 -s res://tools/play_driver.gd -- --shots=/tmp/shots   # 211/211
python3 -m unittest discover -s tests                               # 5/5
```

`godot/tools/play_driver.gd` is new. It boots `MainMenu`, presses **Enter the Manuscript**, and plays `VerticalSlice` by pushing real key and mouse events into the viewport. Clicks land on each sphere's projected screen position and go through the game's own raycast picking. It covers: click before SCAN, Esc pause and unpause, a wrong path plus SUNDER, a two-hop path through an Auditor lock, N to the next district, F5 mid-room then R then F9, the Rollback district, the Null Walker breaking a path in districts 5 and 6 (and the re-draw), and N after The Sink wrapping to district 1 with all six cleared. Since the hand playtest it also covers: SPACE with no SNAPs, SUNDER dropping a pending selection, the SNAP readout in click order, the Auditor lock message, the Rollback timer running out, R and F9 refreshing the Rollback line, the short hex log hash, each HUD fact shown once, and node tags not overlapping each other or any sphere in all six districts. Since hand playtest 2 it also covers: the log hash after F9, the status after E, H and F9, the Null Walker naming the link it took (and the locked endpoint), the 0 → 5 → 3 reroute in districts 5 and 6, History steps in order per district, the dark HUD backing, the Auditor / Sable capsules clear of spheres, tags and beams, spheres and beams drawn after the seam, no beam passing through another sphere, no tag on a beam, and nothing over the PAUSED panel.

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

Not changed, by design: any-two-node SNAP (direct 0 → 3 is possible), R resetting the whole run, and the centre seam and drifting pills. Tags and HUD now draw above the seam and pills, so these no longer hide text. (Hand playtest 2 kept both but changed how they draw: see P7 and P8.)

Screenshots after the fixes (since replaced by the hand-playtest-2 shots of the same names): `docs/images/qa/room1_start.png` (district 1 after SCAN), `docs/images/qa/room3_ghost_rail_win.png` (Ghost Rail tags, Auditor lock), `docs/images/qa/room6_win.png` (The Sink, seven nodes).

## Hand playtest 2 (2026-10-08)

A person played the build again on the desktop (windowed, GL compatibility, 1280×720), this time through all six districts. They cleared all six by hand. F5, R and F9, Esc pause, and H all worked. In districts 5 and 6 the Null Walker broke the path and they rerouted via node 5. N after The Sink wrapped to district 1 with `Cleared 6`. What they reported, and what changed:

| # | Finding | Root cause | Fix |
|---|---------|------------|-----|
| P1 | After **F9** the HUD read `Log hash --------` even though the edge was restored. | Load restored edges, history and locks, but not `frame_id` or `last_hash`. After R, `frame_id` was 0, so the line showed dashes. | The save now stores `frame_id`, the per-district step and `null_walker_fired`. Load restores them and recomputes the hash from the restored state (`GameState.refresh_hash()`). The line shows dashes only until the current district has a commit, so a fresh district no longer shows the last district's hash either. Driver: the hash after F9 equals the hash at F5, and district 2 starts with dashes. |
| P2 | `Loaded.` (and `Saved.`) stayed on the status line through several actions. | A second **E** returned silently, and **H** wrote nothing. | A second E says `Already scanned. Click two nodes to SNAP.` H says `History shown.` / `History hidden (H shows it).` F9 says what to do next (`Loaded. Click two nodes to SNAP.`, or `Press E to SCAN.`, or `Gate open: N…`), and with no save it says `No save yet. F5 saves the run.` Driver covered. |
| P3 | `NULL WALKER removed an edge.` did not say which one. In districts 5 and 6, after 0 → 1 then 1 → 3, it took 0 – 1 while node 1 was being Auditor-locked, so the link could not be redrawn. | The message was fixed text. The lock and the Walker land in the same commit. | `GameState` records the link (`null_walker_link`). The readout says `NULL WALKER removed link 0 – 1. Node 1 is locked: route around it.` The lock hint appears only when an endpoint is locked. The rules are unchanged: 0 and 3 never lock, so it is not a soft-lock. The driver now plays districts 5 and 6 the way the player did. It checks the message, checks that 0 – 1 is refused, and reroutes 0 → 5 → 3. |
| P4 | The History steps wrapped (`…21, 0, 1…`) and carried earlier districts (`0:AUD_LOCK` under `21:SUNDER`). | Two causes. `go_to_room` never cleared `history`, so every district's records stayed in the panel. Records were numbered by the global `frame_id`, which R sets to 0 while F9 brought back records with high numbers. | `history` is cleared on each district change. Each record carries `step`, a per-district commit counter (`room_step`, starting at 1, saved and restored). The global `frame_id` still feeds the hash. Driver: no History on a fresh district, and the steps never go down, including after F5 → R → F9 → SNAP. |
| P5 | `SNAP 0 ⇒ 1` in Ghost Rail, `→` elsewhere. | Not in code. Every readout uses `→` (U+2192), and there is no `⇒` anywhere in the project or any per-district format. At 1:1 the glyph renders as a single arrow. The likely cause is a bright bleed streak running through the arrow behind unbacked text. | None needed beyond P6. The HUD now has a backing, so streaks no longer cross the text. Watch for it in the third pass. |
| P6 | The Objective, Log hash and Threat / Intel lines sat on bright purple streaks. | Only the History panel and footer had a backing. | The five top-left lines share one dark violet-edged panel, the History panel style at 86% opacity, sized to the widest line every frame. Driver: the backing encloses every line and is narrower than the screen. |
| P7 | Big opaque magenta capsules covered the playfield after a lock or a clear. | These are the Auditor (shown on lock) and Sable (shown on win) capsule meshes. They were opaque and emissive, at x = ±3.5 in front of the board. | Kept as atmosphere: unshaded, 26% alpha, drawn first among transparent objects, no shadow. They are parked in the screen margins at view depth 7 and pushed further out if they would reach that district's spheres. Tags treat them as obstacles. Driver: no capsule screen rect touches a sphere, tag or beam, after SCAN, mid-puzzle and after the clear in every district. |
| P8 | The centre seam was a solid bar over node 4's sphere and tag. | The seam's near end (z = 7) sits between the camera and the board. As a transparent mesh it drew after the opaque spheres and washed them out. | The seam keeps its look but draws first (`render_priority -1`). Beams (0) and spheres (1) are transparent-pass materials with a depth pre-pass, so they draw fully opaque on top of it. Tags were already above the 3D layer, and their backing is now 88% opaque. Driver checks the priorities. |
| P9 | The 1 → 3 beam ran through node 2's sphere and tag (districts 1, 3, 5, 6), so it looked like a link to 2. | Straight beams in screen space. | When a straight beam would pass within a sphere radius + 12 px of a sphere that is not one of its endpoints on screen, it bends into the shallowest flat arc (in the board plane) that clears every other sphere. Nodes do not move and the rules do not change. Driver: no beam passes through a non-endpoint sphere in any district. |
| P10 | The `LOCKED` tag sat on the 0 – 1 link (districts 1, 4). | Tag placement ignored beams. | Beams are computed before tags, and tag placement penalises any length of beam inside a tag. Driver: no tag sits on any beam in all six districts (after SCAN, mid-puzzle and after the clear). |
| P11 | Node tags drew over the PAUSED panel. | The default `PanelContainer` style is translucent, so tags showed through it. | Tags are hidden while paused, and the pause panel has an opaque dark violet style. Driver covered. |

By design, unchanged: the Auditor locks node 1 on the 1 → 3 SNAP in every district, any two nodes can be SNAPped, and R resets the whole run.

Screenshots after these fixes (GL compatibility, 1280×720, driver run): `docs/images/qa/room1_start.png` (district 1 after SCAN, HUD backing, seam under node 4), `docs/images/qa/room3_ghost_rail_win.png` (Ghost Rail clear: LOCKED tag off the beams, translucent capsules), `docs/images/qa/room6_win.png` (The Sink after the Null Walker reroute 0 → 5 → 3: the 5 → 3 beam arcs clear of node 6, and the History reads 1…7).

## Played (scripted, real events, windowed)

| District | Result |
|----------|--------|
| 1 Compiler Heights | Wrong path then SUNDER → `Path incomplete.`; 0→1→3 with Auditor lock on node 1 → gate open |
| 2 Static Market | Scan + one SNAP, F5, R (back to district 1), F9 → district 2 restored with the edge; finished after load |
| 3 Ghost Rail | 0→1→2→3, clear |
| 4 Rollback District | Rollback timer counts on the HUD (`ROLLBACK 42s`). The timer is run out: SNAPs wiped, readout restarts. F5, R (the Rollback line clears on Compiler Heights), F9 (it returns). Then cleared. |
| 5 Dead Repository | 0→1, 1→3: Auditor locks 1, `NULL WALKER removed link 0 – 1. Node 1 is locked: route around it.`; 0–1 refused; SPACE → `Path incomplete.`; reroute 0→5→3 → clear |
| 6 The Sink | Same as 5 → clear; N wraps to district 1, six cleared |

## Played (by hand)

| Pass | Districts | Result |
|------|-----------|--------|
| Hand 1 (2026-10-08) | 1–4 | All cleared, 0 missed clicks. Esc, F5 / R / F9 worked. Findings H1–H7. |
| Hand 2 (2026-10-08) | 1–6 | All six cleared by hand. F5 / R / F9, Esc and H worked. In 5 and 6 the Null Walker broke 0 – 1 (node 1 locked), rerouted via node 5. N after The Sink wrapped to district 1 with `Cleared 6`. Findings P1–P11. |

Screenshots: `docs/images/qa/room1_start.png`, `docs/images/qa/room3_ghost_rail_win.png`, `docs/images/qa/room6_win.png`.

## Still open

1. **Third human pass (short).** A person should confirm P1–P11 on screen: the HUD backing, the translucent capsules in the margins, spheres reading through the seam, the arced beams (do they read as links between the right nodes?), tags off the beams, the pause panel, the Null Walker message, the History order after F9, and whether `⇒` (P5) ever shows again. The second pass was clean on gameplay. These are visual confirmations, checked so far only by driver screenshots.
2. **Forward+ / Vulkan render.** This box has no Vulkan driver. Fixes 3 and 5, the tag layer, and the P7 / P8 render-priority changes were checked on the GL compatibility renderer only.
3. **Kernel switch (1 / 2 / 3)** has not been hand-tested. The driver does not press 1 / 2 / 3 either. Only the status message and the selection clearing are covered by code review.
4. **Puzzle depth (design call, not changed).** Any two nodes can be SNAPped, and the Auditor never locks 0 or 3, so a direct 0→3 SNAP clears every district. Constraining SNAPs would be new design.
5. **R resets the whole run** to district 1 (by design in `reset_demo`). There is no "restart this district".
6. **Auditor always locks node 1 on the 1 → 3 SNAP** (by design: it is the highest-scoring target there). With the Null Walker in 5 and 6, that forces the reroute via node 5. P3 now says so on screen.
7. Volume and sensitivity sliders are not persisted between launches. There is no audio in the slice.

## Status

**IN PROGRESS.** Not `COMPLETE — PLAYTEST VERIFIED`.
