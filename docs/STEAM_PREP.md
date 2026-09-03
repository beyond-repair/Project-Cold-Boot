# Steam Preparation Package — Project Cold Boot

**Goal**: Make the project ready for a Steam Next Fest / Early Access or 1.0 upload path.

## Current Reality

The game is a **playable vertical slice** (SCAN → SNAP → SUNDER, two rooms, Kernels, Auditor, Sable, dual-layer scaffold, domain-warped shaders). It is **not** yet a full commercial product. This document prepares the packaging, store presence, and build pipeline so that when content and polish land, Steam submission is straightforward.

## 1. Steam Direct Requirements (Checklist)

- [ ] Steamworks partner account (pay the one-time fee)
- [ ] AppID created in Steamworks
- [ ] Store page draft (see below)
- [ ] Capsule images (main capsule 616×353, small 231×87, header 460×215, library 600×900, etc.)
- [ ] At least 5 screenshots matching the locked art direction
- [ ] Trailer (30–90s) showing SCAN / SNAP / SUNDER + dual reality + Auditor
- [ ] Build uploaded via SteamPipe (Windows first; Linux/Mac later)
- [ ] Age rating questionnaire (likely Teen / PEGI 12 equivalent — stylized violence, mild horror)
- [ ] Privacy policy URL (required if any online features or analytics)
- [ ] Supported languages (English minimum)
- [ ] System requirements

## 2. Recommended Depot / Build Structure

```
steam/
├── app_build.vdf          # SteamPipe build script
├── depot_build.vdf
├── content/
│   └── windows/
│       ├── ProjectColdBoot.exe
│       ├── data.pck (or Godot exported files)
│       └── ...
├── scripts/
│   └── upload.sh
└── store/
    ├── capsules/
    ├── screenshots/
    └── copy/
```

Godot 4 export presets should target:
- Windows Desktop (priority 1)
- Linux (priority 2)
- Android (later / separate)

Use **Export PCK/ZIP** or full project export. Enable **Embed PCK** for single-exe convenience if desired.

## 3. Store Page Draft (Short)

**Title**  
Project Cold Boot

**Short description**  
Rewrite reality. Outsmart the Compiler. A first-person reality-editing action-puzzle where you SCAN anchors, SNAP causal links, and SUNDER the chain while adaptive Auditors lock down anything predictable.

**Long description (draft)**  
You are not the hero. You are the cold boot — the first draft the system never meant to survive.

In Project Cold Boot you manipulate causality across two bleeding timelines: the sterile neon of 2026 Vesper City and the ink-drenched gothic ruins of the 1994 Necropolis. Reveal hidden anchors, draw luminous violet connections, and execute chain reactions that rewrite the world. Adaptive Auditor Units predict your patterns and shut down repetition. Stay unreadable.

- Core loop: SCAN → SNAP → SUNDER
- Dual-reality bleed with lightning seams
- Adaptive constraint adversaries (not conventional enemies)
- Kernel choices that reconfigure the rules
- Deterministic simulation foundation (replayable, fair)

Built in Godot 4. Visual identity locked to high-contrast cyber-noir and gothic ink.

**Tags (suggested)**  
Puzzle, Action, Cyberpunk, First-Person, Singleplayer, Atmospheric, Story Rich, Indie, Godot

**Age rating notes**  
Stylized violence, mild horror imagery, no gore focus, no sexual content.

## 4. Build & Upload Workflow (When Ready)

1. Godot → Project → Export → Windows Desktop
2. Place build in `steam/content/windows/`
3. Fill AppID and depot IDs in the VDF scripts
4. Run SteamCMD + `app_build.vdf`
5. Set build live on a test branch first
6. Playtest the Steam build extensively (different machines, offline mode, cloud if enabled)

## 5. What Still Must Be Built Before Steam Sale

See `docs/ROADMAP_TO_1.0.md`. Minimum viable Steam Early Access bar:

- 2–4 hour campaign or robust roguelite/puzzle loop
- Consistent art pass matching the locked reference images
- Options menu, key rebinding, resolution, volume
- Save/load
- Stable performance on mid-range hardware
- No game-breaking bugs
- Trailer + capsules + screenshots

## 6. Legal / Branding

- Original code and assets only
- Intertextual homage to *Noctropolis* is fine; no trademarked names or direct IP lifts
- MIT license currently in repo — review if you need different commercial terms later
