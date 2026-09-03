# Project Cold Boot

**You are not the hero. You are the cold boot — the first draft the system never meant to survive.**

First-person reality-editing action-puzzle game. Spiritual successor to the 1994 cult classic *Noctropolis*. Built in Godot 4.x on a custom **Deterministic Log-Reduction Simulation Engine (DLRSE)**.

**Public repo**: https://github.com/beyond-repair/Project-Cold-Boot

## Core Premise

The player is an external force rewriting a contested 30-year-old simulation manuscript compiled by **The Compiler**. Reality consists of two bleeding layers:

- **Layer 0 — 1994 Necropolis**: Ink-drenched Gothic ruins
- **Layer 1 — 2026 Vesper City**: Sterile cyber-noir megacity

**Bleed-Through** occurs when the player rewrites causality. The city’s immune system — **Auditor Units** — predicts, adapts, and locks repeatable logic.

## Core Loop (Immutable)

```
SCAN → SNAP → SUNDER
```

- **SCAN** (Restorer’s Lens): Reveal hidden anchors and Layer 0 seams
- **SNAP** (Noctro-Glyph / Gravity Anchor): Draw causal links, define behavior
- **SUNDER** (Talon Daggers): Execute domino chains. Reality resolves.

## Design Philosophy

Project Cold Boot is **simulation-first**.

- Combat is constraint resolution
- Exploration is graph discovery
- Progression is mastery of causality
- Narrative is the visible consequence of simulation

## Visual Authority

Canonical look is defined by the Game Design Document page and moodboard (key art, SCAN/SNAP/SUNDER, Auditor, Dual Reality split, Sable, Tools, Authorship War UI). See `docs/ART_DIRECTION.md` and `docs/VERTICAL_SLICE_VISUAL.md`.

- Violet causal energy
- Lightning bleed seams
- Ink-decay vs sterile neon
- Glitched Auditor silhouette
- Sable as corrupted-code guide

## Engine: DLRSE

**Deterministic Log-Reduction Simulation Engine**

```
Input → GES → AC-3/AC-4.1 → Auditor → MutationLog → DCB → ActiveGraph → Render/Haptics
```

Log-only emission. Single-writer DCB. Replay determinism. GPR enforces ≤10 ms CPU simulation budget on mobile.

## Gear of the Ancients

1. **Shadow-Skin** — Stealth + kinetic burst
2. **Noctro-Glyph** — Gesture symbolic processor
3. **Dimensional Anchor** — Vertical phase-tether

## Current Status (v1.8)

- Engine architecture locked
- Visual language locked from provided GDD + moodboard
- Core implementation in progress
- Immediate priority: **Vertical Slice** (one gray-box room proving the full loop + Auditor + Sable + bleed)

## Repository Structure

```
/
├── docs/                  # Bible, DLRSE, Art Direction, Vertical Slice
├── engine/                # DLRSE core (C++ GDExtension target)
├── godot/                 # Godot 4.x project
├── LICENSE
└── README.md
```

## Solo-Dev Execution Directive

1. Vertical Slice (prove the loop)
2. Tooling
3. Procedural / engine-driven content
4. Polish

Experience drives systems. Scope discipline is non-negotiable.

## License

MIT. Original assets and code only. Intertextual homage permitted; no trademarked names or direct lifts from *Noctropolis*.

---

**You are not the system.**  
**You are the cold boot.**
