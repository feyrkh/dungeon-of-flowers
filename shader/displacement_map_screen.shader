shader_type canvas_item;

uniform sampler2D map;
uniform float maximum_x=0.05;
uniform float maximum_y=0.05;

void fragment() {
	//float time_e = TIME * 0.05;
	vec2 uv_t = vec2(UV.x, UV.y);
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
	float displace  = -0.5 + texture(map, uv_t).g;
	float displace_x  = displace * maximum_x;
	float displace_y  = displace * maximum_y;
	vec2 uv_moving_into_my_spot = vec2(uv_t.x-displace_x, uv_t.y-displace_y);
	float displace_for_original_spot = -0.5 + texture(map, uv_moving_into_my_spot).g;
	if ((displace < 0.0 && displace_for_original_spot > 0.0) || (displace > 0.0 && displace_for_original_spot < 0.0)) {
		COLOR = vec4(0f,0f,0f,0f);
	} else {
		vec2 uv_displaced = vec2(SCREEN_UV.x + displace_x, SCREEN_UV.y + displace_y);
		COLOR = texture(SCREEN_TEXTURE, uv_displaced);
	}
}