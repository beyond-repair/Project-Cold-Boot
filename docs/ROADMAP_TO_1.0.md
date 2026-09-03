# Roadmap to 1.0 / Steam — Project Cold Boot

Honest path from current vertical slice to a shippable game.

## Phase A — Solidify the Slice (now → near term)

- [x] Playable SCAN → SNAP → SUNDER
- [x] Two rooms + Kernel stub
- [x] Dual SubViewport scaffold
- [x] Domain-warped noise shaders
- [ ] Wire compositor shader to SubViewports (visible dual-layer bleed)
- [ ] MutationLog file save/load + replay
- [ ] Basic options (volume, fullscreen, mouse sensitivity)
- [ ] Proper win / fail feedback and short Sable lines

## Phase B — Content Vertical (minimum interesting campaign)

- [ ] 6–12 authored rooms or one longer multi-stage manuscript fragment
- [ ] Full Gear of the Ancients usable (Shadow-Skin, Noctro-Glyph, Dimensional Anchor)
- [ ] At least two distinct Auditor behaviors
- [ ] Kernel choice has clear, readable consequences
- [ ] One mid-game and one ending beat with Sable

## Phase C — Systems & Feel

- [ ] Real ActiveGraph / DCB path closer to Architecture.md (or document the GDScript subset as intentional)
- [ ] Causal energy + ink-decay materials on all relevant meshes
- [ ] Haptics / controller support
- [ ] Performance pass (GPR-minded)

## Phase D — Production

- [ ] Art pass: replace gray-box with assets matching locked reference images
- [ ] Audio: SCAN / SNAP / SUNDER stingers + ambient + Sable VO placeholder or final
- [ ] Main menu, pause, credits, accessibility options
- [ ] Localization readiness (English first)

## Phase E — Steam

- [ ] Windows build via Godot export
- [ ] Steamworks AppID + SteamPipe scripts
- [ ] Capsules, screenshots, trailer
- [ ] Store page + pricing + age rating
- [ ] Closed playtest → Next Fest or Early Access decision → 1.0

## Scope Discipline

Do not expand foundational engine systems until the vertical slice is fun and visually on-model. Experience drives systems. The Architecture document remains the north star; implementation can stay GDScript longer if it ships the fantasy.
