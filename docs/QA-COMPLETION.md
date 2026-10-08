# Project Cold Boot — QA completion pass

**Date:** 2026-10-08 (America/New_York)
**Branch:** `fix/coldboot-playtest-pass`
**Scope:** the existing Claim-0 vertical slice (main menu, six districts, SCAN → SNAP → SUNDER, kernels, Auditor lock, Rollback timer, Null Walker, F5/F9 save). No new mechanics.
**Status:** COMPLETE — PLAYTEST VERIFIED (2026-10-08, ~05:15 ET, at `f7cf3f5`). Every district clears with real input events on the real scenes. Three human mouse-and-keyboard sessions (2026-10-08) found HUD, save/load, readability and kernel-message bugs (H1–H7, P1–P11, Q1–Q7), all fixed or explained below. Q8 (H, F5 and F9 under the PAUSED panel) followed from the driver. The driver now passes 356/356 windowed on Forward+ (Vulkan, software) and on GL compatibility, and 352/352 headless (the four streak pixel checks need a window and are skipped there). Hand check 4 (03:45 ET) confirmed the kernel messages and pause gating on screen; its R1–R3 readability findings are fixed and checked by the driver and by screenshots on both renderers. Hand check 5 (~04:12 ET) played district 1 with real mouse and keyboard on the fixed build and confirmed R1–R3 on screen; its one new finding (W1, seam showing through the win panel) is fixed. Hand check 6 (~04:30–04:45 ET) cleared all six districts by hand at `1dcb907` with no functional failure; its three polish findings (S1–S3: translucent PAUSED panel, compositor streaks over spheres, no message on resume) are fixed and checked by the driver and by screenshots. Hand check 7 (~05:10–05:15 ET) confirmed S1–S3 with real input on `f7cf3f5` and cleared all six districts again.

## How this was run

```bash
# Godot 4.2.2 (project target). 4.7.2 passed the earlier 47-check driver; not re-run for the hand-playtest slices.
# Every run uses its own empty XDG_DATA_HOME, so the F5 save starts clean.
export XDG_DATA_HOME=$(mktemp -d)
godot --headless --path godot -s res://tools/smoke_test.gd          # 28/28
godot --headless --path godot -s res://tools/play_driver.gd         # 352/352 (4 pixel checks skipped)
# Windowed under Xvfb (1280x720), with screenshots.
# Forward+ on Vulkan (Mesa lavapipe, software):
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json \
godot --path godot --rendering-method forward_plus --rendering-driver vulkan \
      --resolution 1280x720 -s res://tools/play_driver.gd -- --shots=/tmp/shots_vk  # 356/356
# GL compatibility (Mesa llvmpipe):
godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
      --resolution 1280x720 -s res://tools/play_driver.gd -- --shots=/tmp/shots_gl  # 356/356
python3 -m unittest discover -s tests                               # 5/5
```

The headless run prints `Parameter "m" is null` from the dummy renderer's `mesh_get_surface_count`. It was already there at `fe5faf4` (783 lines on 211 checks) and grows with the number of redraws. Neither windowed run prints it. The only other error in the windowed logs is ALSA failing to open a sound device (the box has none).

