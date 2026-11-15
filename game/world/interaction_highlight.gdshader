shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.35, 1.0);
// UVs refer to the full atlas. Samples outside this frame must be transparent,
// including when the neighboring frame touches the edge of its own cell.
uniform vec4 source_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D source_texture : filter_nearest, repeat_disable;
varying float inherited_alpha;

void vertex() {
	inherited_alpha = COLOR.a;
}

float frame_alpha(vec2 uv) {
	if (uv.x < source_region.x || uv.y < source_region.y || uv.x >= source_region.z || uv.y >= source_region.w) {
		return 0.0;
	}
	return texture(source_texture, uv).a;
}

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	float alpha = frame_alpha(UV);
	float near_alpha = 0.0;
	float far_alpha = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 step_uv = vec2(float(x), float(y)) * pixel;
			near_alpha = max(near_alpha, frame_alpha(UV + step_uv));
			far_alpha = max(far_alpha, frame_alpha(UV + step_uv * 2.0));
		}
	}
	float rim = (1.0 - alpha) * near_alpha * 0.75;
	float halo = (1.0 - alpha) * (1.0 - near_alpha) * far_alpha * 0.22;
	COLOR = vec4(glow_color.rgb, (rim + halo + alpha * 0.10) * glow_color.a * inherited_alpha);
}
