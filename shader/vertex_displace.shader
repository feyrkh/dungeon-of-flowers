shader_type spatial;

uniform sampler2D mask;
uniform sampler2D albedo;
uniform float deform_power = 0.05;

void vertex() {
	float sample = texture(mask, UV).r;
	VERTEX.y += deform_power * sample;
	COLOR = texture(albedo, UV, 0.0);
	vec2 e = vec2(0.005, 0.0);
	vec3 normal = normalize(vec3(texture(mask, UV - e).r - texture(mask, UV - e).r, 2.0 * e.x, texture(mask, UV - e.yx).r - texture(mask, UV + e.yx).r));
	NORMAL = normal;
}

void fragment() {
	ALBEDO = COLOR.xyz;
}