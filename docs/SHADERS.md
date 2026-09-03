# Shader Techniques — Project Cold Boot

Canonical reference for Godot 4 shaders aligned to locked art direction and Architecture document.

## 1. Dual-Layer Screen-Space Compositor

Full-screen pass sampling two SubViewport textures (Own World 3D) + noise mask to create the lightning bleed seam.

Key uniforms:
- layer0_tex / layer1_tex
- noise_tex
- bleed_intensity
- seam_width
- violet_seam color (locked to reference)

Produces the vertical electrical tear between 2026 Vesper City and 1994 Necropolis.

## 2. Violet Causal Energy

Unshaded / additive material for nodes, SNAP chains, and SUNDER bursts.

- High emission
- Animated pulse
- Fresnel rim
- Color locked to electric violet / magenta-purple from reference art

## 3. Ink-Decay / Bit-Rot

World-position or screen-space noise that darkens, desaturates, and adds violet rot. Driven by entropy / Bit-Rot values from the simulation.

## 4. Auditor Glitch

UV distortion + scanlines + channel separation. Strength driven by Auditor state (prediction / lock).

## 5. Implementation Order

1. Compositor shader sampling existing SubViewports
2. Shared CausalEnergy material
3. Ink-decay overlay
4. Auditor glitch pass

All outputs must match the locked reference images.
