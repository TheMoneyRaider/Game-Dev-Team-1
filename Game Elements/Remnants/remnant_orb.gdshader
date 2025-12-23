shader_type canvas_item;

uniform float time_scale = 0.1;
uniform float distortion_amount = 3;
uniform float color_shift = 1.0;
uniform float color_shift_time_scale = .1;

uniform bool upper_left = true;
uniform bool split = false;

bool diagonal_mask(vec2 uv) {
    return upper_left
        ? (uv.x + uv.y <= 1.0)
        : (uv.x + uv.y > 1.0);
}
// 0 = off, 1 = on
uniform int shift_wave_enabled = 0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    if (split && !diagonal_mask(UV)) {
        discard;
    }
    float t = TIME * time_scale;
    float t_cs = TIME * color_shift_time_scale;

    // STATIC NOISE
    float noise = rand(UV * (t + 50.0));

    // JITTERED UV FOR WARP
    vec2 uv = UV;
    uv.x += sin(uv.y * 15.0 + t * 8.0) * 0.01 * distortion_amount;
    uv.y += cos(uv.x * 20.0 - t * 6.0) * 0.01 * distortion_amount;

    float shift_scale = 1.0;

    if (shift_wave_enabled == 1) {
        // sine wave between 0.0 and 1
        shift_scale = 0.0 + (sin(t_cs * 2.0) * 0.5 + 0.5) * 1.0;
    }

    float shift = color_shift * shift_scale * 0.005;

    vec4 r = texture(TEXTURE, uv + vec2(shift, 0.0));
    vec4 g = texture(TEXTURE, uv);
    vec4 b = texture(TEXTURE, uv - vec2(shift, 0.0));
    vec4 final_color = vec4(r.r, g.g, b.b, g.a);

    COLOR = final_color;
}