shader_type canvas_item;

/*
  Domain-Warped Dual-Layer Compositor — Project Cold Boot
  Samples two layer textures and produces a noise-driven lightning bleed seam.
  Matches locked art direction: violet electrical tear between Vesper / Necropolis.
*/

uniform sampler2D layer0_tex : source_color, hint_default_black; // Necropolis (1994)
uniform sampler2D layer1_tex : source_color, hint_default_black; // Vesper (2026)
uniform float bleed_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float seam_width : hint_range(0.001, 0.15) = 0.035;
uniform float warp_strength : hint_range(0.0, 1.5) = 0.55;
uniform float noise_scale : hint_range(0.5, 15.0) = 4.0;
uniform float time_speed : hint_range(0.0, 1.0) = 0.07;
uniform vec3 violet_seam : source_color = vec3(0.82, 0.35, 1.0);
uniform float seam_emission : hint_range(0.0, 10.0) = 4.5;

// Vertical stretch makes the seam read as lightning
uniform vec2 stretch = vec2(1.2, 9.5);

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

float domain_warped_noise(vec2 p) {
	vec2 q = vec2(
		value_noise(p),
		value_noise(p + vec2(5.2, 1.3))
	);
	vec2 r = vec2(
		value_noise(p + warp_strength * q + vec2(1.7, 9.2)),
		value_noise(p + warp_strength * q + vec2(8.3, 2.8))
	);
	return value_noise(p + warp_strength * r);
}

void fragment() {
	vec2 uv = UV;

	// Domain-warped, vertically stretched noise for lightning character
	vec2 noise_uv = uv * stretch * noise_scale;
	noise_uv.x += TIME * time_speed;
	float n = domain_warped_noise(noise_uv);

	// Soft world mask
	float mask = smoothstep(bleed_intensity - seam_width, bleed_intensity + seam_width, n);

	vec3 col0 = texture(layer0_tex, uv).rgb; // Necropolis
	vec3 col1 = texture(layer1_tex, uv).rgb; // Vesper
	vec3 base = mix(col1, col0, mask);

	// Emissive violet lightning seam (core of the reference look)
	float edge = smoothstep(bleed_intensity - seam_width, bleed_intensity, n)
	           - smoothstep(bleed_intensity, bleed_intensity + seam_width, n);
	// Sharpen and boost
	edge = pow(edge, 0.7);
	base += edge * violet_seam * seam_emission;

	// Subtle secondary micro-arcs
	float micro = value_noise(noise_uv * 3.5 + TIME * 0.3);
	base += edge * micro * violet_seam * 1.2;

	COLOR = vec4(base, 1.0);
}
