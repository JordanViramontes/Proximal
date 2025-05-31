shader_type canvas_item;

uniform sampler2D overlay;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 color: source_color;

void fragment() {
	vec4 overlay_sample = texture(overlay, SCREEN_UV);
	vec4 screen_sample = texture(screen_texture, SCREEN_UV);
	
	COLOR.rgb = screen_sample.rgb * overlay_sample.rgb * color.rgb;
	COLOR.a = color.a;
}
