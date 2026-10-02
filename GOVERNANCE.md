# Governance — Project-Cold-Boot

**Classification:** RESEARCH / **RUNNABLE SKETCH**  
**Claim level:** **0 — Foundation prototype**  
**Governing source:** [ADL-Governance](https://github.com/beyond-repair/ADL-Governance)  
**Sweep lock:** Sweep-127 (2026-09-08)

## Claim Level

**0 — Foundation prototype (RUNNABLE SKETCH).**  
Playable vertical slice (SCAN → SNAP → SUNDER), dual-timeline framing, domain-warp shaders, and deterministic mutation log (GDScript simulation of DLRSE principles) are implemented and documented.  
Headless smoke (`tools/smoke_test.sh`) exercises GameState + resource load without a display.

**Not** a commercial 1.0 / Steam-ready title.  
**Not** formal verification of full architecture (AC-4.1, GPR, ActiveGraph SoA) or production audio/art.

## Allowed Uses

- Solo continuation or collaborator handoff of the foundation.
- Reference for art direction, mechanics, and architecture docs.
- Demonstration of the core fantasy loop in Godot 4.2+.
- CI-less local smoke via Godot headless.

## Forbidden Uses

- Claiming validated commercial product or Steam-ready title.
- Claiming formal mathematical/physics proofs from DLRSE simulation.
- Parallel feature development that diverges from locked art/mechanics without updating ROADMAP.

## CI / Tests

No GitHub Actions workflow in this repo (token/workflow scope not assumed).  
Automated check: `./tools/smoke_test.sh` (Godot 4.2+ `--headless`).  
Manual play: open `godot/` → F5.

## Target State

RESEARCH terminal for foundation: docs complete, claims capped, smoke exits 0, structure preserved.  
Commercial 1.0 remains operator/content work outside this classification.

## History Preservation

All prior commits and docs retained. No deletions or history rewrites.
