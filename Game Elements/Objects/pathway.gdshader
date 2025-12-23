shader_type canvas_item;

uniform bool upper_left = true;
uniform bool split = false;
uniform float x_y_ratio = 1.0;
uniform vec2 frame_offset = vec2(0.0,0.0);

bool diagonal_mask(vec2 uv) {
    vec2 uv_corr = uv;
    uv_corr.x = uv.x*x_y_ratio-frame_offset.x;
    uv_corr.y = uv.y-frame_offset.y;

    return upper_left
        ? (uv_corr.x + uv_corr.y <= 1.0)
        : (uv_corr.x + uv_corr.y > 1.0);
}

void fragment() {
    if (split && !diagonal_mask(UV)) {
        discard;
    }
}