shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D mask_texture;
uniform float aberration_strength : hint_range(0.0,0.05) = 0.005;
uniform float mask_intensity : hint_range(0.0,1.0) = 1.0; // how visible the mask should be

void fragment() {
	COLOR = texture(TEXTURE, UV);
}