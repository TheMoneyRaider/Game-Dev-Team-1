shader_type canvas_item;

uniform vec4 outline_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(1.0, 5.0) = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (tex_color.a == 0.0) {
	    float alpha = 0.0;
	    for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
	        for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
				if (length(vec2(x, y)) > outline_thickness) 
					continue;
	            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
	            vec4 neighbor = texture(TEXTURE,  UV + offset);
	            alpha = max(alpha, neighbor.a);
	        }
	    }
	    
	    if (alpha > 0.0) {
	        COLOR = outline_color;
	    }
	}else{
	COLOR = tex_color;
	}
}