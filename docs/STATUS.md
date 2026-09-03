# Project Status

**Version**: 1.9.8  
**Repository**: https://github.com/beyond-repair/Project-Cold-Boot

## Working (Playable)

- Vertical slice: SCAN → SNAP → SUNDER
- Two rooms, Kernel selection, Auditor, Sable
- Dual SubViewport scaffold + domain-warped shaders
- MutationLog history, validation, quantized positions
- Art direction locked to your reference images

## Steam Preparation

- `docs/STEAM_PREP.md` — checklist, store draft, depot structure, build workflow
- `docs/ROADMAP_TO_1.0.md` — concrete path to a shippable / Early Access build

## Standing Rules

1. Push every meaningful increment to `main`.
2. Visuals stay true to the locked reference art.
3. Do not claim "complete" until Phase E criteria are met.

## Immediate Next Build Steps

1. Wire domain_warp_compositor to the dual SubViewports (visible bleed)
2. MutationLog save/load to disk
3. Options menu stub
4. More rooms / stronger single-session loop
5. Windows export preset + first SteamPipe trial when content is deeper
