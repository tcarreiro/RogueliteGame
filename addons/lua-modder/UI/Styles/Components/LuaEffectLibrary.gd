class_name LuaEffectLibrary extends RefCounted
## Efeitos de cor pontuais. Vários efeitos viram UM shader, aplicado em ordem.
## No corpo, P_<param> vira o uniform daquele efeito.

const PRESETS := {
	&"grayscale": {
		"defaults": {"amount": 1.0},
		"body": "float g = dot(c.rgb, vec3(0.299, 0.587, 0.114)); return vec4(mix(c.rgb, vec3(g), P_amount), c.a);",
	},
	&"saturation": {
		"defaults": {"amount": 1.0},
		"body": "float g = dot(c.rgb, vec3(0.299, 0.587, 0.114)); return vec4(mix(vec3(g), c.rgb, P_amount), c.a);",
	},
	&"brightness": {"defaults": {"amount": 0.0}, "body": "return vec4(c.rgb + vec3(P_amount), c.a);"},
	&"contrast": {"defaults": {"amount": 1.0}, "body": "return vec4((c.rgb - 0.5) * P_amount + 0.5, c.a);"},
	&"invert": {"defaults": {"amount": 1.0}, "body": "return vec4(mix(c.rgb, 1.0 - c.rgb, P_amount), c.a);"},
	&"sepia": {
		"defaults": {"amount": 1.0},
		"body": "vec3 s = vec3(dot(c.rgb, vec3(0.393, 0.769, 0.189)), dot(c.rgb, vec3(0.349, 0.686, 0.168)), dot(c.rgb, vec3(0.272, 0.534, 0.131))); return vec4(mix(c.rgb, s, P_amount), c.a);",
	},
	&"tint": {"defaults": {"color": Color(1, 0, 0, 1), "amount": 0.3}, "body": "return vec4(mix(c.rgb, P_color.rgb, P_amount), c.a);"},
	&"flash": {"defaults": {"color": Color(1, 1, 1, 1), "amount": 0.0}, "body": "return vec4(mix(c.rgb, P_color.rgb, P_amount), c.a);"},
	&"fade": {"defaults": {"amount": 1.0}, "body": "return vec4(c.rgb, c.a * P_amount);"},
}

static var _shaders: Dictionary = {}   # assinatura (sequência de nomes) -> Shader


static func names() -> Array:
	return PRESETS.keys()


static func has_preset(preset: StringName) -> bool:
	return PRESETS.has(preset)


## effects do Lua -> [{ name, params }]. Aceita 'nome', { effect = 'nome', param = valor } ou uma lista deles.
static func parse_specs(raw: Variant) -> Array:
	var list: Array = []
	if raw is Array:
		list = raw
	elif raw is Dictionary:
		list = [raw]
	var out: Array = []
	for item in list:
		var spec := {"name": &"", "params": {}}
		if item is Dictionary:
			spec.name = StringName(str(item.get("effect", "")))
			for k in item:
				if str(k) != "effect":
					spec.params[str(k)] = item[k]
		else:
			spec.name = StringName(str(item))
		if has_preset(spec.name):
			out.append(spec)
		else:
			push_warning("[Effects] efeito desconhecido: '%s' (existem: %s)" % [spec.name, str(names())])
	return out


static func uniform_name(index: int, param: String) -> String:
	return "p%d_%s" % [index, param]


static func convert(default: Variant, value: Variant) -> Variant:
	return LuaHelper.parse_color(value) if default is Color else float(value)


## O código do shader só depende da sequência de efeitos; os valores são uniforms.
static func build_material(specs: Array) -> ShaderMaterial:
	var signature := ""
	var uniforms := ""
	var functions := ""
	var calls := ""
	var values := {}
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var preset: Dictionary = PRESETS[spec.name]
		signature += String(spec.name) + ";"
		var body: String = preset.body
		for param: String in preset.defaults:
			var uname := uniform_name(i, param)
			var default: Variant = preset.defaults[param]
			uniforms += ("uniform vec4 %s : source_color;\n" if default is Color else "uniform float %s;\n") % uname
			body = body.replace("P_" + param, uname)
			values[uname] = convert(default, spec.params.get(param, default))
		functions += "vec4 fx%d(vec4 c) {\n  %s\n}\n" % [i, body]
		calls += "  c = fx%d(c);\n" % i
	if not _shaders.has(signature):
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;\n%s%svoid fragment() {\n  vec4 c = COLOR;\n%s  COLOR = c;\n}\n" % [uniforms, functions, calls]
		_shaders[signature] = shader
	var material := ShaderMaterial.new()
	material.shader = _shaders[signature]
	for uname in values:
		material.set_shader_parameter(uname, values[uname])
	return material
	
