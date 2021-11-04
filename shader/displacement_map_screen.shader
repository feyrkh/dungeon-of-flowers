shader_type canvas_item;

uniform sampler2D map;
uniform float maximum=0.05;

void fragment() {
	float time_e = TIME * 0.05;
	vec2 uv_t = vec2(UV.x+time_e, UV.y+time_e);
	if (uv_t.x > 1.0) {
		uv_t.x = fract(uv_t.x);
	} else if (uv_t.x < 0.0) {
		uv_t.x = fract(uv_t.x) + 1.0;
	}
	if (uv_t.y > 1.0) {
		uv_t.y = fract(uv_t.y);
	} else if (uv_t.y < 0.0) {
		uv_t.y = fract(uv_t.y) + 1.0;
	}
	vec4 displace  = texture(map, uv_t);
	float displace_k  = displace.g * maximum;
	vec2 uv_displaced = vec2(UV.x + displace_k,UV.y + displace_k);
	COLOR = texture(SCREEN_TEXTURE, uv_displaced);
}