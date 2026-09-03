# Project Cold Boot

**You are not the hero. You are the cold boot — the first draft the system never meant to survive.**

First-person reality-editing action-puzzle game. Spiritual successor to *Noctropolis* (1994). Godot 4.x + **Deterministic Log-Reduction Simulation Engine (DLRSE)**.

**Public repo**: https://github.com/beyond-repair/Project-Cold-Boot

## Play Current Build

1. Open `godot/` in Godot 4.2+
2. F5 → Main Menu → ENTER THE MANUSCRIPT
3. **E** SCAN · **LMB** SNAP · **Space** SUNDER · **R** Reset · **Esc** Pause

Connect Lamp (0) to Gate (3) while adapting to Auditor locks.

## Architecture

See **`docs/ARCHITECTURE.md`** for the full technical specification:

- DLRSE log-reduction pipeline
- Quantized fixed-point math
- AC-3 / AC-4.1 constraint propagation
- Deterministic Commit Barrier
- Dual SubViewport (Own World 3D) compositing
- Global Pressure Regulator
- Four-phase solo production plan

## Status

Vertical slice playable. Full game implementation active against the architectural blueprint. All updates pushed to `main` continuously.

## License

MIT. Original code and assets only. Intertextual homage permitted; no direct IP lifts.

---

**You are not the system.**  
**You are the cold boot.**