`godot/tools/play_driver.gd` is new. It boots `MainMenu`, presses **Enter the Manuscript**, and plays `VerticalSlice` by pushing real key and mouse events into the viewport. Clicks land on each sphere's projected screen position and go through the game's own raycast picking. It covers: click before SCAN, Esc pause and unpause, a wrong path plus SUNDER, a two-hop path through an Auditor lock, N to the next district, F5 mid-room then R then F9, the Rollback district, the Null Walker breaking a path in districts 5 and 6 (and the re-draw), and N after The Sink wrapping to district 1 with all six cleared. Since the hand playtest it also covers: SPACE with no SNAPs, SUNDER dropping a pending selection, the SNAP readout in click order, the Auditor lock message, the Rollback timer running out, R and F9 refreshing the Rollback line, the short hex log hash, each HUD fact shown once, and node tags not overlapping each other or any sphere in all six districts. Since hand playtest 2 it also covers: the log hash after F9, the status after E, H and F9, the Null Walker naming the link it took (and the locked endpoint), the 0 → 5 → 3 reroute in districts 5 and 6, History steps in order per district, the dark HUD backing, the Auditor / Sable capsules clear of spheres, tags and beams, spheres and beams drawn after the seam, no beam passing through another sphere, no tag on a beam, and nothing over the PAUSED panel. Since hand playtest 3 it also covers the kernel keys (see **Kernels** below): keys 1 / 2 / 3, the HUD kernel line, the status naming the SNAP that will lock, the lock landing on that SNAP, a kernel key dropping a pending selection, the message after the Auditor has locked and mid-district, F5 / F9 of the kernel and its log hash, 1 / 2 / 3 and N ignored while paused, R keeping the kernel, district 1 cleared under each kernel, and Force Revert in Dead Repository across F5 → R → F9. For Q8 it also checks, in district 2 with a pending selection and a save that differs from the board, that E, SPACE, 1, 2, 3, N, H, F5, F9, R and a click under the PAUSED panel change nothing (game state, board, HUD lines, status and the save file), that Esc resumes with the same board, and that H, E, a click and F5 work again after it. For hand check 6 it also checks that the PAUSED and win panel backings are fully opaque (alpha 1.0), that every Esc resume sets the status to `Resumed.`, and that the compositor masks its streaks off lit scene pixels; windowed, in districts 1 and 6 after SCAN, it renders a frame with the streaks forced to full strength everywhere and compares it with a normal frame: every sphere centre keeps its colour and layer hue, while an empty background pixel turns violet.

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

## Hand playtest 3 (2026-10-08)

A person played the build on the desktop (windowed, GL compatibility, 1280×720, real mouse and keyboard, code at `fe5faf4`) from about 2:35 to 2:48 ET. They cleared all six districts by hand and switched kernels along the way:

| District | Kernel | Route | What happened |
|----------|--------|-------|---------------|
| 1 Compiler Heights | Final Commit | 0 → 1, 1 → 3 | The Auditor locked node 1 on 1 → 3. |
| 2 Static Market | Force Revert | 0 → 4, 4 → 3 | No lock. |
| 3 Ghost Rail | Keep Drafting | 0 → 1 → 2 → 3 | No lock. |
| 4 Rollback District | Keep Drafting | 0 → 4, 4 → 3 | No lock. The Rollback timer started at 47s on SCAN and read 31s at SUNDER. |
| 5 Dead Repository | Keep Drafting | 0 → 1, 1 → 3, then 0 → 5, 5 → 3 | The Null Walker removed 0 – 1. The Auditor locked node 1 on the 5 → 3 SNAP. F5 here, R to district 1, F9 restored district 5. N to district 6. |
| 6 The Sink | Keep Drafting | 0 → 1, 1 → 3, then 0 → 5, 5 → 3 | The Null Walker removed 0 – 1. The Auditor locked node 1 on the 0 → 5 SNAP. N wrapped to district 1 with `Cleared 6`. |

They confirmed every P-fix from hand playtest 2 on screen:

- The HUD backing is readable.
- The capsules are translucent and stay in the margins.
- Node 4 reads through the seam after SCAN. It is dim before SCAN, which is the unscanned look.
- The arced 1 → 3 beam clearly joins 1 and 3. It passes close to the top edge of node 2.
- No tag sits on a beam or on another tag. In districts 5 and 6 the `LOCKED` tag on node 1 is within a few pixels of the 1 → 3 beam, but not on it.
- The PAUSED panel is opaque, tags are hidden while paused, and Esc resumes.
- The Null Walker message reads `SNAP 1 → 3 | NULL WALKER removed link 0 – 1.`
- After F9 the History steps are in increasing order, and the log hash is hex.
- The SNAP arrow was always a single `→`. P5 is closed.

