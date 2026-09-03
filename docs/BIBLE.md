# Project Cold Boot — Project Bible (v1.8 Executive Edition Locked)

**Status**: Architecture Locked | Core Implementation In Progress | Solo-Dev Vertical Slice Priority

## 1. Vision

First-person reality-editing action-puzzle game. Spiritual successor to 1994 *Noctropolis*. Player is the external Cold Boot rewriting a contested simulation manuscript compiled by The Compiler. Dual layers bleed: 1994 Necropolis (Layer 0) and 2026 Vesper City (Layer 1).

**Tagline**  
*You are not the hero. You are the cold boot—the first draft the system never meant to survive.*

## 2. Design Philosophy

Project Cold Boot is simulation-first.

The player does not defeat enemies by statistics or equipment.  
The player understands systems, discovers hidden causality, and rewrites reality.

- Combat is constraint resolution
- Exploration is graph discovery
- Progression is mastery of causality
- Narrative is the visible consequence of simulation

## 3. Core Loop (Immutable)

SCAN → SNAP → SUNDER

- **SCAN** (Restorer’s Lens): Reveal hidden anchors and Layer 0 seams
- **SNAP** (Noctro-Glyph / Gravity Anchor): Draw causal links, define behavior
- **SUNDER** (Talon Daggers): Execute domino chains. Reality resolves.

Player-facing language: chains, links, echoes, rewrites, desync. Graph terminology is internal only.

## 4. Gear of the Ancients (Locked)

1. **Shadow-Skin** — Semi-organic polymer suit. Light absorption, kinetic burst via Android gestures. Stealth + glyph enhancement.
2. **Noctro-Glyph** — Palm-sized obsidian shard with shifting sigils. Resonance Scan, gesture execution, Reality Desync. Tiered symbolic language progression.
3. **Dimensional Anchor (Phase-Tether Harness)** — Vertical momentum chaining, dual-layer tethers, phase pass-through.

## 5. Systems

- **Authority Vector**: Identity Drift, Authorial Strain, Bit-Rot, Final Signature (perception distortion prioritized over control mutation).
- **Simulation Kernels**: Final Commit / Force Revert / Keep Drafting — systemic reconfiguration of physics, shaders, entropy, Auditor aggression.
- **Auditors**: Constraint-solving adversaries. Markov pattern tracking + entropy noise. Predict, lock, corrupt, force creativity.
- **Sable**: Corrupted-code companion, decoder, emotional stability anchor.

## 6. Engine — DLRSE

Deterministic Log-Reduction Simulation Engine.

**Pipeline**  
GES (emission) → AC-3/AC-4.1 (constraints) → Auditor (adversarial) → MutationLog → DCB (reduction) → ActiveGraph (SoA state)

**Invariants**
- Log-only emission
- Single-writer DCB
- Pure reduction functions
- Strict payload typing (fixed float32/int32/bool arrays)
- Total ordering + atomic sequence counters
- Read-only snapshots during emission
- Hash validation (incremental + XXH3)
- ZeroAllocPool + static allocation
- GPR enforces ≤10 ms CPU simulation budget

## 7. Engineering Constitution

Every subsystem must:

- Emit MutationRecords only
- Never mutate ActiveGraph directly
- Remain replay deterministic
- Execute within the GPR frame budget
- Degrade gracefully under pressure
- Serialize deterministically
- Be testable through the replay harness
- Preserve DCB as the sole authority for state mutation

Violation requires redesign before integration.

## 8. Solo-Dev Execution Directive

**Phase 1** — Vertical Slice: One gray-box room proving SCAN→SNAP→SUNDER + Auditor interference + Sable contact + bleed. 10–15 minutes. Success metric: fun + deterministic.

**Phase 2** — Tooling: Graph Editor, Puzzle Generator, MutationLog Inspector, Replay Viewer, Auditor Debug, Graph Heatmap.

**Phase 3** — Engine-driven content: Procedural graphs, puzzles, districts from world DNA.

**Phase 4** — Polish: Shaders, haptics, environmental storytelling, Sable dialogue, UI.

## 9. Production Priorities

1. Vertical slice
2. Tooling
3. ActiveGraph + AC-4.1 integration
4. Integration / determinism tests
5. Content

## 10. Legal & Production Shield

- 100% original assets and code
- Intertextual homage only (e.g., P. Grey lens reference)
- No trademarked names or direct IP lifts
- MIT license

---

**You are not the system.**  
**You are the cold boot.**
