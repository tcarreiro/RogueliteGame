class_name LuaShaderLibrary extends RefCounted
## Efeitos de tela prontos. Cada preset lê o que foi desenhado atrás do componente.
## "defaults" lista os parâmetros válidos e o tipo de cada um (Color é convertido).

const HEADER := "shader_type canvas_item;\nuniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;\n"

const PRESETS := {
	&"tint": {
		"defaults": {"color": Color(1, 0, 0, 1), "intensity": 0.3},
		"code": """
uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.3;
void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	COLOR = vec4(mix(src.rgb, color.rgb, intensity), src.a);
}""",
	},
	&"grayscale": {
		"defaults": {"intensity": 1.0},
		"code": """
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float g = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(src.rgb, vec3(g), intensity), src.a);
}""",
	},
	&"vignette": {
		"defaults": {"color": Color(0, 0, 0, 1), "intensity": 0.5, "softness": 0.5},
		"code": """
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.01, 1.0) = 0.5;
void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float d = distance(UV, vec2(0.5)) * 1.41421;
	float v = smoothstep(1.0 - softness, 1.0, d) * intensity;
	COLOR = vec4(mix(src.rgb, color.rgb, v), src.a);
}""",
	},
	&"blur": {
		"defaults": {"radius": 2.0},
		"code": """
uniform float radius : hint_range(0.0, 8.0) = 2.0;
void fragment() {
	COLOR = vec4(textureLod(screen_texture, SCREEN_UV, radius).rgb, 1.0);
}""",
	},
	&"pixelate": {
		"defaults": {"pixel_size": 6.0},
		"code": """
uniform float pixel_size : hint_range(1.0, 64.0) = 6.0;
void fragment() {
	vec2 cell = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 uv = (floor(SCREEN_UV / cell) + 0.5) * cell;
	COLOR = vec4(texture(screen_texture, uv).rgb, 1.0);
}""",
	},
	&"scanlines": {
		"defaults": {"intensity": 0.25, "density": 300.0, "speed": 0.0},
		"code": """
uniform float intensity : hint_range(0.0, 1.0) = 0.25;
uniform float density : hint_range(1.0, 1080.0) = 300.0;
uniform float speed = 0.0;
void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float line = 0.5 + 0.5 * sin((UV.y * density + TIME * speed) * 3.14159);
	COLOR = vec4(src.rgb * (1.0 - intensity * line), src.a);
}""",
	},
	&"chromatic": {
		"defaults": {"amount": 0.004},
		"code": """
uniform float amount : hint_range(0.0, 0.05) = 0.004;
void fragment() {
	vec2 off = (UV - vec2(0.5)) * amount;
	float r = texture(screen_texture, SCREEN_UV + off).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - off).b;
	COLOR = vec4(r, g, b, 1.0);
}""",
	},
	&"wave": {
		"defaults": {"amplitude": 0.008, "frequency": 20.0, "speed": 2.0},
		"code": """
uniform float amplitude : hint_range(0.0, 0.05) = 0.008;
uniform float frequency = 20.0;
uniform float speed = 2.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(UV.y * frequency + TIME * speed) * amplitude;
	COLOR = vec4(texture(screen_texture, uv).rgb, 1.0);
}""",
	},
}

static var _cache: Dictionary = {}


static func names() -> Array:
	return PRESETS.keys()


static func has_preset(preset: StringName) -> bool:
	return PRESETS.has(preset)


static func defaults(preset: StringName) -> Dictionary:
	return PRESETS.get(preset, {}).get("defaults", {})


static func shader(preset: StringName) -> Shader:
	if not _cache.has(preset):
		var s := Shader.new()
		s.code = HEADER + str(PRESETS[preset]["code"])
		_cache[preset] = s
	return _cache[preset]
