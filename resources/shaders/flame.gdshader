shader_type spatial;
// Procedural flame with rising embers. Driven only by uniforms (never TIME), so motion is
// deterministic, freezes while paused and restarts with the run clock.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float clock = 0.0;
uniform float intensity = 1.0;
uniform float seed = 0.0;
uniform float flame_height = 0.62;
uniform float brightness = 1.6;
uniform vec3 core_color : source_color = vec3(1.0, 0.86, 0.55);
uniform vec3 edge_color : source_color = vec3(0.95, 0.36, 0.08);

void vertex() {
	// Y-axis billboard that keeps the node's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int k = 0; k < 3; k++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	float x = UV.x - 0.5;
	float y = 1.0 - UV.y;
	float height = flame_height * (0.55 + 0.45 * intensity);
	float fy = y / height;
	float n = fbm(vec2(x * 4.0 + seed, y * 3.0 - clock * 2.6 + seed * 1.7));
	float sway = (sin(clock * 2.1 + seed * 3.0) * 0.06 + (n - 0.5) * 0.24) * fy;
	float width = 0.34 * pow(max(1.0 - fy, 0.0), 0.55) * smoothstep(0.0, 0.12, fy + 0.02);
	float d = abs(x - sway) / max(width, 0.001);
	float body = (1.0 - smoothstep(0.55, 1.0, d)) * step(fy, 1.0);
	body *= smoothstep(0.15, 0.55, n + (1.0 - fy) * 0.55);
	float core = (1.0 - smoothstep(0.0, 0.6, d)) * (1.0 - smoothstep(0.2, 0.75, fy));
	vec3 color = mix(edge_color, core_color, clamp(core * 1.2, 0.0, 1.0)) * body;
	float sparks = 0.0;
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float r = hash(vec2(fi, seed));
		float t = fract(clock * (0.35 + 0.25 * r) + r * 7.0);
		vec2 p = vec2((r - 0.5) * 0.3 + sin(clock * 1.3 + fi * 2.0) * 0.05 * t, height * 0.5 + t * (1.0 - height * 0.5));
		float s = 1.0 - smoothstep(0.0, 0.02, length((vec2(x, y) - p) * vec2(1.0, 0.6)));
		sparks += s * (1.0 - t);
	}
	ALBEDO = (color + edge_color * sparks * 1.5) * brightness * (0.75 + 0.25 * intensity);
}