What they reported, what the driver found while covering the kernels, and what changed:

| # | Finding | Root cause | Fix |
|---|---------|------------|-----|
| Q1 | The kernel message (`Kernel switched: the Auditor locks a node on SNAP #N.`) gave SNAP numbers that matched nothing on screen, and promised locks that never came (Force Revert in district 2, Keep Drafting in district 3). | The number was `get_auditor_lock_threshold() + 1`. That is correct only for a district with no SNAPs yet, and only for the district on screen when the key is pressed. It ignored three things. The threshold drops by one at threat ≥ 85% (districts 1 and 6). The Auditor locks only once per district. And SNAPs already made count, so a switch mid-district promised a SNAP that was already past. Short routes also never reach the promised SNAP: district 2 under Force Revert (threat 68%) locks on SNAP #3, and the player made two. District 3 under Keep Drafting (threat 50%) locks on SNAP #4, and the player made three. | The message names the kernel and states what will actually happen in this district. Before a lock: `Kernel switched to Keep Drafting: the Auditor locks a node on SNAP #3.`, where the number is the threshold or the next SNAP, whichever is later. After a lock: `…the Auditor has already locked a node here.` With the gate open: `Kernel switched to X.` The rules are unchanged. Driver: the promised SNAP number under each kernel in district 1, the lock landing on it (or not landing before it), the message after a lock, and a mid-district switch. |
| Q2 | `AUD_LOCK` History entries share the SNAP's step number (`4:SNAP`, `4:AUD_LOCK`, `5:SNAP`). | By design. The step is the per-district commit counter. `_do_snap` logs the SNAP and the Auditor's lock in the same frame, and `commit_frame` applies both together (the lock at priority 2, after the SNAP). So they are one commit and share one step. The next commit gets the next step. | None. Documented here. |
| Q3 | In district 5 the lock landed on the 5 → 3 SNAP, and in district 6 on the 0 → 5 SNAP. Both times it locked node 1, which was not in that SNAP. | By design. Keep Drafting carried over from district 3. Its threshold locks on SNAP #4, or SNAP #3 at threat ≥ 85%. Dead Repository is at 82%, so it locks on SNAP #4 (0 → 1, 1 → 3, 0 → 5, 5 → 3). The Sink is at 95%, so it locks on SNAP #3 (0 → 5). SNAP numbers count SNAPs made, including the 0 – 1 link the Walker removed. `pick_auditor_lock_target` never picks 0 or 3. It scores the other nodes from the links before this SNAP: 2 per link, +3 if on the recent path, +1.5 × threat for layer 0, all × 0.75 under Keep Drafting. In district 6, node 1 (one link, on the path, layer 0) scores about 4.8 and node 5 about 1.1. In district 5, nodes 1 and 5 tie at about 4.7, and the lower id wins. | None. The message already names the node (`AUDITOR locked node 1: …`). |
| Q4 | The kernel survives R. | By design. `reset_demo` resets the run, not the kernel, and the HUD kernel line agrees after R. | None. Driver: R keeps the kernel and the HUD line. |
| Q5 | Driver: after a kernel switch, the log hash on the HUD was stale. F5 → R → F9 then showed a different hash from the one at F5 (`39847d58` vs `395ce7d5`). | The kernel is mixed into the log hash, but the hash was only recomputed on the next commit. | A kernel switch recomputes the hash (`GameState.refresh_hash()`) and redraws the hash line. Driver: the hash after F9 equals the hash at F5 after a switch. |
| Q6 | Driver: 1 / 2 / 3 and N still worked under the PAUSED panel. N while paused moved to the next district. | Pause gated clicks, SCAN, SNAP and SUNDER, but not these keys. | While paused, 1 / 2 / 3 and N are ignored. Esc, H, F5 and F9 still work while paused, as before. Driver: kernel and district unchanged after 1 and N while paused. |
| Q7 | Driver: after F9 in Dead Repository, the Auditor locked one SNAP late. | Load set the SNAP count to the number of edges. The Null Walker removes an edge but not the SNAP that made it, so the restored count was one short. | The save stores the SNAP count, and load uses it (never less than the edge count, for older saves). Driver: Force Revert in district 5, F5 → R → F9 restores the count and the lock lands on the same SNAP as without the save. |
| Q8 | Driver (open item 7 after Q6): H, F5 and F9 still worked under the PAUSED panel. F9 while paused restored the board behind the panel, and H toggled the History and rewrote the status. | In `_unhandled_input` the H / F5 / F9 keys were handled before the `paused` check. Q6 had added a pause check for 1 / 2 / 3 and N only. | Right after Esc is handled, `if paused: return` now gates every gameplay key and click (E, SPACE, R, 1 / 2 / 3, N, H, F5, F9, LMB). Esc still pauses and resumes. Nothing else changed. Driver: see the Q8 checks above (22 new checks, district 2). |

