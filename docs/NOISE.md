# Screen-Space Noise Generation — Project Cold Boot

Noise is a core visual primitive for bleed seams, ink-decay, Auditor glitch, and living causal energy.

## Methods

### Value Noise
Fast lattice noise. Good base for bleed masks and soft decay.

### Gradient / Perlin-Style
Smoother, more organic. Better for flowing ink.

### Texture-Based (Preferred for Full-Screen)
`NoiseTexture2D` or pre-baked tiling texture. Lowest cost for compositor.

### Domain Warping
Warp one noise with another for folding ink and unstable seam character.

### Screen-Space Patterns
- Scanlines + noise → Auditor
- Vertically stretched noise → lightning tear seam

## Performance (Mobile)

| Method              | Cost    | Use                          |
|---------------------|---------|------------------------------|
| Texture sample      | Lowest  | Full-screen compositor       |
| Value noise (1 oct) | Low     | Per-object detail            |
| Gradient + warp     | Medium  | Hero effects                 |
| Many octaves        | High    | Avoid on mobile              |

GPR can reduce octaves or force texture-only under pressure.

## Integration

Expose `bleed_intensity`, `noise_scale`, `noise_speed` so SCAN, entropy, and Kernel can drive the visuals.

Art rule: resulting noise must produce the same class of violet lightning tear and ink-like instability shown in the reference images.
