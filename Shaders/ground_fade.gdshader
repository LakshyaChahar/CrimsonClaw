// shaders/ground_fade.gdshader
shader_type canvas_item;
uniform vec4 ground_color : source_color = vec4(0.04, 0.045, 0.06, 1.0);
uniform float fade_height : hint_range(0.0, 1.0) = 0.35;

void fragment() {
    float fade = smoothstep(0.0, fade_height, UV.y);
    COLOR = vec4(ground_color.rgb, fade);
}