Before these fixes, the extended driver passed 308/315 on Forward+. The seven failures were Q1 (two), Q5, Q6 (two) and Q7 (two). After them, every renderer passes 315/315. With the Q8 pause-gating checks the driver has 337 checks, and every renderer passes 337/337.

Screenshots: the existing `docs/images/qa/` GL shots are unchanged (these fixes change status text and the hash line, not the board). `docs/images/qa/room1_vulkan.png` is new: district 1 after SCAN on Forward+.

## Kernels

Keys 1, 2 and 3 pick the kernel: **Final Commit**, **Force Revert** and **Keep Drafting**. The HUD shows it on the `Kernel:` line. A kernel changes only two things. It does not change which SNAPs are allowed or what clears a district.

- **When the Auditor locks.** The Auditor locks one node per district, on a set SNAP: Final Commit on SNAP #2, Force Revert on SNAP #3, Keep Drafting on SNAP #4. At threat ≥ 85% (Compiler Heights 90%, The Sink 95%) Force Revert and Keep Drafting lock one SNAP earlier. Nothing locks before SNAP #2. SNAPs are counted per district, including links the Null Walker later removes.
- **Which node it locks.** It never locks 0 (START) or 3 (GATE). It scores the rest by links, the recent path and layer. Final Commit adds weight for links, so it favours well-linked nodes more. Keep Drafting scales every score by 0.75, which does not change the pick, so Force Revert and Keep Drafting pick the same node.

The kernel is part of the log hash. It is saved by F5 and restored by F9, and it survives R and N. Switching clears a pending selection. The status line then says which SNAP will lock in this district, or that the Auditor has already locked here. Kernel keys do nothing while paused (no gameplay key does: see Q8).

## Forward+ / Vulkan render check

This box has no GPU. Mesa's lavapipe software Vulkan driver (`mesa-vulkan-drivers` 25.0.7, `libvulkan1` 1.4.309) was installed, and Godot was pointed at it with `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`. The run log confirms the real Forward+ path:

```
Vulkan devices:
  #0: Unknown llvmpipe (LLVM 19.1.7, 256 bits) - Supported, CPU
Vulkan API 1.4.305 - Forward+ - Using Vulkan Device #0: Unknown - llvmpipe (LLVM 19.1.7, 256 bits)
```

| Run | Code | Forward+ (Vulkan) | GL compatibility |
|-----|------|-------------------|------------------|
| Original driver | `fe5faf4` | 211/211 | 211/211 |
| Extended driver, before the Q-fixes | `fe5faf4` + driver | 308/315 (the Q1, Q5–Q7 bugs) | not run |
| Extended driver, after the Q-fixes | `2a65f01` | 315/315 | 315/315 |
| Driver with the Q8 pause-gating checks | `757edf6` | 337/337 | 337/337 |
| Driver with the R1–R3 / W1 checks | `06b6391` / `1dcb907` | 346/346 (`06b6391`) | 347/347 (`1dcb907`) |
| Driver with the S1–S3 checks | this slice | 356/356 | 356/356 |

