shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D mask_texture;
uniform float aberration_strength : hint_range(0.0,0.05) = 0.005;
uniform float mask_intensity : hint_range(0.0,1.0) = 1.0; // how visible the mask should be

void fragment() {
    vec2 uv = UV; // UV of the ShaderSprite, 0..1 across the sprite
    float mask = texture(mask_texture, uv).a;

    // Sample screen behind this Sprite at the same position
    vec2 screen_uv = SCREEN_UV; // SCREEN_UV automatically matches the fragment's screen location
    vec4 original = texture(SCREEN_TEXTURE, screen_uv);

    // Small RGB offsets for chromatic aberration
    vec2 offset = vec2(aberration_strength, 0.0);
    vec4 aberrated;
    aberrated.r = texture(SCREEN_TEXTURE, screen_uv + offset).r;
    aberrated.g = original.g;
    aberrated.b = texture(SCREEN_TEXTURE, screen_uv - offset).b;
    aberrated.a = original.a;
	if(mask > 0.0)
		mask = 1.0;
    // Mix the original screen and the aberrated color based on the mask
    vec4 color_with_aberration = mix(original, aberrated, mask);

    // Add the mask texture itself on top (e.g., multiply by mask_intensity for control)
    vec4 mask_color = texture(mask_texture, uv) * mask_intensity;

    // Final color combines chromatic aberration and visible mask
    COLOR = color_with_aberration + mask_color*mask;
}