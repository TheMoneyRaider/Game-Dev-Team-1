shader_type canvas_item;

uniform sampler2D texture_albedo;
uniform vec2 tex_size;

void fragment() {
    vec2 uv = UV;
    COLOR = texture(texture_albedo, uv);
}