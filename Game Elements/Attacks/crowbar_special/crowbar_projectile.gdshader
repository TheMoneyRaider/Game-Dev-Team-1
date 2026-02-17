shader_type canvas_item;

uniform sampler2D mask : source_color;
uniform int sprite_width_px = 64;  // the width of the sprite in pixels
uniform bool edges = true;

varying vec4 modulate_color;

void vertex() {
    // In vertex, COLOR is already: modulate * self_modulate * vertex_color
    modulate_color = COLOR;
}
void fragment() {
    // Get the UV of the fragment (0-1 across the sprite)
    vec2 uv = UV;

    // Quantize UVs to sprite resolution
    uv = floor(uv * float(sprite_width_px)) / float(sprite_width_px)+.5/float(sprite_width_px);

    // Sample the texture at the quantized UV
    vec4 tex = texture(mask, uv);
    // Discard if no alpha
    if (tex.a <= 0.0) {
        discard;
    }
    // Check neighbors to detect edges
    float alpha_left  = texture(mask, uv + vec2(-1.0/float(sprite_width_px), 0)).a;
    float alpha_right = texture(mask, uv + vec2( 1.0/float(sprite_width_px), 0)).a;
    float alpha_up    = texture(mask, uv + vec2(0, -1.0/float(sprite_width_px))).a;
    float alpha_down  = texture(mask, uv + vec2(0,  1.0/float(sprite_width_px))).a;

    // If any neighbor has zero alpha, this is an edge pixel
    if (alpha_left == 0.0 || alpha_right == 0.0 || alpha_up == 0.0 || alpha_down == 0.0) {
		if (!edges){
			discard;
		}else{
        	COLOR = vec4(0.0, 0.0, 0.0, 1.0); // black edge
		}
    } else {
        COLOR = texture(TEXTURE, uv)*modulate_color; // display original color, fully opaque
    }
}
