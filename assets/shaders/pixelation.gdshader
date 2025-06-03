shader_type canvas_item;

uniform sampler2D view: hint_screen_texture, filter_nearest, repeat_disable;
uniform float resolution_downsampling: hint_range(1.0, 8.0, 1.0);

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 UV_new = SCREEN_UV - mod(SCREEN_UV, SCREEN_PIXEL_SIZE * resolution_downsampling);
	vec3 tex = texture(view, UV_new).rgb;
	COLOR.rgb = tex.rgb;
}