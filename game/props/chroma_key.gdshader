shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(1.0, 0.0, 1.0);
uniform float tolerance : hint_range(0.0, 1.0, 0.01) = 0.24;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (distance(source.rgb, key_color) <= tolerance) {
		discard;
	}
	COLOR = source;
}
