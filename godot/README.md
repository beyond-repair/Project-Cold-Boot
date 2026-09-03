# Godot Project

Godot 4.x project root (to be initialized).

## Planned Structure

```
godot/
├── project.godot
├── scenes/
│   ├── vertical_slice/
│   └── common/
├── scripts/
│   ├── systems/
│   └── ui/
├── resources/
├── shaders/          # dual-layer, ink, bleed, causal energy
└── addons/            # GDExtension bindings
```

## Dual-Layer Rendering Notes

- Layer 0 (Necropolis): ink-drenched, procedural noise, low-res gothic
- Layer 1 (Vesper City): clean vectors, high-contrast neon
- Bleed: stencil masks + ViewportTexture blending driven by Identity Drift / entropy
- Causal energy: violet particle / line overlays for SNAP chains

Initialize with `godot --path . --editor` once project.godot is present.
