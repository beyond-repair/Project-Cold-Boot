# Vertical Slice Specification (Phase 1 Priority)

## Goal

One gray-box room that proves the full core loop is fun, responsive, and deterministic.

**Target duration**: 10–15 minutes focused gameplay.

## Required Elements

1. **SCAN** — Restorer’s Lens reveals 3–5 hidden anchors / Layer 0 seams
2. **SNAP** — Player draws causal links with Noctro-Glyph (gesture or simplified input)
3. **SUNDER** — Execute a domino chain that resolves the room state
4. **Auditor Interference** — One Auditor that predicts / locks / corrupts a pattern
5. **Sable Contact** — Brief dialogue / presence as stability anchor
6. **Bleed-Through** — Visible Layer 0 geometry erupting into Layer 1
7. **Escape** — Dimensional Anchor or desync used to exit the rewritten space

## Success Metrics

- Loop feels intentional and satisfying (not button-mashing)
- Determinism holds (identical seed + input log → identical final graph hash)
- Frame budget stays within GPR limits under load
- Player can understand the causal chain without external explanation
- At least one moment of “reality just changed because of me”

## Out of Scope for Slice

- Full 7-operator toolkit
- Multiple Kernels
- Procedural generation
- Full narrative arc
- Production art / music
- Complex multi-room traversal

## Implementation Order for Slice

1. Minimal ActiveGraph + MutationLog + DCB
2. Hard-coded room graph with 3–5 anchors
3. SCAN visualization
4. SNAP edge creation
5. SUNDER collapse + resolution
6. Simple Auditor counter
7. Bleed visual (shader or material swap)
8. Sable trigger + exit condition
9. Replay harness validation

If the slice is fun, the project has a foundation. If it is not, no additional systems will save it.