Visual differences on Forward+, compared with GL compatibility at the same frames: the image is brighter and keeps colour (spheres stay pink where GL compatibility clips them to white). The seam is about twice as bright. The capsules are about twice as visible, but still clear of spheres, tags and beams. The board, tags, HUD and panels read the same. This is the renderer's tone mapping and glow, not a regression. Fixes 3 and 5 and P7 / P8 hold on both renderers. See `docs/images/qa/room1_vulkan.png` against `docs/images/qa/room1_start.png`. (That comparison predates R2. Since R2 both renderers keep the violet / cyan sphere hues, and the refreshed screenshots read almost the same on both.)

Not covered: Vulkan on a real GPU driver. Only the software ICD was used.

## Played (scripted, real events, windowed)

| District | Result |
|----------|--------|
| 1 Compiler Heights | Wrong path then SUNDER → `Path incomplete.`; 0→1→3 with Auditor lock on node 1 → gate open |
| 2 Static Market | Scan + one SNAP, F5, R (back to district 1), F9 → district 2 restored with the edge; finished after load |
| 3 Ghost Rail | 0→1→2→3, clear |
| 4 Rollback District | Rollback timer counts on the HUD (`ROLLBACK 42s`). The timer is run out: SNAPs wiped, readout restarts. F5, R (the Rollback line clears on Compiler Heights), F9 (it returns). Then cleared. |
| 5 Dead Repository | 0→1, 1→3: Auditor locks 1, `NULL WALKER removed link 0 – 1. Node 1 is locked: route around it.`; 0–1 refused; SPACE → `Path incomplete.`; reroute 0→5→3 → clear |
| 6 The Sink | Same as 5 → clear; N wraps to district 1, six cleared |
| Pause (district 2) | With a pending selection and a save: E, SPACE, 1 / 2 / 3, N, H, F5, F9, R and a click under PAUSED change nothing; Esc resumes with the same board; H, E, click and F5 work again |
| Kernels | District 1 cleared under Final Commit, Force Revert and Keep Drafting, each lock on the promised SNAP; F5 / R / F9 of the kernel with the same hash; 1 / 2 / 3 and N ignored while paused; Force Revert through to district 5, F5 / R / F9 after the Null Walker, lock on the same SNAP, clear |

## Played (by hand)

| Pass | Districts | Result |
|------|-----------|--------|
| Hand 1 (2026-10-08) | 1–4 | All cleared, 0 missed clicks. Esc, F5 / R / F9 worked. Findings H1–H7. |
| Hand 2 (2026-10-08) | 1–6 | All six cleared by hand. F5 / R / F9, Esc and H worked. In 5 and 6 the Null Walker broke 0 – 1 (node 1 locked), rerouted via node 5. N after The Sink wrapped to district 1 with `Cleared 6`. Findings P1–P11. |
| Hand 3 (2026-10-08, ~2:35–2:48 ET) | 1–6 | All six cleared by hand with kernel switches (Final Commit, Force Revert, Keep Drafting). Null Walker reroute via 5 in 5 and 6. F5 in 5, R, F9 restored 5. N after The Sink wrapped to district 1 with `Cleared 6`. Every P-fix confirmed on screen. Findings Q1–Q4 (plus driver findings Q5–Q7). |
| Hand 6 (2026-10-08, ~04:30–04:45 ET) | 1–6 | All six cleared by hand at `1dcb907` with kernel keys, F5 / R / F9 in districts 2 and 5, pause gating, H, the Rollback timer and the Null Walker reroute. No functional failure. Findings S1–S3 (polish). |
| Hand 7 (2026-10-08, ~05:10–05:15 ET) | 1–6 | All six cleared by hand at `f7cf3f5` (direct 0 → 3). S1–S3 confirmed: opaque PAUSED and win panels, no streak over any sphere in The Sink, `Resumed.` after Esc. N wrapped to district 1 with `Cleared 6`. No findings. |

