shader_type canvas_item;


uniform vec4 original_0: source_color;
uniform vec4 original_1: source_color;
uniform vec4 original_2: source_color;
uniform vec4 original_3: source_color;
uniform vec4 replace_0: source_color;
uniform vec4 replace_1: source_color;
uniform vec4 replace_2: source_color;
uniform vec4 replace_3: source_color;

const float precision = 0.1;


vec4 swap_color(vec4 color){
	vec4 original_colors[4] = vec4[4] (original_0, original_1, original_2, original_3);
	vec4 replace_colors[4] = vec4[4] (replace_0, replace_1, replace_2, replace_3);
	for (int i = 0; i < 5; i ++) {
		if (distance(color, original_colors[i]) <= precision){
			return replace_colors[i];
		}
	}
	return color;
}


void fragment() {
	vec4 new_color = swap_color(texture(TEXTURE, UV));
	COLOR = vec4(new_color.r, new_color.g, new_color.b, COLOR.a);
}