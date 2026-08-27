shader_type canvas_item;
uniform sampler2D noise_texture;

uniform float dissolve_amount : hint_range(-0.1, 1.0) = -0.1;
uniform vec4 burn_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float noise_val = texture(noise_texture, UV).r;
    
    if (noise_val < dissolve_amount) {
        discard;
    }

    if (noise_val < dissolve_amount + 0.08) {
        tex_color.rgb = mix(tex_color.rgb, burn_color.rgb, 0.8);
    }
    COLOR = tex_color;
}