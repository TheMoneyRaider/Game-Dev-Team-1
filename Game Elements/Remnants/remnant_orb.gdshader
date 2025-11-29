shader_type canvas_item;

uniform float time_scale = 0.1;
uniform float distortion_amount = 3;
uniform float color_shift = 1.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    float t = TIME * time_scale;

    // STATIC NOISE
    float noise = rand(UV * (t + 50.0));

    // JITTERED UV FOR ELDritch "WARP"
    vec2 uv = UV;
    uv.x += sin(uv.y * 15.0 + t * 8.0) * 0.01 * distortion_amount;
    uv.y += cos(uv.x * 20.0 - t * 6.0) * 0.01 * distortion_amount;

    // COLOR CHANNEL SHIFT
    float shift = color_shift * 0.005;
    vec4 r = texture(TEXTURE, uv + vec2(shift, 0.0));
    vec4 g = texture(TEXTURE, uv);
    vec4 b = texture(TEXTURE, uv - vec2(shift, 0.0));
    vec4 final_color = vec4(r.r, g.g, b.b, g.a);


    COLOR = final_color;
}