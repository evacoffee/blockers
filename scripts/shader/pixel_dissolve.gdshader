shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	
	vec2 pixel_uv = SCREEN_UV;
	pixel_uv = floor(UV / TEXTURE_PIXEL_SIZE / pixel_size) * pixel_size;
	pixel_uv *= TEXTURE_PIXEL_SIZE;
	
	float noise_value = fract(
		sin(dot(pixel_uv, vec2(12.9898, 78.233))) * 43758.5453
	);
	
	if (noise_value < dissolve_amount) {
		discard;
	}
	
	COLOR = tex;
}