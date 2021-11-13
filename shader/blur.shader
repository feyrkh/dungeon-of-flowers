shader_type canvas_item;

uniform float blur = 0.0;

void fragment() {
	COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur).rgb;
}