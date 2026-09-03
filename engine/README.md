# Engine (DLRSE)

C++ GDExtension target for Godot 4.x.

## Planned Modules

- `MutationLog` — append-only typed records
- `GraphExecutionScheduler` (GES)
- `AC3Emitter` / `AC4Emitter`
- `AuditorLogInterpreter`
- `DeterministicCommitBarrier` (DCB)
- `ActiveGraph` (SoA + partitions + dormant promotion)
- `GlobalPressureRegulator` (GPR)
- `KernelBindingTable` (KBT)
- `ZeroAllocPool`

## Build Notes

Target: Godot 4.x + godot-cpp. Mobile-first (Android mid-range budget). All emission log-only. DCB is the sole writer of ActiveGraph.

See `docs/DLRSE.md` for full invariants and pipeline.
