# Architectural Analysis and Implementation Framework for Project Cold Boot

**A Deterministic Dual-Reality Simulation Engine in Godot 4**

*Canonical technical reference — integrated into Project Bible v1.9+*

## 1. Engine Architecture and Deterministic Log-Reduction Execution Model

The core architecture centers on the **Deterministic Log-Reduction Simulation Engine (DLRSE)**, engineered as a native extension using Godot 4’s GDExtension C++ interface (godot-cpp + SCons).

Standard Godot patterns rely on imperative state mutations inside the scene tree. This introduces non-deterministic frame ordering and floating-point variance across platforms. DLRSE decouples simulation from the scene tree: all critical state lives in native C++ and is advanced only through a unidirectional pipeline.

**Pipeline**

```
Input Events
    ↓
Gameplay Event Subsystem → standardized input vectors
    ↓
Constraint Propagation Engine (AC-3 / AC-4.1)
    +
Adaptive Auditor AI (counter-constraint injection)
    ↓
MutationRecords (immutable, sequential)
    ↓
Deterministic Commit Barrier (DCB) — validation + single-writer commit
    ↓
ActiveGraph (authoritative state)
    ↓
Render / Haptics / Narrative Projection
```

**Core equation**

```
State = Reduce(Ordered(MutationLog))
```

### Fixed-Point Quantization

Cross-platform determinism requires elimination of IEEE-754 drift. All state-critical spatial values use quantized integer representation:

```cpp
struct QuantizedVector3 {
    int32_t x, y, z;
    static const int32_t SCALE_FACTOR = 1000;

    QuantizedVector3(float fx, float fy, float fz)
        : x(static_cast<int32_t>(fx * SCALE_FACTOR)),
          y(static_cast<int32_t>(fy * SCALE_FACTOR)),
          z(static_cast<int32_t>(fz * SCALE_FACTOR)) {}

    Vector3 to_float() const {
        return Vector3(
            static_cast<float>(x) / SCALE_FACTOR,
            static_cast<float>(y) / SCALE_FACTOR,
            static_cast<float>(z) / SCALE_FACTOR);
    }
};
```

Subsystems never mutate node properties directly. They emit `MutationRecord`s only.

### Deterministic Commit Barrier (DCB)

Single-writer transactional gateway. Intercepts all records, validates against invariants (budget, partitions, kernel hash, pressure, graph sanity, hashes), then commits to ActiveGraph or rolls back. Mirrors delta-state networking patterns: minimal temporal differentials, instant rollback, full reproducibility.

| Layer              | DLRSE Native                  | Standard Godot Node Pattern      | Benefit                          |
|--------------------|-------------------------------|----------------------------------|----------------------------------|
| State Storage      | Flat contiguous C++ buffers   | Reference-counted Node trees     | Cache coherency, no GC           |
| State Mutation     | Log-only emission             | Direct property writes           | Replay + rollback                |
| Arithmetic         | Quantized / integer vectors   | Platform float                   | No cross-platform drift          |
| Execution Control  | Time-sliced work-stealing     | `_process` / `_physics_process`  | Hard frame-budget compliance     |

## 2. Graph Constraint Propagation: AC-3 and AC-4.1

Puzzles are dynamic CSPs `(V, D, C)`. SCAN observes variables, SNAP proposes arcs, SUNDER runs propagation.

- **AC-3** (coarse): queue of arcs, re-evaluate on domain change. Complexity \(\mathcal{O}(e \cdot d^3)\). Low memory, used at setup.
- **AC-4 / AC-4.1** (fine): support counters + inverted support sets. Complexity \(\mathcal{O}(e \cdot d^2)\) or better on sparse graphs. Used at runtime.

GPR enforces time-sliced execution (\(T_{\text{frame}} \le 10\,\text{ms}\)) with priority queues: Causal → Physical → Narrative → Background. Excess work carries deterministically to the next frame.

Empty domain after propagation = contradiction → immediate delta rollback + violet fracture feedback.

## 3. Dual-World Visual Pipeline

Layer 0 (1994 Necropolis) and Layer 1 (2026 Vesper City) are isolated via two `SubViewport`s with **Own World 3D = true**. This prevents light / environment / physics bleed.

```
Main Compositor Canvas
├── SubViewport_Layer0 (Own World 3D)
│   ├── Camera3D_Layer0 (synced)
│   ├── WorldEnvironment_Layer0 (gothic, fog)
│   └── Necropolis geometry
└── SubViewport_Layer1 (Own World 3D)
    ├── Camera3D_Layer1 (synced)
    ├── WorldEnvironment_Layer1 (neon, bloom)
    └── Vesper geometry
```

A full-screen spatial shader composites both color + depth textures using noise-driven bleed masks and emissive violet seam highlighting.

Target budgets: ~3.5 ms GPU per layer, ~1.0 ms compositor.

## 4. Gameplay Mechanics and Adaptive Constraint AI

**SCAN** — graph observation / highlight latent nodes.  
**SNAP** — propose binary arcs (candidate constraints).  
**SUNDER** — DCB + AC-4.1 evaluation; commit or rollback.

**Auditor Units** are constraint adversaries, not pathfinding agents. They analyze centrality, inject domain restrictions, and force contradictions on illegal SUNDER attempts.

**Gear**
- Shadow-Skin: local collision-layer modulation (phase between layers).
- Noctro-Glyph: domain extension / temporary Auditor bypass.
- Dimensional Anchor: cross-layer spatial locks + momentum continuity.

## 5. Aesthetic, Sonic, and Production Architecture

Visual pillars (ink-gothic, sterile cyber-noir, violet causal energy, lightning seams) are driven by the same state that the DCB commits. Audio mirrors phase: filtered observation (SCAN) → syncopated linking (SNAP) → impact or tape-stop fracture (SUNDER success/failure).

**Four-Phase Solo Production**
1. Vertical Slice — prove SCAN/SNAP/SUNDER + dual-viewport + basic DLRSE.
2. Core Tooling — graph editor, replay viewer, mutation inspector.
3. Procedural Content — tetrahedral rule fields + solver-guided generation.
4. Optimization & Polish — GPR tuning, shaders, audio, exports.

| Stage                        | Module                        | Budget Goal      |
|-----------------------------|-------------------------------|------------------|
| Constraint Propagation      | AC-4.1 work-stealing          | ≤ 1.8 ms CPU     |
| DCB Validation              | Single-writer barrier         | ≤ 0.5 ms CPU     |
| Physics / Quantized Motion  | Integer / fixed-point        | ≤ 2.5 ms CPU     |
| Dual SubViewport            | Own World 3D passes           | ≤ 7.0 ms GPU     |
| Compositor Shader           | Screen-space composite        | ≤ 1.0 ms GPU     |
| GPR Reserve                 | Safety margin                 | ≤ 3.8 ms CPU     |

## 6. Conclusions

DLRSE + AC-4.1 + dual-SubViewport isolation + GPR yields a verifiable, mobile-viable, dual-reality puzzle engine. Narrative themes (editing the manuscript, resisting the Compiler, staying unreadable) are realized directly in the log-reduction, constraint, and compositing machinery.

This document is the binding technical specification for all implementation work.
