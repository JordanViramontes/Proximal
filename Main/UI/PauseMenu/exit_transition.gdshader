shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float progress : hint_range(0.0, 1.0); // 0 = fully masked, 1 = fully revealed

void fragment() {
    vec2 uv = UV;
    float mask = texture(mask_texture, uv).r; // read red (grayscale) channel
    float alpha = step(progress, mask); // if progress >= mask, show what's behind
    COLOR = vec4(0.0, 0.0, 0.0, alpha); // Black cover fades out by mask
}
