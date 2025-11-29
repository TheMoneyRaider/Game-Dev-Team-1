shader_type canvas_item;

uniform float u_time = 0.0;
uniform float u_radius = 0.35;
uniform float u_thickness = 0.12;
uniform vec4 color_inner : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 color_outer : source_color = vec4(0.9, 0.3, 1.0, 1.0);
uniform vec2 u_resolution = vec2(64.0, 64.0);

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0;
    float res = mix(
        mix(hash(n + 0.0), hash(n + 1.0), f.x),
        mix(hash(n + 57.0), hash(n + 58.0), f.x),
        f.y
    );
    return res;
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(x);
        x *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
	float pixel_size = 1.0 / 512.0; // smaller denominator = higher pixel detail
	vec2 uv = floor(UV / pixel_size) * pixel_size;
    vec2 pos = (uv - vec2(0.5))*10.0;
    float dist = length(pos);
    float n = fbm(pos * 5.0 + u_time * 0.6);

    // soft ring mask
    float ring = smoothstep(u_radius + u_thickness, u_radius + u_thickness * 0.4, dist)
               - smoothstep(u_radius - u_thickness * 0.4, u_radius - u_thickness, dist);

    // swirl shimmer
    float glow = 0.6 + 0.4 * sin((dist * 20.0 - u_time * 3.0) + n * 4.0);
    float intensity = ring * glow;

    // blend between colors
    vec4 col = mix(color_inner, color_outer, n) * intensity;
    COLOR = vec4(col.rgb, col.a);
}