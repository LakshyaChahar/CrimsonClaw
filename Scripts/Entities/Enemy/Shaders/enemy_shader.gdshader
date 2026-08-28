shader_type canvas_item;

uniform float burn_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fire_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (burn_intensity > 0.0 && tex_color.a > 0.1) {
        float alpha = tex_color.a;
        
        // Detect sprite borders for a clean outline (no scrolling)
        float n_up = texture(TEXTURE, UV + vec2(0.0, -TEXTURE_PIXEL_SIZE.y * 2.0)).a;
        float n_down = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a;
        float n_left = texture(TEXTURE, UV + vec2(-TEXTURE_PIXEL_SIZE.x * 2.0, 0.0)).a;
        float n_right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x * 2.0, 0.0)).a;
        
        float is_edge = (n_up < 0.1 || n_down < 0.1 || n_left < 0.1 || n_right < 0.1) ? 1.0 : 0.0;
        
        if (is_edge > 0.5) {
            // Steady, glowing fire border with a subtle pulse (no top-to-bottom movement)
            float border_pulse = 0.75 + 0.25 * sin(TIME * 10.0);
            vec3 fire_border = fire_color.rgb * 1.8 * border_pulse;
            COLOR = vec4(fire_border, alpha);
        } else {
            // Interior cleanly blinks back and forth between normal texture and orange
            float blink = step(0.0, sin(TIME * 10.0));
            vec3 interior_color = mix(tex_color.rgb, fire_color.rgb * 1.5, blink * burn_intensity);
            COLOR = vec4(interior_color, alpha);
        }
    } else {
        COLOR = tex_color;
    }
}