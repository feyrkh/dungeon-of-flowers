shader_type canvas_item;

uniform sampler2D mask;

uniform vec4 start_color : hint_color = vec4(0, 0, 0, 0);
uniform float start_color_width = 0.1;
uniform vec4 fade_color_1 : hint_color = vec4(0, 0, 0, 1);
uniform float fade_color_1_width = 0.2;
uniform vec4 fade_color_2 : hint_color = vec4(1, 1, 0.35, 1);
uniform float fade_color_2_width = 0.3;
uniform vec4 fade_color_3 : hint_color = vec4(1, 1, 1, 1);
uniform float fade_color_3_width = 0.4;

uniform float duration = 0.25;
uniform float progress = 1.0;

void fragment() {
	float _mask_progress = progress * (1.0+fade_color_3_width);
	vec4 in_color = texture(TEXTURE, UV);
	float sample = texture(mask, UV).r;
	if (_mask_progress < sample+start_color_width) {                                                                                       
		COLOR = start_color;
		COLOR.a *= in_color.a;
	} else {
		if (_mask_progress < sample+fade_color_1_width) {
			COLOR = fade_color_1;
			COLOR.a *= in_color.a;
		} else {
			if (_mask_progress < sample+fade_color_2_width) {
				COLOR = fade_color_2;
				COLOR.a *= in_color.a;
			}  else {
				if (_mask_progress < sample+fade_color_3_width) {
					COLOR = fade_color_3;
					COLOR.a *= in_color.a;
				}  else {
					COLOR = in_color;
				}
			}
		}
	}
		//if (_mask_progress <= sample+fade_color_1_width) {    
		//	COLOR = fade_color_1;
			//COLOR.a *= in_color.a;
		//}
	/*
	else if (_mask_progress <= sample+fade_color_2_width) {    
		COLOR = fade_color_2;
		//COLOR.a *= in_color.a;
		return;
	}
	else if (_mask_progress <= sample+fade_color_3_width) {    
		COLOR = fade_color_3;
		//COLOR.a *= in_color.a;
		return;
	}*/
}