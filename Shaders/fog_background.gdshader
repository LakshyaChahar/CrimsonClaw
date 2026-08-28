shader_type canvas_item;

// Dark gothic sky gradient with slowly drifting fog, matching the
// teal/near-black forest tone from the gameplay screenshots.

uniform vec4 color_top : source_color = vec4(0.10, 0.15, 0.20, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.015, 0.03, 0.05, 1.0);
uniform vec4 fog_color : source_color = vec4(0.09, 0.20, 0.22, 0.4);
uniform float fog_speed : hint_range(0.0, 1.0) = 0.025;
uniform float fog_scale : hint_range(1.0, 20.0) = 5.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        v += noise(p) * amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    vec3 sky = mix(color_bottom.rgb, color_top.rgb, uv.y);

    vec2 fog_uv = uv * fog_scale + vec2(TIME * fog_speed, -TIME * fog_speed * 0.15);
    float n = fbm(fog_uv);

    // Fog sits in a horizontal band roughly where the tree canopy is.
    float band = smoothstep(0.10, 0.45, uv.y) * (1.0 - smoothstep(0.55, 1.0, uv.y));
    float fog_mask = smoothstep(0.35, 0.9, n) * band;

    vec3 col = mix(sky, fog_color.rgb, clamp(fog_mask * fog_color.a * 2.0, 0.0, 1.0));
    COLOR = vec4(col, 1.0);
}
