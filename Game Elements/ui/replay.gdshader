shader_type canvas_item;

uniform float time : hint_range(0,1000) = 0.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment(){
    vec2 uv_mod = UV;

    // Horizontal tear
    float tear = step(0.995, rand(vec2(uv_mod.y*100.0 + time, 0.0)));
    uv_mod.x += tear * 0.02 * sin(uv_mod.y*50.0 + time*10.0);

    // RGB shift
    vec4 color = texture(TEXTURE, uv_mod);
    color.r = texture(TEXTURE, uv_mod + vec2(0.005,0)).r;
    color.g = texture(TEXTURE, uv_mod + vec2(-0.005,0)).g;
    color.b = color.b;

    // Noise
    color.rgb += vec3(rand(uv_mod*1000.0 + time)*0.02);

    COLOR = color;
}