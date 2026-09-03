# Export Notes — Windows / Steam Path

## Godot 4.2+

1. Open project (`godot/` folder).
2. Project → Export
3. Add **Windows Desktop** preset if missing.
4. Options:
   - Application / Product Name: Project Cold Boot
   - Export with debug: off for release
   - Embed PCK: optional (single exe convenience)
5. Export to e.g. `build/windows/ProjectColdBoot.exe`

## Steam

See `docs/STEAM_PREP.md`. Place the exported build under your SteamPipe content folder and upload to a private branch first.

## Android (later)

Requires debug keystore / Play signing setup. Not required for initial Steam path.
