shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
varying vec2 screen_pixel_position;
uniform float stripe_scale:hint_range(0.01, 100.0, 0.01);
uniform float time_scale:hint_range(0.01, 100.0, 0.01);
void vertex() {
	screen_pixel_position = vec2(VERTEX.x / TEXTURE_PIXEL_SIZE.x,VERTEX.y / TEXTURE_PIXEL_SIZE.y);
}

void fragment() {
	
	float alf = step(-0.90f,sin((screen_pixel_position.y + TIME*time_scale)/stripe_scale));
	COLOR.rgb = alf * texture(screen_texture,UV).xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
