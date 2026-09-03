# Self-Review Checklist

## Cycles 1–4 — PASSED
## Cycle 5 — Visual Fidelity Pass (Art-Locked) — PASSED

### Cycle 5 Checklist

- [x] Runs in Godot 4.2+
- [x] Core loop intact
- [x] Materials and emission pushed toward reference art (violet causal energy, dual-layer colors, dark wet floor)
- [x] Bleed seam intensity increased to match lightning reference
- [x] Auditor / Sable materials moved toward glitch / corrupted-code look
- [x] ART_DIRECTION.md explicitly locks the provided images as sole visual authority
- [x] No gameplay regressions
- [x] Docs updated

### Remaining visual gaps (explicit)

- Still primitive meshes (spheres / capsules) — final art will replace with proper models matching the moodboard
- No full SubViewport compositor shader yet
- No screen-space glitch/scanline post on Auditor
- No hand-held tool models yet
- Lighting is improved but not yet cinematic volumetric

### Rule going forward

Every visual change must be checked against the locked reference images before commit.
