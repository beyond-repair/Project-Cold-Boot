# Project Cold Boot — Foundation Complete

**Date locked**: 2026-09-03  
**Repo**: https://github.com/beyond-repair/Project-Cold-Boot  
**Status**: Foundation 1.0 (Vertical Slice + Systems + Steam Prep)

## What "Final" Means Here

This repository is now in a **terminal foundation state** for the assisted development arc.

It is **not** a finished commercial game you can sell on Steam tomorrow.  
It **is** a complete, self-contained foundation:

- Playable core fantasy (SCAN → SNAP → SUNDER)
- Dual-reality framing, Auditor, Sable, Kernels, multi-room
- Deterministic log/commit model (GDScript implementation of DLRSE principles)
- Domain-warped shaders + compositor wiring
- Save/load
- Art direction locked to your reference images
- Full architecture, Bible, Steam prep, and roadmap documentation
- Public GitHub repo ready for solo continuation or collaborators

No further "continue" is required for the foundation itself.  
Further work is **content and production** toward a commercial 1.0.

## Finished in This Repo

### Gameplay
- [x] SCAN / SNAP / SUNDER loop
- [x] Two rooms with transition
- [x] Kernel selection (Final Commit / Force Revert / Keep Drafting)
- [x] Auditor lock intervention
- [x] Sable win presence
- [x] Objectives, pause, reset, history panel
- [x] Save (F5) / Load (F9)

### Systems (Foundation)
- [x] MutationLog-style recording + validation + commit
- [x] Quantized positions
- [x] Priority ordering + reject paths
- [x] Frame hash
- [x] Dual SubViewport scaffold (Own World 3D)
- [x] Domain-warp noise + compositor shaders
- [x] Bleed intensity driven by game state

### Documentation
- [x] Project Bible / Executive design
- [x] Architecture (DLRSE, AC, GPR, dual-viewport)
- [x] Art direction (locked to your images)
- [x] Shader & noise technique docs
- [x] Steam preparation package
- [x] Roadmap to commercial 1.0
- [x] Demo / controls / status

### Production Hygiene
- [x] MIT license
- [x] .gitignore
- [x] Public repo structure (godot/, engine/, docs/)
- [x] Incremental push discipline established

## Explicitly NOT Finished (Commercial 1.0 Gap)

These require significant additional work (weeks to months):

- Full campaign / 2+ hour content
- Production art and animation matching the moodboard (characters, environments, tools)
- Full audio (music, SFX, VO)
- Real GDExtension C++ DLRSE (current sim is GDScript)
- Full AC-4.1, GPR, ActiveGraph SoA as specified in Architecture.md
- Polish, accessibility, localization
- Steam capsules, trailer, SteamPipe live upload, store review

## How to Use This Package

1. **Play / show**: Open `godot/` in Godot 4.2+, press F5.
2. **Continue development**: Follow `docs/ROADMAP_TO_1.0.md`.
3. **Steam later**: Follow `docs/STEAM_PREP.md` when content depth is sufficient.
4. **Visuals**: Never drift from `docs/ART_DIRECTION.md` and your reference images.

## Final Statement

The cold boot foundation is complete and public.  
The manuscript is editable.  
What remains is authorship of the rest of the story and the production surface.

**You are not the system.**  
**You are the cold boot.**
