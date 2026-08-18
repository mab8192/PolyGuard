shader_type canvas_item;

uniform float move_speed : hint_range(10.0, 500.0) = 75.0;
uniform float pulse_spacing : hint_range(32.0, 512.0) = 128.0;
uniform float pulse_length : hint_range(8.0, 128.0) = 24.0;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.12;
uniform float pulse_alpha : hint_range(0.0, 1.0) = 0.45;
uniform float fade_distance : hint_range(8.0, 128.0) = 32.0;
uniform float total_length : hint_range(1.0, 10000.0) = 500.0;
uniform float fade_alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	if (fade_alpha <= 0.001) {
		discard;
	}

	float dist = UV.x * total_length;

	// Edge fade at the beginning (spawner) and ending (exit) of the path
	float edge_fade = clamp(min(dist, total_length - dist) / fade_distance, 0.0, 1.0);

	// Pulse moves forward from spawner (dist = 0) towards exit (dist = total_length)
	float s = mod(mod(TIME * move_speed - dist, pulse_spacing) + pulse_spacing, pulse_spacing);

	// Leading bright head (s = 0) followed by a soft trailing tail (s = pulse_length)
	float pulse = 0.0;
	if (s < pulse_length) {
		float t = s / pulse_length;
		pulse = pow(1.0 - t, 1.8);
	}

	// Line cross-section profile (brighter glowing core in center)
	float cross = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = pow(cross, 1.5);

	float a = (base_alpha + pulse * pulse_alpha) * edge_fade * fade_alpha * (0.4 + 0.6 * core);

	COLOR = vec4(1.0, 1.0, 1.0, a);
}
