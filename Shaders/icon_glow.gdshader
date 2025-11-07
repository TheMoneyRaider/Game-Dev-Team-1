shader_type canvas_item;
uniform float u_time = 0.0;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    float pulse = 0.5 + 0.5 * sin(u_time * 3.0);
    COLOR = texture(TEXTURE, UV) * base_color * (0.8 + 0.2 * pulse);
}