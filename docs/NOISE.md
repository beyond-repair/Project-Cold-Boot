# Screen-Space & Procedural Noise — Project Cold Boot

## Implemented Shaders (Cycle 6)

### `godot/shaders/domain_warp_noise.gdshader`
Spatial, additive. Domain-warped value noise for:
- Violet causal energy on nodes / surfaces
- Living ink-decay overlays
- Fresnel-enhanced presence

Parameters: `energy_color`, `intensity`, `warp_strength`, `noise_scale`, `time_speed`, `pulse_speed`, `fresnel_power`.

### `godot/shaders/domain_warp_compositor.gdshader`
CanvasItem full-screen compositor. Samples two layer textures and produces a domain-warped, vertically stretched lightning bleed seam.

Parameters: `layer0_tex`, `layer1_tex`, `bleed_intensity`, `seam_width`, `warp_strength`, `noise_scale`, `time_speed`, `violet_seam`, `seam_emission`, `stretch`.

## Domain Warping Summary

1. Generate low-frequency noise field Q.
2. Use Q to offset the sampling coordinates of a second noise field R.
3. Optionally warp again.
4. Final noise value is sampled at the twice-warped coordinate.

This produces the folding, liquid, unstable look required for the reference lightning tear and ink-decay.

## Usage Notes

- Assign the compositor shader to a full-screen ColorRect / TextureRect that sits above the dual SubViewports.
- Feed `SubViewport_Layer0` and `SubViewport_Layer1` as `ViewportTexture`s into `layer0_tex` / `layer1_tex`.
- Drive `bleed_intensity` from SCAN state, entropy, or Kernel.
- Keep `violet_seam` locked to the reference electric violet.

## Performance

Domain warping costs ~3 value-noise evaluations. Acceptable for full-screen on mid-range Android when the rest of the frame is within GPR budget. Under extreme pressure, fall back to a single texture sample.
