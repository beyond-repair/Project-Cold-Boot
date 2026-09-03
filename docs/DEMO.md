# Vertical Slice Demo — How to Run

## Requirements

- Godot 4.2+ (Forward Plus renderer recommended)

## Run

1. Open Godot
2. Import / open the `godot/` folder as a project
3. Press F5 (or Play)

## Controls

| Input | Action |
|-------|--------|
| **E** | SCAN — reveal anchors and Layer 0 seams |
| **Left Mouse** | SNAP — click two revealed nodes to draw a causal link |
| **Space** | SUNDER — execute the chain; open the gate if Lamp (0) connects to Gate (3) |
| **R** | Reset demo |

## Goal

1. Press **E** to SCAN (nodes light up, bleed seam appears).
2. Click nodes to create SNAP links. After the second link an Auditor locks one node.
3. Build a path from **Vesper_Lamp (0)** to **Vesper_Gate (3)**.
4. Press **Space** to SUNDER. If the path exists the gate opens and Sable appears.
5. Demo complete. Press **R** to run again (determinism: same actions produce same hash).

## What This Proves

- SCAN → SNAP → SUNDER loop is playable
- Log-style mutation + commit model works
- Auditor intervention changes the graph
- Dual-layer coloring (cyan Vesper / purple Necropolis)
- Frame hash updates for basic determinism feedback
- Bleed seam + Sable presence as narrative anchors

This is a gray-box proof. Full DLRSE (C++ GDExtension, AC-4.1, SoA ActiveGraph, GPR) replaces the GDScript simulation after the loop is validated as fun.
