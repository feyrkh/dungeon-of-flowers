shader_type canvas_item;

uniform sampler2D map;
uniform float maximum=0.05;
uniform float motion=0.05;

void fragment() {
	float time_e = TIME * motion;
	
	// scroll displacement map up/left over time

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

	// end scroll over time
	
	// expand and contract to center
//	float expansion = abs(sin(TIME/5.0));
//	vec2 uv_t = vec2(UV.x - (0.5-UV.x)*expansion, UV.y - (0.5-UV.y)*expansion);
	
	vec4 displace  = texture(map, uv_t);
	float displace_k  = (displace.g - 0.5) * maximum * 2.0; // centralized: displaces up+left/down+right with medium gray meaning no change
	//float displace_k  = displace.g * maximum; // normal: displaces up and left with black meaning no change
	vec2 uv_displaced = vec2(UV.x + displace_k,UV.y + displace_k);
	COLOR = texture(TEXTURE, uv_displaced);
}