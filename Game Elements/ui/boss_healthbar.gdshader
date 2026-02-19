shader_type canvas_item;

uniform int effect_index = -1;
uniform float progress : hint_range(0.0,1.0)= 1.0;



uniform float u_speed = .125;
uniform vec4 u_color_low : source_color = vec4(0, 0, 0, 1);
uniform vec4 u_color_mid_red : source_color = vec4(0, 0.396, 0.5607, 1.0);
uniform vec4 u_color_high : source_color = vec4(0, 0.9019, 0.73, 1.0);
uniform vec2 image_size = vec2(0, 0);
uniform float scale = 96.0;
uniform bool enabled = true;



#define iTime (TIME * u_speed)
#define iResolution 1.0/SCREEN_PIXEL_SIZE

const mat2 mtx = mat2( vec2(0.80, -0.60), vec2(0.60, 0.80) );

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);

    return res * res;
}

float fbm( vec2 p ){
    float f = 0.0;

    f += 0.500000 * noise( p + iTime ); p = mtx * p * 2.02;
    f += 0.031250 * noise( p ); p = mtx * p * 2.01;
    f += 0.250000 * noise( p ); p = mtx * p * 2.03;
    f += 0.125000 * noise( p ); p = mtx * p * 2.01;
    f += 0.062500 * noise( p ); p = mtx * p * 2.04;
    f += 0.015625 * noise( p + sin(iTime) );

    return f / 0.96875;
}

float pattern( in vec2 p ){
	return fbm( p + fbm( p + fbm( p ) ) );
}

vec4 colormap(float x) {

    if (x < 0.24) {
        return mix(u_color_low, u_color_mid_red, x / 0.24);
    }
    else {
        return mix(u_color_mid_red, u_color_high, (x - 0.24) / 0.76);
    }
}



void vertex() {
	// Called for every vertex the material is visible on.
}


bool health_edge(sampler2D text, vec2 uv){
	if (effect_index == -1) {
		if(uv.x > progress)
			return true;
	} else if (effect_index == 0) {
		if(uv.x > progress)
			return true;
	} else if (effect_index == 1) {
		if(uv.x > progress)
			return true;
	} else {
	}
	return false;
}


vec4 health_color(sampler2D text, vec2 uv, vec2 pixel_size, vec4 fragment_coord){
	if (effect_index == -1) {
		return texture(text,uv);
	} else if (effect_index == 0) {

	    //vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	    //vec2 uv = FRAGCOORD.xy / screen_size.x;
	   	//float shade = pattern(floor(world_pos)/scale);

		vec2 uv2 = floor(uv*image_size)/image_size * image_size;
		uv2 /= scale;
		return colormap(pattern(uv2));
	} else if (effect_index == 1) {
		return texture(text,uv);
	}
	return vec4(0.0,0.0,0.0,0.0);
}


void fragment() {
	if(health_edge(TEXTURE, UV)){
		discard;
	}
	if (texture(TEXTURE,UV).rgb==vec3(1.0,0.0,0.0)){
		COLOR = health_color(TEXTURE, UV,SCREEN_PIXEL_SIZE,FRAGCOORD);
	}else{
		COLOR = texture(TEXTURE,UV);
	}
}
