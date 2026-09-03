# Project Status

**Version**: 1.8 + Vertical Slice Demo  
**Repository**: https://github.com/beyond-repair/Project-Cold-Boot  
**Owner**: beyond-repair

## Locked

- Core vision & design philosophy
- SCAN → SNAP → SUNDER loop
- DLRSE architecture & determinism invariants
- DCB validation suite
- GPR frame budget model
- AC-3 / AC-4.1 scheduling approach
- Gear of the Ancients (Items 1–3)
- Solo-dev execution directive
- Engineering Constitution
- Visual language (GDD + moodboard)

## Working Demo (Now)

- Godot 4.x vertical-slice project under `godot/`
- Minimal MutationLog + commit simulation in GDScript
- Playable SCAN / SNAP / SUNDER loop with Auditor lock + Sable reveal
- Dual-layer node colors + bleed seam
- Frame hash feedback
- See `docs/DEMO.md` for run instructions

## Next Immediate

1. Playtest and tighten the gray-box feel
2. Replace GDScript simulation with real ActiveGraph / DCB stubs
3. Dual-layer material / simple ink-bleed shader
4. Replay harness (record input + MutationLog, verify hash)

## Out of Scope Until Slice Feels Good

- Full C++ GDExtension
- Procedural generation
- Production art / audio
- Multiple Kernels
