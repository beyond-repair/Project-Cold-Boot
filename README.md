# Project Cold Boot

**You are not the hero. You are the cold boot — the first draft the system never meant to survive.**

First-person reality-editing action-puzzle game. Spiritual successor to the 1994 cult classic *Noctropolis*. Built in Godot 4.x on a custom **Deterministic Log-Reduction Simulation Engine (DLRSE)**.

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

The player does not defeat enemies by statistics. The player understands systems, discovers hidden causality, and rewrites reality.

## Engine: DLRSE

**Deterministic Log-Reduction Simulation Engine**

```
Input → GES → AC-3/AC-4.1 → Auditor → MutationLog → DCB → ActiveGraph → Render/Haptics
```

**Invariants**
- Log-only emission (no direct mutation of ActiveGraph)
- Single-writer Deterministic Commit Barrier (DCB)
- Pure reduction functions
- Strict payload typing
- Replay determinism from seed + MutationLog
- Global Pressure Regulator (GPR) enforces ≤10 ms CPU simulation budget

## Gear of the Ancients

1. **Shadow-Skin** — Stealth + kinetic burst suit
2. **Noctro-Glyph** — Gesture-driven symbolic processor (scan, execution, desync)
3. **Dimensional Anchor** — Vertical phase-tether momentum chaining

## Visual Pillars

- Ink-drenched Gothic ruins (Necropolis)
- Sterile cyber-noir megacity (Vesper City)
- Violet causal energy
- Lightning bleed seams
- Adaptive Auditor overlays
- Minimal diegetic HUD
- Dynamic corruption shaders

## Current Status (v1.8)

- Engine architecture locked
- Core implementation in progress
- Solo-dev execution directive active
- Immediate priority: **Vertical Slice** (one gray-box room proving the full SCAN→SNAP→SUNDER loop + Auditor + Sable + bleed)

## Repository Structure

```
/
├── docs/                  # Project Bible, RFCs, design chapters
├── engine/                # DLRSE core (C++ GDExtension target)
├── godot/                 # Godot 4.x project (scenes, scripts, resources)
├── assets/                # Placeholder art / audio notes
├── tools/                 # Editor tooling plans
├── LICENSE
└── README.md
```

## Solo-Dev Execution Directive

1. **Phase 1** — Vertical Slice (prove the loop)
2. **Phase 2** — Tooling (Graph Editor, Replay Viewer, Mutation Inspector)
3. **Phase 3** — Procedural / engine-driven content
4. **Phase 4** — Polish

Experience drives systems. Scope discipline is non-negotiable.

## License

MIT (see LICENSE). Original assets and code only. Intertextual homage permitted; no trademarked names or direct lifts from *Noctropolis*.

---

**You are not the system.**  
**You are the cold boot.**