Screenshots: `docs/images/qa/room1_start.png`, `docs/images/qa/room3_ghost_rail_win.png`, `docs/images/qa/room6_win.png`, `docs/images/qa/room1_vulkan.png` (Forward+). Refreshed after S1–S3 from the GL and Vulkan driver runs (they still showed the white spheres and the seam column from before R1–R3).

## Hand check 4 (2026-10-08, ~03:45 ET)

Real key presses and clicks on the GL compatibility build at `99483b0`, 1280x720, fresh save folder.

| Check | Result |
|---|---|
| Kernel keys before any SNAP (district 1, after E) | PASS. 2: `Kernel switched to Force Revert: the Auditor locks a node on SNAP #2.` 3: `…Keep Drafting: …SNAP #3.` 1: `…Final Commit: …SNAP #2.` HUD kernel line follows each key. |
| Lock lands on the promised SNAP (Final Commit) | PASS. 0 → 1, then 1 → 3: `SNAP 1 → 3 \| AUDITOR locked node 1: no new SNAPs to it (its links still count).` on SNAP #2. |
| Kernel key after the lock | PASS. `Kernel switched to Force Revert: the Auditor has already locked a node here.` |
| Mid-district switch (district 2, one SNAP made) | PASS. `…Force Revert: the Auditor locks a node on SNAP #3.` |
| Pause gating (node selected, after F5) | PASS. Under `PAUSED / Esc to resume`, E, SPACE, 1, 2, 3, N, H, F5, F9, R and a click changed no HUD line, the district, History or selection. Esc resumed with the same board; H then toggled History. |
| Clear and N | PASS. District 1 `SUNDER: gate open.`, Cleared 1, N to `Static Market (2/6)`. |

Also seen, by design or minor: node tags hide while paused (P11); F5 replaces the `Selected [2] …` status with `Saved.` while the node stays selected; the log hash is deterministic per kernel. No crash, freeze or soft-lock.

## Readability fixes from hand check 4 (2026-10-08, ~04:05 ET)

| # | Found | Cause | Fix and check |
|---|-------|-------|---------------|
| R1 | Violet compositor streaks ran behind the HUD column, one crossing `(GATE)` in the Objective line; the backing let them show through. | The HUD backing was 86% opaque and the compositor seam was drawn everywhere, including under the text. | The backing is 95% opaque, and the compositor fades its seam inside the HUD column and History panel rects (`calm_rect_a/b`, updated every frame with the backing). Driver: the calm rect encloses the HUD backing after SCAN and after the first SNAP. |
| R2 | After SCAN every sphere was the same solid white, linked or not. | Sphere emission was 3.5× on an LDR target, so violet and cyan both clipped to white. Beams at 6× clipped too. | Necropolis nodes glow violet and Vesper nodes cyan at 0.55×; linked nodes glow at 1.1×, as do locked (red), open gate (green) and selected (amber). Beams are 1.4× violet. Driver: no sphere's emission passes white, the two layers glow different colours, and a linked sphere glows brighter than an unlinked one. |
| R3 | A translucent magenta column ran through the centre of each district, over nodes 4 and 1 and near their tags. | The `BleedSeam` was a 7-unit-tall, 14-deep sheet at x = 0, with its near end close to the camera. | The seam is now a thin fault line on the floor across the front of the board (9 × 0.02 × 0.08 at z = 3.9), in front of every node and inside the Auditor / Sable margins. It still appears on SCAN. Driver: the seam is flat and in front of every node in district 1. Screenshots of all six districts on Vulkan show it below every sphere and tag. |

## Hand check 5 (2026-10-08, ~04:12 ET)

Real mouse and keyboard on the GL compatibility build at 1280×720, fresh save directory. Menu, ENTER THE MANUSCRIPT, district 1: E, click 0 then 1, click 1 then 3, SPACE.

