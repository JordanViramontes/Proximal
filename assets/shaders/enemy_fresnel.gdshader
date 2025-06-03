shader_type spatial;

uniform vec3 base_color: source_color = vec3(0.5, 0.2, 0.9);
uniform sampler2D base_tex: filter_nearest;
uniform vec2 sample_rate = vec2(1.0, 1.0);
uniform vec3 fresnel_color: source_color = vec3(0.0, 0.7, 0.9);
uniform float fresnel_intensity = 4.5;
uniform float fresnel_amount = 4.0;
uniform float transparency: hint_range(0.0, 1.0) = 1.0;

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}

void fragment()
{
	//vec3 base_color = vec3(0.5, 0.2, 0.9);
	//vec3 fresnel_color = vec3(0.0, 0.7, 0.9);
	vec3 fresnel = fresnel_glow(fresnel_amount, fresnel_intensity, fresnel_color, NORMAL, VIEW);
	vec4 col = texture(base_tex, UV * sample_rate);
	ALBEDO = col.xyz + fresnel;
	//ALPHA = transparency;
	EMISSION = fresnel;
}

