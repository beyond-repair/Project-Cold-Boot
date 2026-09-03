# Project Status

**Version**: 1.9 — Architecture Document Integrated + Full Game Implementation Active  
**Repository**: https://github.com/beyond-repair/Project-Cold-Boot

## Canonical References

- `docs/ARCHITECTURE.md` — Full DLRSE / AC-4.1 / dual-viewport / GPR paper (authoritative)
- `docs/BIBLE.md` — Executive design bible
- `docs/DEMO.md` — How to run current build
- `docs/ART_DIRECTION.md` — Visual language from GDD + moodboard

## Working Now

- Main menu → vertical slice
- Playable SCAN → SNAP → SUNDER with Auditor, win state, Sable, pause/reset
- Dual-layer node colors + bleed seam + frame hash
- Godot 4.2+ project under `godot/`

## Production Phases (from Architecture)

1. **Vertical Slice** (in progress → hardening) — core loop + basic dual view + DLRSE simulation
2. **Core Tooling** — graph editor, replay viewer, mutation inspector
3. **Procedural Content** — rule-field generation + solver heuristics
4. **Optimization & Polish** — GPR, shaders, audio, exports, 1.0

## Immediate Implementation Queue

- Expand GDScript simulation toward quantized / validated DCB patterns from ARCHITECTURE.md
- Dual SubViewport prototype (Own World 3D) for true Layer 0 / Layer 1 isolation
- Second room + transition
- Noctro-Glyph vs Gravity Anchor distinction
- MutationLog replay / save
- Kernel selection
- Full ActiveGraph + AC-4.1 path (GDExtension target)

Architecture is locked. Implementation continues until the complete game ships.
