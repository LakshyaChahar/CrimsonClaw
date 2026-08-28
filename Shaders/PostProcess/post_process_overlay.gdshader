shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Vignette Settings
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.65;
uniform vec4 vignette_color : source_color = vec4(0.04, 0.02, 0.07, 1.0);

// Chromatic Aberration (Lens Distortion)
uniform float aberration_amount : hint_range(0.0, 10.0) = 1.2;

// Color Adjustment
uniform float saturation : hint_range(0.0, 2.0) = 1.12;
uniform float contrast : hint_range(0.5, 2.0) = 1.08;
uniform float brightness : hint_range(-0.5, 0.5) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0, 0.97, 0.94, 1.0);

// Subtle Film Grain
uniform float grain_amount : hint_range(0.0, 0.1) = 0.02;

float pseudo_random(vec2 uv, float time) {
	return fract(sin(dot(uv + vec2(time * 0.1, time * 0.1), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center_offset = uv - vec2(0.5);
	float dist = length(center_offset);

	// 1. Chromatic Aberration
	vec2 ab_shift = center_offset * (aberration_amount * 0.002);
	float r = texture(screen_texture, uv - ab_shift).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + ab_shift).b;
	vec3 color = vec3(r, g, b);

	// 2. Brightness, Contrast & Saturation
	color = (color - vec3(0.5)) * contrast + vec3(0.5) + vec3(brightness);
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luminance), color, saturation);
	color *= tint_color.rgb;

	// 3. Smooth Vignette
	float vignette = smoothstep(0.5, 0.5 - vignette_intensity, dist);
	vec3 v_color = mix(vignette_color.rgb, color, vignette);
	color = mix(color, v_color, vignette_opacity);

	// 4. Subtle Film Grain
	float noise = (pseudo_random(uv, TIME) - 0.5) * grain_amount;
	color += noise;

	COLOR = vec4(color, 1.0);
}
