shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.5;
uniform float radius : hint_range(0.0, 2.0) = 0.85;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv * vec2(1.0, 0.8));
    float vig = smoothstep(radius, radius - 0.6, dist);
    float alpha = clamp((1.0 - vig) * intensity, 0.0, 1.0) * vignette_color.a;
    COLOR = vec4(vignette_color.rgb, alpha);
}
