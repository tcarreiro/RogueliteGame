extends LuaComponent
## Camada de efeito de tela. O material fica no próprio ColorRect da raiz.
## Em um Stack ocupa a área toda e não captura o mouse.

@onready var _copy: BackBufferCopy = %Copy
@onready var _rect: ColorRect = %Rect

var _material: ShaderMaterial
var _preset: StringName = &""
var _tween: Tween

func get_schema() -> Dictionary:
	return {
		"name": "ShaderEffect",
		"props": PropertyDefinition.pick([
			PropertyDefinition.EFFECT, PropertyDefinition.PARAMS, PropertyDefinition.ACTIVE,
			PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
		]),
		"methods": ["set_param", "tween_param"],
	}


func _component_ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_copy.copy_mode = BackBufferCopy.COPY_MODE_RECT
	resized.connect(func(): _copy.rect = Rect2(Vector2.ZERO, size))
	_rebuild()


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.EFFECT, PropertyDefinition.PARAMS, PropertyDefinition.ACTIVE:
			if _is_ready:
				_rebuild()
		PropertyDefinition.WIDTH:
			if int(value) >= 0:
				custom_minimum_size.x = value
		PropertyDefinition.HEIGHT:
			if int(value) >= 0:
				custom_minimum_size.y = value
		_:
			super._apply_prop(key, value)


## Lê de `props`: a ordem em que as props chegam não importa.
func _rebuild() -> void:
	var preset := StringName(str(props.get(PropertyDefinition.EFFECT, "tint")))
	if not LuaShaderLibrary.has_preset(preset):
		push_warning("[ShaderEffect] efeito desconhecido: '%s'" % preset)
		material = null
		return
	if preset != _preset or _material == null:
		_material = ShaderMaterial.new()
		_material.shader = LuaShaderLibrary.shader(preset)
		_preset = preset
	var active := bool(props.get("active", true))
	_rect.material = _material if active else null
	_copy.visible = active
	var given: Variant = props.get(PropertyDefinition.PARAMS)
	if given is Dictionary:
		for param in given:
			set_param(str(param), given[param])


#region Métodos expostos ao Lua
## UI.callMethod('fx', 'set_param', { 'intensity', 0.8 })
func set_param(param: String, value: Variant) -> void:
	var known := LuaShaderLibrary.defaults(_preset)
	if _material == null or not known.has(param):
		push_warning("[ShaderEffect] '%s' não é parâmetro de '%s' (%s)" % [param, _preset, ", ".join(known.keys())])
		return
	_material.set_shader_parameter(param, _convert(known[param], value))


## Anima um parâmetro numérico: UI.callMethod('fx', 'tween_param', { 'intensity', 0.0, 0.3 })
func tween_param(param: String, to: float, seconds: float) -> void:
	var known := LuaShaderLibrary.defaults(_preset)
	if _material == null or not known.has(param):
		return
	var current: Variant = _material.get_shader_parameter(param)
	if current == null:
		current = known[param]
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(v: float): _material.set_shader_parameter(param, v), float(current), to, seconds)
#endregion


func _convert(default: Variant, value: Variant) -> Variant:
	if default is Color:
		return LuaHelper.parse_color(value)
	if default is float or default is int:
		return float(value)
	return value
