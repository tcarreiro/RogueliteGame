extends LuaComponent
## Partículas configuradas por props. Cada mudança relê tudo de `props`.

@onready var _particles: CPUParticles2D = %Particles

static var _shape: GradientTexture2D
var _additive: CanvasItemMaterial


func get_schema() -> Dictionary:
	return {
		"name": "ParticleEmitter",
		"props": PropertyDefinition.pick([
			PropertyDefinition.EMITTING, PropertyDefinition.AMOUNT, PropertyDefinition.LIFETIME, PropertyDefinition.ONE_SHOT,
			PropertyDefinition.EXPLOSIVENESS, PropertyDefinition.RANDOMNESS, PropertyDefinition.PREWARM,
			PropertyDefinition.SHAPE, PropertyDefinition.EMIT_ANGLE, PropertyDefinition.SPREAD, PropertyDefinition.SPEED,
			PropertyDefinition.GRAVITY, PropertyDefinition.PARTICLE_SCALE, PropertyDefinition.COLOR, PropertyDefinition.COLOR_END,
			PropertyDefinition.BLEND, PropertyDefinition.TEXTURE, PropertyDefinition.CLIP,
			PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
		]),
		"methods": ["restart"],
	}


func _component_ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_configure()


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.WIDTH:
			if int(value) >= 0:
				custom_minimum_size.x = value
		PropertyDefinition.HEIGHT:
			if int(value) >= 0:
				custom_minimum_size.y = value
		_:
			if _schema.get("props", {}).has(key):
				if _is_ready:
					_configure()
			else:
				super._apply_prop(key, value)


func _configure() -> void:
	var speed := _pair(props.get("speed"), Vector2(20.0, 60.0))
	var grow := _pair(props.get("particle_scale"), Vector2.ONE)
	var start := _color(props.get("color"), Color.WHITE)
	var finish := _color(props.get("color_end"), Color(start.r, start.g, start.b, 0.0))
	var ramp := Gradient.new()
	ramp.set_color(0, start)
	ramp.set_color(1, finish)

	_particles.amount = maxi(int(props.get("amount", 32)), 1)
	_particles.lifetime = maxf(float(props.get("lifetime", 1.5)), 0.01)
	_particles.one_shot = bool(props.get("one_shot", false))
	_particles.explosiveness = clampf(float(props.get("explosiveness", 0.0)), 0.0, 1.0)
	_particles.randomness = clampf(float(props.get("randomness", 0.0)), 0.0, 1.0)
	_particles.preprocess = maxf(float(props.get("prewarm", 0.0)), 0.0)
	_particles.emission_shape = PropertyDefinition.EMIT_SHAPES.get(
		StringName(str(props.get("shape", "box"))), CPUParticles2D.EMISSION_SHAPE_RECTANGLE)
	_particles.direction = Vector2.from_angle(deg_to_rad(float(props.get("emit_angle", -90.0))))
	_particles.spread = float(props.get("spread", 25.0))
	_particles.initial_velocity_min = speed.x
	_particles.initial_velocity_max = speed.y
	_particles.gravity = _vector(props.get("gravity"))
	_particles.scale_amount_min = grow.x
	_particles.scale_amount_max = grow.y
	_particles.color = Color.WHITE
	_particles.color_ramp = ramp

	var path := str(props.get("texture", ""))
	var custom := load(path) as Texture2D if path != "" else null
	_particles.texture = custom if custom != null else _default_shape()

	if _additive == null:
		_additive = CanvasItemMaterial.new()
	match str(props.get(PropertyDefinition.BLEND, PropertyDefinition.MIX)):
		PropertyDefinition.ADD:
			_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		PropertyDefinition.MULTIPLY:
			_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		PropertyDefinition.MIX:
			_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		PropertyDefinition.PREMULTIPLIED_ALPHA:
			_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		PropertyDefinition.SUBTRACT:
			_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	_particles.material = _additive

	clip_contents = bool(props.get("clip", false))
	_layout()
	_particles.emitting = bool(props.get("emitting", true))


func _layout() -> void:
	_particles.position = size * 0.5
	_particles.emission_rect_extents = size * 0.5
	_particles.emission_sphere_radius = minf(size.x, size.y) * 0.5


## Exposto ao Lua: reinicia (útil com one_shot).
func restart() -> void:
	_particles.restart()


#region Conversões
func _pair(raw: Variant, fallback: Vector2) -> Vector2:
	if raw is int or raw is float:
		return Vector2.ONE * float(raw)
	if raw is Array and raw.size() == 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return fallback


func _vector(raw: Variant) -> Vector2:
	if raw is int or raw is float:
		return Vector2(0.0, float(raw))
	if raw is Array and raw.size() == 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO


func _color(raw: Variant, fallback: Color) -> Color:
	return LuaHelper.parse_color(raw) if raw != null else fallback


## Ponto macio (círculo que some nas bordas) para quando não há textura.
func _default_shape() -> Texture2D:
	if _shape == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		_shape = GradientTexture2D.new()
		_shape.gradient = gradient
		_shape.fill = GradientTexture2D.FILL_RADIAL
		_shape.fill_from = Vector2(0.5, 0.5)
		_shape.fill_to = Vector2(1.0, 0.5)
		_shape.width = 16
		_shape.height = 16
	return _shape
#endregion
