shader_type canvas_item;
uniform bool sobel_enabled = false;
uniform bool inverse_output = false;
uniform float sobel_strength : hint_range(0.0,1.0) = 1.0;
uniform vec3 edge_color = vec3(1.0,1.0,1.0);

uniform vec2 impact_world_pos;
uniform vec2 camera_center;
uniform vec2 visible_world_size;
uniform float impact_time = -10000;
uniform float wave_speed = 48.0;
uniform float wave_width = 32.0;
uniform float collision_distances[720];

float lum(vec3 color){
    return dot(color, vec3(0.299, 0.587, 0.114)); // brightness
}
// Gaussian falloff
float g(float r, float sigma) {
    return exp(-(r * r) / (2.0 * sigma * sigma));
}


float fraction_sobeled(sampler2D text, vec2 uv){
	if (impact_time < 0.0) return 0.0;
	
	float elapsed = TIME - impact_time;
	if (elapsed <= 0.0) {
		return 0.0;
	}
	// Convert UV → world position
	vec2 world_pos = camera_center + (uv - vec2(0.5)) * visible_world_size;

	// Distance from impact in WORLD space
	vec2 delta = world_pos - impact_world_pos; // impact_uv is now world position
	float dist = length(delta);


	// Angle in degrees [0,360)
	float angle = degrees(atan(delta.y, delta.x));
	if (angle < 0.0) {
	    angle += 360.0;
	}

	// Convert to index (assuming 0.5° resolution -> 720 samples)
	int index = int(angle * 2.0);
	index = clamp(index, 0, 719);

	float max_dist = collision_distances[index];

	// Do not darken past collision
	if (dist > max_dist) {
	    return 0.0;
	}

	// Wave radius
	float wave_radius = elapsed * wave_speed;
	float edge_dist = dist - wave_radius;
	
	if (edge_dist > 0.0  || edge_dist < -wave_width) {
	    return 0.0;
	}

	// Smooth radial band
	// 1.0 at exact wave edge
	// 0.0 outside wave_width
	return smoothstep(0.0, 1.0, -edge_dist/wave_width);
}

vec4 sobel(vec4 original_color, bool inverse_out, float mix_strength, sampler2D text, vec2 uv){
	vec2 px = 1.0 / vec2(textureSize(text, 0));
	if (original_color.a <= 0.0){
			return original_color;
		}

	float top_l = lum(texture(text, uv + vec2(-px.x, -px.y)).rgb);
	float top  = lum(texture(text, uv + vec2( 0.0 , -px.y)).rgb);
	float top_r = lum(texture(text, uv + vec2( px.x, -px.y)).rgb);

	float left  = lum(texture(text, uv + vec2(-px.x,  0.0)).rgb);
	float center  = lum(texture(text, uv).rgb);
	float right  = lum(texture(text, uv + vec2( px.x,  0.0)).rgb);

	float bottom_l = lum(texture(text, uv + vec2(-px.x,  px.y)).rgb);
	float bottom  = lum(texture(text, uv + vec2( 0.0 ,  px.y)).rgb);
	float bottom_r = lum(texture(text, uv + vec2( px.x,  px.y)).rgb);

	float gx = (top_r + 2.0*right + bottom_r) - (top_l + 2.0*left + bottom_l);
	float gy = (bottom_l + 2.0*bottom + bottom_r) - (top_l + 2.0*top + top_r);
	float edge = sqrt(gx * gx + gy * gy);
	if(inverse_out){
		return vec4(edge_color*(1.0-edge),1.0);
	}else{
		return vec4(edge_color*edge,1.0);
	}
}



void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	COLOR = original_color;
	float fraction = fraction_sobeled(TEXTURE, UV);
	
	if (fraction > 0.0)
		COLOR = vec4(1.0,1.0,1.0,1.0);
		//COLOR = mix(original_color,sobel(original_color,inverse_output, 1.0,TEXTURE, UV),fraction);
	//
	//if(sobel_enabled)
		//COLOR = sobel(original_color,inverse_output, 1.0,TEXTURE, UV);



}