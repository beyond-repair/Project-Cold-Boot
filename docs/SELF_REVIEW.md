# Self-Review Checklist

## Cycles 1–3 — PASSED
## Cycle 4 — Second room + Kernel stub — PASSED

### Cycle 4 Checklist

- [x] Runs in Godot 4.2+
- [x] SCAN → SNAP → SUNDER functional in both rooms
- [x] Two distinct room layouts
- [x] Transition via N after win
- [x] Kernel selection (1/2/3) changes Auditor aggressiveness
- [x] Kernel name + room status visible in UI
- [x] History + validation + quantized positions retained
- [x] Dual SubViewport scaffold retained
- [x] Docs updated
- [x] No critical regressions

### Known limitations

- Rooms are still gray-box graphs (no unique art per room yet)
- Kernel only modulates Auditor threshold (not full KBT rebind)
- No persistent save between sessions
- Compositor shader not yet sampling SubViewports
- Still GDScript

### Next

5. File-based MutationLog save/load + simple replay
6. Compositor shader for dual-layer bleed
7. Basic Gear distinction (Noctro-Glyph vs Gravity Anchor input)
8. GDExtension skeleton
