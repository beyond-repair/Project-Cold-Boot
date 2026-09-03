# DLRSE — Deterministic Log-Reduction Simulation Engine

## Overview

All gameplay reduces to a live causal graph (Nodes / Edges / Fields). Player actions and system reactions emit pure event records. A single Deterministic Commit Barrier reduces the ordered log into the authoritative ActiveGraph state.

**Core Equation**

```
State = Reduce(Ordered(MutationLog))
```

## Pipeline

```
Input (Player / Lens / SUNDER)
    ↓
GPR (pressure snapshot, frozen per frame)
    ↓
GES (operator emission → MutationLog)
    ↓
AC-3 / AC-4.1 (constraint projection → MutationLog)
    ↓
Auditor (adversarial inference → MutationLog)
    ↓
KBT (read-only Kernel snapshot)
    ↓
MutationLog (append-only)
    ↓
DCB (deterministic sort + validate + serial apply)
    ↓
ActiveGraph (committed SoA state)
    ↓
Render / Physics / Haptics / Narrative Projection
```

## Key Components

### MutationLog
Append-only, strictly typed records. Payload restricted to fixed-size float32 / int32 / bool arrays for cross-platform determinism.

### GES (Graph Execution Scheduler)
Operator emission layer. Budget-aware, pressure-scaled. Emits only; never mutates ActiveGraph.

### AC-3 / AC-4.1 Emitter
Log-only constraint projection. Partition-aware (causal / physical / narrative / hidden). Time-sliced, priority-partitioned, lazy propagation (AC-4.1). Work-stealing across frames.

### Auditor Log Interpreter
Markov order 2–3 pattern tracking + bounded entropy noise. Emits AUD_* records (lock, corrupt, inject false path, force creative).

### DCB (Deterministic Commit Barrier)
Single-writer. Sorts by (frame_id, subsystem_priority, sequence). Validates budget, partitions, kernel hash, pressure, graph sanity, hashes. Serial reduction into backbuffer + atomic swap. Fail-fast rollback.

### ActiveGraph
Structure-of-Arrays layout. Partition indices. Dormant promotion via spatial hash. Double-buffered for DCB swap. Max 512 active nodes / 2048 edges.

### GPR (Global Pressure Regulator)
Computes pressure_level ∈ [0.0, 1.0] each frame. Scales mutation budget, AC iterations, Auditor depth. Regimes: Full Fidelity / Throttled / Constrained. Enforces ≤10 ms CPU simulation hard cap.

### KBT (Kernel Binding Table)
Data-driven registry. Atomic rebinding of shaders, physics, Auditor heuristics, entropy caps on Kernel commit.

## Determinism Invariants

1. Log-only emission
2. Single-writer DCB
3. Pure reduction functions
4. Strict payload typing
5. Total ordering + atomic counters
6. Read-only snapshots during emission
7. Hash validation (incremental rolling + full XXH3)
8. ZeroAllocPool / static allocation
9. GPR backpressure with graceful degradation
10. Kernel snapshot atomicity

## Frame Budget (CPU Simulation)

Hard cap: ≤10 ms sustained.

| Subsystem              | Base Budget     | GPR Scaling                  |
|------------------------|-----------------|------------------------------|
| Graph + GES            | 4.0–5.5 ms     | mutation_budget 64 → 16      |
| AC-3/AC-4.1            | 2.0–3.0 ms     | iterations 12 → 3            |
| Auditor                | 1.0–1.5 ms     | depth 8 → 2                  |
| Physics / Anchors      | 1.5–2.0 ms     | reduced rate                 |
| Entropy / KBT          | 0.5–1.0 ms     | background / freeze          |
| **Total**              | **≤10.0 ms**   | Linear pressure scaling      |

## Engineering Constitution

Any new subsystem must satisfy all of the above invariants and pass the DCB validation suite + replay harness before integration.
