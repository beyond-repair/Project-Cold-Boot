# Godot Project — Project Cold Boot

Godot **4.2+** project root for the Claim-0 vertical slice.

## Structure

```
godot/
├── project.godot          # main_scene = MainMenu; autoload GameState
├── scenes/
│   ├── main_menu/MainMenu.tscn
│   └── vertical_slice/VerticalSlice.tscn
├── scripts/
│   ├── systems/GameState.gd
│   ├── main_menu/MainMenu.gd
│   └── vertical_slice/VerticalSlice.gd
├── shaders/               # domain-warp compositor + noise
└── tools/smoke_test.gd    # headless SCAN→SNAP→SUNDER smoke
```

## Run

- Editor: open this folder as the project → **F5** (main menu → Enter the Manuscript).
- CLI play: `godot --path .` (from this directory) or `godot --path godot` from repo root.
- Headless smoke (from repo root): `./tools/smoke_test.sh`  
  or `godot --headless --path godot -s res://tools/smoke_test.gd`

## Dual-layer notes

- Layer 0 (Necropolis): ink / low-res gothic framing
- Layer 1 (Vesper City): neon vectors
- Bleed: compositor shader + ViewportTexture seam

**Claim:** RUNNABLE SKETCH only — not commercial art/audio/Steam readiness.
