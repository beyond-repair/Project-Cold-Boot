shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled;

/*
  Domain-Warped Noise — Project Cold Boot
  Use for violet causal energy, ink-decay overlays, living surfaces.
  Art direction: electric violet, organic-digital instability.
*/

uniform vec3 energy_color : source_color = vec3(0.78, 0.32, 1.0);
uniform float intensity : hint_range(0.0, 12.0) = 3.5;
uniform float warp_strength : hint_range(0.0, 2.0) = 0.65;
uniform float noise_scale : hint_range(0.5, 20.0) = 3.5;
uniform float time_speed : hint_range(0.0, 2.0) = 0.15;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.2;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.8;

// --- Hash & Value Noise ---
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// --- Domain Warping ---
// Two-octave warp for folding ink / unstable reality look
float domain_warped_noise(vec2 p) {
	vec2 q = vec2(
		value_noise(p + vec2(0.0, 0.0)),
		value_noise(p + vec2(5.2, 1.3))
	);
	vec2 r = vec2(
		value_noise(p + warp_strength * q + vec2(1.7, 9.2)),
		value_noise(p + warp_strength * q + vec2(8.3, 2.8))
	);
	return value_noise(p + warp_strength * r);
}

void fragment() {
	// World-space XZ so noise is stable across the surface
	vec2 uv = NODE_POSITION_WORLD.xz * noise_scale;
	uv += TIME * time_speed;

	float n = domain_warped_noise(uv);
	float pulse = 0.55 + 0.45 * sin(TIME * pulse_speed + n * 6.2831);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	vec3 col = energy_color * (n * 0.7 + 0.3) * pulse;
	col += energy_color * fres * 0.9;

	ALBEDO = col;
	EMISSION = col * intensity * (0.6 + n * 0.8);
	ALPHA = clamp(0.4 + n * 0.6 + fres * 0.3, 0.0, 1.0);
}