| Check | Result |
|-------|--------|
| R1 HUD at entry and after SUNDER | PASS. The six HUD lines and History sit on a dark backing with no violet streak through any text. |
| R2 sphere colours | PASS. Vesper nodes glow cyan and Necropolis nodes violet; linked 0 and 1 are brighter than 2 and 4; node 1 turns red with a `LOCKED` tag; the gate turns green on SUNDER. Beams are violet, not white. |
| R3 seam | PASS. No column through the board; a thin violet line lies across the front of the board below every sphere and tag. |
| Clear | PASS. `SUNDER: gate open.`, `Objective complete.`, Cleared 1, History 1–4 in order, win panel with the Sable line. |
| W1 (new) | The win panel used the default translucent grey, and the front seam line showed between its text lines. Fixed: the win panel uses the opaque PAUSED backing. Driver asserts it; GL screenshots of the district 1 and 6 win panels show it clean. |

## Hand check 6 (2026-10-08, ~04:30–04:45 ET)

Real mouse and keyboard on the GL compatibility build at `1dcb907`, 1280×720, fresh save directory. All six districts cleared by hand. No functional failure, crash, freeze or soft-lock.

| Districts | Result |
|-----------|--------|
| 1–3 | District 1: kernel keys 2 then 1 before the first SNAP, each status naming the promised SNAP #2; Final Commit locked node 1 on 1 → 3 (SNAP #2, as promised); History in order; H hid and showed it; win panel opaque (the floor line passes behind it, by design); N to district 2. District 2: Force Revert, SNAP 0 → 4, F5 (Log hash `1d49e8ee`), R to district 1, F9 restored district 2 with the same hash `1d49e8ee` and the beam; paused with node 4 selected: N, SPACE, H and a click were ignored; Esc resumed the same board; 4 → 3, clear. District 3: Keep Drafting, 0 → 1 → 2 → 3, clear. |
| 4–6 | District 4: key 2 before SCAN kept Force Revert through SCAN; ROLLBACK started at 47s and counted down; cleared at 16s; the readout was gone on clear. District 5: the Null Walker removed 0 – 1 on 1 → 3; SPACE → `Path incomplete. Link 0 to 3, then SUNDER.`; 0 → 5; F5 (`a9400a3c`), R, F9 restored hash `a9400a3c` and both beams; 5 → 3 (node 1 locked); History 1–6 in order; pause ignored SPACE and N; clear, `Cleared 5`. District 6: Null Walker on 1 → 3; the Auditor locked node 1 on 0 → 5; 5 → 3; clear, `Cleared 6`; N wrapped to Compiler Heights with `Cleared 6`. |

Two tester-reported "failures" were checked and are not bugs:

- **A kernel reverting on SCAN in district 3.** A scripted replay of the exact key and click sequence reproduced every hand hash (`1d49e8ee`, `fefcc33c`) and showed the kernel holds through SCAN. The tester's first key 3 did not reach the game before E.
- **`SNAP 3 → 2`.** The replay records 2 → 3; the readout follows click order (P-fix), and the tester clicked 3 first after a missed click.

Two missed clicks in district 2 worked on retry.

### Polish fixes from hand check 6

