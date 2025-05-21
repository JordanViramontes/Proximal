shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool use_billboard;
void vertex() {
	if (use_billboard){
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

uniform bool effect_enabled;
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_disable;

vec2 scale(vec2 uv, float x, float y)
{
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

void fragment() {
	if (effect_enabled) {
		ALBEDO = vec3(1.0, 1.0, 1.0); 
	} else {
		ALBEDO = texture(albedo_texture, scale(UV, 0.2, 0.2)).rgb;
	}
	ALPHA = texture(albedo_texture, scale(UV, 0.2, 0.2)).a;
}