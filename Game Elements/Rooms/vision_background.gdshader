shader_type canvas_item;

uniform float time_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.05;
uniform float band_width : hint_range(0.05, 0.5) = 0.22;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.06;

uniform vec4 color_a : source_color = vec4(0.8, 0.2, 0.2, 1.0); // red
uniform vec4 color_b : source_color = vec4(0.2, 0.7, 0.3, 1.0); // green
uniform vec4 color_c : source_color = vec4(0.4, 0.2, 0.6, 1.0); // purple

uniform float glow_strength : hint_range(0.0, 2.0) = 0.6;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    float t = TIME * time_speed;

    vec2 uv = UV;

    // Domain warping (organic edge breakup)
    float n = noise(uv * 6.0 + t * 0.2);
    uv.x += (n - 0.5) * wave_strength;

    // Vertical wave distortion
    uv.x += sin(uv.y * 10.0 + t) * wave_strength;

    // Band calculation
    float band = mod(uv.x, band_width * 3.0);

    float mask_a = smoothstep(0.0, edge_softness, band) *
                   (1.0 - smoothstep(band_width, band_width + edge_softness, band));

    float mask_b = smoothstep(band_width, band_width + edge_softness, band) *
                   (1.0 - smoothstep(band_width * 2.0, band_width * 2.0 + edge_softness, band));

    float mask_c = smoothstep(band_width * 2.0, band_width * 2.0 + edge_softness, band) *
                   (1.0 - smoothstep(band_width * 3.0, band_width * 3.0 + edge_softness, band));

    vec4 color =
        color_a * mask_a +
        color_b * mask_b +
        color_c * mask_c;

    // Edge glow
    float glow = pow(mask_a + mask_b + mask_c, 2.0) * glow_strength;

    COLOR = color + vec4(color.rgb * glow, 0.0);
}