| # | Found | Cause | Fix and check |
|---|-------|-------|---------------|
| S1 | The PAUSED panel was slightly translucent: a beam behind it showed faintly through its dark interior. | The shared PAUSED / win panel `StyleBoxFlat` had a background alpha of 0.96. | Alpha 1.0 for both panels (`_style_pause_panel`). Driver: both panel styleboxes have background alpha 1.0. GL and Vulkan screenshots of PAUSED (`01d_room1_paused`, `02b_room2_paused_gated`) and the win panels show no beam through them. |
| S2 | The compositor's thin violet background streaks were painted over the spheres; in The Sink a streak crossed sphere 6 `Unraveled Mind` and could read as a beam through it. | The compositor blended its streak over the whole composited 3D image, spheres and beams included (tags sit on a layer above it and were never affected). | The shader scales the streak by `1 - smoothstep(scene_mask_low, scene_mask_high, lit)`, where `lit` is the brightest channel of the composited scene pixel (0.1 → 0.24). The empty background is near black (< 0.08) and keeps the full streak; spheres, beams and the floor line are far brighter and get none. Driver: the shader has the mask; windowed, in districts 1 and 6 after SCAN, a frame with the streak forced on everywhere (`seam_force`, a test-only uniform, 0 in play) leaves every sphere centre's colour and hue unchanged while an empty background pixel turns violet. With the mask disabled the sphere check fails. Screenshots of district 6 after SCAN show sphere 6 and every other sphere clear. |
| S3 | After Esc resumed from pause the status kept the old text, so nothing said the game had resumed. | The pause toggle only changed the panel, tags and tree pause. | On resume the status reads `Resumed.` (pausing is unchanged). Driver: every Esc resume expects `Resumed.`; the pause-gating "same board after resume" check now compares everything except the status, which it checks separately. |

## Hand check 7 (2026-10-08, ~05:10–05:15 ET)

Real mouse and keyboard on the GL compatibility build at `f7cf3f5`, 1280×720, fresh save directory. Menu, ENTER THE MANUSCRIPT, then every district: E, SNAP 0 → 3, SPACE, N. Pause and resume in districts 1 and 6.

| Check | Result |
|-------|--------|
| S1 PAUSED panel (districts 1 and 6) | PASS. Magnified crops show one solid dark colour inside the panel; no beam, streak or line shows through. |
| S1 win panels | PASS. Districts 1 and 6 magnified, 2–5 at full frame: opaque; the floor line passes behind the panel edges only. |
| S2 streaks over spheres (district 6 after SCAN) | PASS. Streaks stop at the edge of sphere 6 "Unraveled Mind" and every other sphere; at most a 1–2 px graze of the top rim of sphere 3 in one frame, nothing across a sphere's surface. |
| S3 resume | PASS. `Resumed.` after both Esc resumes. |
| Progression | PASS. Each district `SUNDER: gate open.` / `Objective complete.`, Cleared 1 → 6 (district 4 met with `ROLLBACK 42s` left); N after The Sink wrapped to Compiler Heights with Cleared 6. No ignored input, crash or freeze. |

The translucent Auditor / Sable capsule in the left margin after SUNDER is by design (see P7 / P8).

## Still open

1. **Hand verification: done.** Hand check 6 cleared all six districts by hand and hand check 7 confirmed S1–S3 on `f7cf3f5`. Nothing below blocks the release candidate; items 2–6 are design calls or untested environments.
2. **Puzzle depth (design call, not changed).** Any two nodes can be SNAPped, and the Auditor never locks 0 or 3, so a direct 0→3 SNAP clears every district. Constraining SNAPs would be new design.
3. **R resets the whole run** to district 1 (by design in `reset_demo`). There is no "restart this district".
4. **Auditor always locks node 1 on the 1 → 3 SNAP** (by design: it is the highest-scoring target there). With the Null Walker in 5 and 6, that forces the reroute via node 5. P3 now says so on screen. Q3 explains when it lands on a later SNAP.
5. Volume and sensitivity sliders are not persisted between launches. There is no audio in the slice.
6. Vulkan on a real GPU is untested (software lavapipe only).

## Status

**COMPLETE — PLAYTEST VERIFIED.** Built and launched with Godot 4.2.2, played by hand through all six districts on the final build (hand checks 6 and 7), with the primary loop (SCAN → SNAP → SUNDER), progression and the N wrap, node picking, every control (E, LMB, SPACE, Esc, H, 1/2/3, N, F5/F9, R), F5/F9 saves across R, the Rollback timer, the Auditor lock and the Null Walker reroute verified, plus the scripted regression (driver 356/356 windowed on GL compatibility and Forward+, 352/352 headless; smoke 28/28; unit 5/5).
