shader_type canvas_item;

uniform sampler2D card_back;
uniform float progress = 0.0;
uniform vec4 flip_color : hint_color = vec4(0, 0, 0, 0);

void fragment() {
	if (progress <= 0.0) {
		COLOR = texture(TEXTURE, UV);
	} else if (progress >= 1.0) {
		COLOR = texture(card_back, UV);
	} else {
		float relevant_coord = UV.x;
		if (progress < 0.5) {
			// We are flipping from the front toward the back
			if (relevant_coord < progress || relevant_coord > 1.0-progress) {
				COLOR = flip_color;
			} else {
				vec2 offset = vec2(progress, 0);
				// fold the left edge and the right edge together
				if (UV.x < 0.5) {
					COLOR = texture(TEXTURE, UV-offset);
				} else {
					COLOR = texture(TEXTURE, UV+offset);
				}
			}
		} else {
			// we are flipping from the back toward the front
			float cur_progress = progress - 0.5; // shift progress to make the math easier
			if (relevant_coord < 0.5 - cur_progress || relevant_coord > 0.5 + cur_progress) {
				// the card has turned enough that this is outside the bounds of the card now
				COLOR = flip_color;
			}
		}
	}
}