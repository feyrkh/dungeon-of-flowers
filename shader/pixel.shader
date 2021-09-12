shader_type canvas_item;

uniform float size_x = 0.01;
uniform float size_y = 0.01;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv -= mod(uv, vec2(size_x, size_y));
	uv += vec2(size_x/2.0, size_y/2.0);
	
	COLOR.rgb = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
}