class_name LCSSStyleTarget extends RefCounted
## Liga propriedades (como aparecem no .lua e no .lcss, com o "contexto")
## a um alvo do componente e à propriedade (PropertyDefinition.*) que o LCSSAppliers aplica, 
## e anima as mudanças de valor.
##
##   register_property(PropertyDefinition.FONT_COLOR, _label)                      # contexto = "font_color"
##   register_property(PropertyDefinition.FONT_COLOR, _label, &"label_font_color") # contexto explícito
##   register_group(PropertyDefinition.FONT, _label, "label_")                     # label_font_color, label_font_size...
##
## Famílias: o contexto é o do atalho; as partes herdam o sufixo
## (input_padding -> input_padding_left, input_padding_top, ...).

enum Kind { NONE, COLOR, NUMBER, VECTOR, FAMILY }


#region Internal classes
class Binding extends RefCounted:
	var property: StringName
	var target: Node


class FamilyBinding extends RefCounted:
	var family: StringName
	var target: Node
	var shorthand: StringName
	var members: Array[StringName] = [] 

	func context_of(canonical: StringName) -> StringName:
		if canonical == family:
			return shorthand
		var i := PropertyDefinition.members_of(family).find(canonical)
		return members[i] if i >= 0 else &""


class Transition extends RefCounted:
	
	var duration := 0.0
	var trans: int = Tween.TRANS_QUAD
	var ease_type: int = Tween.EASE_OUT
	var loop: StringName = PropertyDefinition.ONE_SHOT
	var repetitions: int = -1
	var properties: Array[String] = []   # vazio = all

	func covers(key: StringName) -> bool:
		return properties.is_empty() or properties.has(PropertyDefinition.ALL) or properties.has(String(key))
#endregion

var _property_targets: Dictionary[StringName, Node] = {}
var _family_targets: Dictionary[StringName, Node] = {}
var _defaults: Dictionary = {}   # contexto -> valor padrão (camada mais baixa, abaixo do .lcss)
var _simple: Dictionary = {}     # context -> Binding
var _families: Dictionary = {}   # context -> FamilyBinding
var _contexts: Dictionary = {}   # todo contexto conhecido -> Binding | FamilyBinding
var _meta: Dictionary = {}            # chaves que só configuram (transition_*), sem alvo

var _target_values: Dictionary = {}   # chave -> último valor RESOLVIDO
var _shown: Dictionary = {}           # chave -> valor aplicado agora (muda durante o tween)
var _tweens: Dictionary = {}
var _transitions_enabled := false

var _last_style: LCSSStyle
var _last_overrides: Dictionary[StringName, Variant] = {}
var _anim_values: Dictionary = {}   # chave -> valor atual da animação (vence o estilo)
var _anim_tween: Tween
var _anim_signature := ""

#region Register
func register_property(property: StringName, target: Node, context: StringName = &"") -> void:
	if PropertyDefinition.FAMILIES.has(property):
		register_family(property, target, context)
		return
	var family := PropertyDefinition.family_of(property)
	if family != &"":
		push_warning("[LCSSStyleTarget] '%s' é parte de uma família; registre o atalho '%s'." % [property, family])
		return
	var binding := Binding.new()
	binding.property = property
	binding.target = target
	var ctx := context if context != &"" else property
	_simple[ctx] = binding
	_contexts[ctx] = binding


func register_family(family: StringName, target: Node, context: StringName = &"") -> void:
	if not PropertyDefinition.FAMILIES.has(family):
		push_warning("[LCSSStyleTarget] '%s' não é uma família." % family)
		return
	var fb := FamilyBinding.new()
	fb.family = family
	fb.target = target
	fb.shorthand = context if context != &"" else family
	_contexts[fb.shorthand] = fb
	for member: StringName in PropertyDefinition.members_of(family):
		var suffix := String(member).trim_prefix(String(family))
		var ctx := StringName(String(fb.shorthand) + suffix)
		fb.members.append(ctx)
		_contexts[ctx] = fb
	_families[fb.shorthand] = fb


## Registra vários de uma vez. prefix "label_" gera label_font_color, label_font_size...
func register_group(properties: Array, target: Node, prefix: String = "") -> void:
	for property in properties:
		var context: StringName = &""
		if prefix != "":
			context = StringName(prefix + String(property))
		register_property(property, target, context)


## transition_duration / _easing / _properties: só configuram, não têm alvo.
func register_transitions() -> void:
	for ctx in PropertyDefinition.TRANSITION:
		_meta[ctx] = true
	for ctx in PropertyDefinition.ANIMATION:
		_meta[ctx] = true


## Liga as animações. O LuaComponent chama no fim do _ready (sem animação de entrada).
## Se precisar de animação de entrada, deixar um estado "invisível" no começo e transicionar
## a partir dele
func enable_transitions() -> void:
	_transitions_enabled = true


func unregister_property(context: StringName) -> void:
	_simple.erase(context)
	_contexts.erase(context)


func unregister_family(context: StringName) -> void:
	var fb: FamilyBinding = _families.get(context)
	if fb == null:
		return
	_contexts.erase(fb.shorthand)
	for m in fb.members:
		_contexts.erase(m)
	_families.erase(context)


func set_default(context: StringName, value: Variant) -> void:
	_defaults[context] = value
#endregion


#region Query
## Recebe o nome como escrito no .lua/.lcss (context)
func has_property(context: StringName) -> bool:
	return _contexts.has(context) or _meta.has(context)


func get_properties() -> Array[StringName]:
	var properties: Array[StringName] = []
	properties.assign(_contexts.keys())
	properties.append_array(_meta.keys())
	return properties


func get_target(context: StringName) -> Node:
	var entry: Variant = _contexts.get(context)
	return entry.target if entry != null else null


func apply_property(context: StringName, value: Variant, handler: Callable) -> bool:
	var entry: Variant = _contexts.get(context)
	if entry == null:
		return false
	handler.call(context, value, entry.target)
	return true
#endregion


#region Application
## `animate = false` aplica direto, sem tween (usado no boot e ao re-resolver descendentes).
func apply_style(style: LCSSStyle, overrides: Dictionary[StringName, Variant] = {}, animate := true) -> void:
	_last_style = style
	_last_overrides = overrides
	var transition: Transition = _read_transition(style, overrides) if (_transitions_enabled and animate) else null

	for context: StringName in _simple:
		var binding: Binding = _simple[context]
		var value: Variant = overrides[context] if overrides.has(context) else _style_value(style, context)
		if value == null:
			value = _defaults.get(context)
		var animating := _anim_values.has(context)
		if animating:
			value = _anim_values[context]
		_drive(context, binding.property, value, binding.target, null if animating else transition, false)

	for fb: FamilyBinding in _families.values():
		var layers: Array[Callable] = [
			func(p: StringName) -> Variant: return overrides.get(fb.context_of(p)),
			func(p: StringName) -> Variant: return _style_value(style, fb.context_of(p)),
			func(p: StringName) -> Variant: return _defaults.get(fb.context_of(p)),
		]
		var values: Variant = PropertyDefinition.resolve_family(fb.family, layers)
		var animating := _anim_values.has(fb.shorthand)
		if animating:
			values = _anim_values[fb.shorthand]
		_drive(fb.shorthand, fb.family, values, fb.target, null if animating else transition, true)

	_update_animation(style, overrides)


func _drive(key: StringName, property: StringName, value: Variant, target: Node,
		transition: Transition, is_family: bool) -> void:
	if value == null:
		# propriedade simples que saiu do estilo (ex.: saiu do :hover que era o único a defini-la)
		if _target_values.has(key):
			_cancel_tween(key)
			LCSSAppliers.reset(property, target)
			_target_values.erase(key)
			_shown.erase(key)
		return

	if _target_values.has(key) and _same(_target_values[key], value):
		return   # nada mudou: não reaplica e não reinicia o tween (nem o loop)

	var had_previous := _shown.has(key)
	var from: Variant = _shown.get(key)
	_target_values[key] = _copy(value)
	_cancel_tween(key)

	if transition == null or not had_previous or not transition.covers(key):
		_commit(key, property, value, target, is_family)
		return

	var kind := _kind(property, from, value, is_family)
	if kind == Kind.NONE:
		_commit(key, property, value, target, is_family)
		return

	var a: Variant = _normalize(kind, from)
	var b: Variant = _normalize(kind, value)
	var step: Callable = func(t: float): _step(key, property, kind, a, b, t, target, is_family)
	var d := transition.duration

	var tween := target.create_tween()
	tween.set_trans(transition.trans).set_ease(transition.ease_type)
	_tweens[key] = tween

	var infinite := transition.loop != PropertyDefinition.ONE_SHOT and transition.repetitions < 1
	match transition.loop:
		PropertyDefinition.PING_PONG:
			if infinite:
				tween.tween_method(step, 0.0, 1.0, d)
				tween.tween_method(step, 1.0, 0.0, d)
				tween.set_loops()   # sem argumento = infinito
			else:
				# desenrolado: n ciclos (A→B→A) e uma ida final, para assentar no alvo
				for i in transition.repetitions:
					tween.tween_method(step, 0.0, 1.0, d)
					tween.tween_method(step, 1.0, 0.0, d)
				tween.tween_method(step, 0.0, 1.0, d)
		PropertyDefinition.LOOP:
			tween.tween_method(step, 0.0, 1.0, d)
			if infinite:
				tween.set_loops()
			else:
				tween.set_loops(transition.repetitions)
		_:
			tween.tween_method(step, 0.0, 1.0, d)

	if infinite:
		return   # nunca termina: nada a assentar. Quem interrompe é o próximo _drive.

	# `finished` dispara uma vez, depois de todas as voltas (e não dispara com kill()).
	tween.finished.connect(func():
		if _tweens.get(key) != tween:
			return
		_tweens.erase(key)
		_commit(key, property, value, target, is_family))


func _commit(key: StringName, property: StringName, value: Variant, target: Node, is_family: bool) -> void:
	_shown[key] = _copy(value)
	_call_applier(property, value, target, is_family)


func _step(key: StringName, property: StringName, kind: int, a: Variant, b: Variant,
		t: float, target: Node, is_family: bool) -> void:
	if not is_instance_valid(target):
		return
	var v: Variant = _lerp(kind, a, b, t)
	_shown[key] = v
	_call_applier(property, v, target, is_family)


func _call_applier(property: StringName, value: Variant, target: Node, is_family: bool) -> void:
	if is_family:
		LCSSAppliers.apply_family(property, value, target)
	else:
		LCSSAppliers.apply(property, value, target)


func _cancel_tween(key: StringName) -> void:
	var tween: Tween = _tweens.get(key)
	if tween != null and tween.is_valid():
		tween.kill()
	_tweens.erase(key)
#endregion


#region Interpolação
static func _kind(property: StringName, from: Variant, to: Variant, is_family: bool) -> int:
	if PropertyDefinition.SCROLLBAR.has(property):
		return Kind.NONE   # scrollbar tween is very expensive. Disabled for now
	if is_family:
		return Kind.FAMILY if (from is Array and to is Array) else Kind.NONE
	if PropertyDefinition.type_of(property) == TYPE_COLOR:
		return Kind.COLOR
	if _is_numeric(from) and _is_numeric(to):
		return Kind.NUMBER if (_is_number(from) and _is_number(to)) else Kind.VECTOR
	return Kind.NONE


static func _is_number(v: Variant) -> bool:
	return v is int or v is float


static func _is_numeric(v: Variant) -> bool:
	if _is_number(v):
		return true
	if v is Array and not v.is_empty():
		for item in v:
			if not _is_number(item):
				return false
		return true
	return false


static func _normalize(kind: int, v: Variant) -> Variant:
	match kind:
		Kind.COLOR: return LuaHelper.parse_color(v)
		Kind.NUMBER: return float(v)
		Kind.VECTOR: return LuaHelper.parse_distributable(v)
	return v


static func _lerp(kind: int, a: Variant, b: Variant, t: float) -> Variant:
	match kind:
		Kind.COLOR:
			var ca: Color = a
			return ca.lerp(b, t)
		Kind.NUMBER:
			return lerpf(a, b, t)
		Kind.VECTOR:
			var out: Array = []
			for i in b.size():
				out.append(lerpf(a[i], b[i], t))
			return out
		Kind.FAMILY:
			# parte indefinida de um lado conta como 0; no fim o _commit aplica o alvo exato (com nulls)
			var out: Array = []
			out.resize(b.size())
			for i in b.size():
				var ai: Variant = a[i] if i < a.size() else null
				var bi: Variant = b[i]
				if ai == null and bi == null:
					out[i] = null
				else:
					out[i] = lerpf(float(ai) if ai != null else 0.0, float(bi) if bi != null else 0.0, t)
			return out
	return b


static func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


static func _copy(v: Variant) -> Variant:
	return v.duplicate() if v is Array else v
#endregion


#region Config
func _read_transition(style: LCSSStyle, overrides: Dictionary) -> Transition:
	var dur: Variant = _resolve(style, overrides, PropertyDefinition.TRANSITION_DURATION)
	var duration = dur
	if dur is LCSSProperty:
		duration = dur.value
	if duration == null or float(duration) <= 0.0:
		return null
	var t := Transition.new()
	t.duration = float(duration)

	var easing: Variant = _resolve(style, overrides, PropertyDefinition.TRANSITION_EASING)
	if easing != null and PropertyDefinition.EASINGS.has(StringName(str(easing))):
		var pair: Array = PropertyDefinition.EASINGS[StringName(str(easing))]
		t.trans = pair[0]
		t.ease_type = pair[1]
	
	var loop: Variant = _resolve(style, overrides, PropertyDefinition.TRANSITION_LOOP)
	if loop != null and PropertyDefinition.LOOP_OPTIONS.has(StringName(str(loop))):
		t.loop = StringName(str(loop))

	var repetitions: Variant = _resolve(style, overrides, PropertyDefinition.TRANSITION_REPETITIONS)
	if repetitions != null:
		t.repetitions = -1 if str(repetitions) == "infinite" else int(repetitions)

	var listed: Variant = _resolve(style, overrides, PropertyDefinition.TRANSITION_PROPERTIES)
	if listed is Array:
		for p in listed:
			t.properties.append(str(p))
	elif listed != null:
		for p in str(listed).replace(",", " ").split(" ", false):
			t.properties.append(p)
	return t


func _resolve(style: LCSSStyle, overrides: Dictionary, context: StringName) -> Variant:
	return overrides[context] if overrides.has(context) else _style_value(style, context)


func _style_value(style: LCSSStyle, context: StringName) -> Variant:
	if style != null and style.has_effective_property(context):
		return style.get_effective_property(context)
	return null

#endregion


#region Animação (@keyframes)
func _update_animation(style: LCSSStyle, overrides: Dictionary) -> void:
	if not _transitions_enabled:
		return
	var raw_name: Variant = _resolve(style, overrides, PropertyDefinition.ANIMATION_NAME)
	var spec := {
		"name": StringName(str(raw_name)) if raw_name != null else &"",
		"duration": _as_float(_resolve(style, overrides, PropertyDefinition.ANIMATION_DURATION), 0.0),
		"delay": _as_float(_resolve(style, overrides, PropertyDefinition.ANIMATION_DELAY), 0.0),
		"easing": _as_name(_resolve(style, overrides, PropertyDefinition.ANIMATION_EASING), PropertyDefinition.EASE_IN_OUT),
		"direction": _as_name(_resolve(style, overrides, PropertyDefinition.ANIMATION_DIRECTION), PropertyDefinition.NORMAL),
		"fill": _as_name(_resolve(style, overrides, PropertyDefinition.ANIMATION_FILL), PropertyDefinition.NONE),
		"iterations": _iterations(_resolve(style, overrides, PropertyDefinition.ANIMATION_ITERATIONS)),
	}
	var signature := var_to_str(spec)
	if signature == _anim_signature:
		return   # nada mudou: a animação em curso continua
	_anim_signature = signature
	_stop_animation(true)
	if spec.name == &"" or spec.duration <= 0.0:
		return
	_start_animation(spec)


func _start_animation(spec: Dictionary) -> void:
	var keyframes := LuaUi.lcss.find_keyframes(spec.name)
	if keyframes == null:
		push_warning("[LCSSStyleTarget] @keyframes '%s' não encontrado" % spec.name)
		return
	var tracks := _build_tracks(keyframes)
	var anchor := _anchor()
	if tracks.is_empty() or anchor == null:
		return
	if float(spec.delay) > 0.0:
		var wait := anchor.create_tween()
		_anim_tween = wait
		wait.tween_interval(spec.delay)
		wait.finished.connect(func():
			if _anim_tween == wait:
				_run_animation(tracks, spec))
	else:
		_run_animation(tracks, spec)


func _run_animation(tracks: Dictionary, spec: Dictionary) -> void:
	var anchor := _anchor()
	if anchor == null:
		return
	var d: float = spec.duration
	var step := func(t: float): _anim_step(tracks, t, spec.easing)
	var tween := anchor.create_tween()
	_anim_tween = tween
	tween.tween_method(step, 0.0, 1.0, d)
	if spec.direction == PropertyDefinition.ALTERNATE:
		tween.tween_method(step, 1.0, 0.0, d)
	var iterations: int = spec.iterations
	if iterations < 1:
		tween.set_loops()   # infinito: nunca termina, só é interrompida por outro estilo
		return
	if iterations > 1:
		tween.set_loops(iterations)
	tween.finished.connect(func():
		if _anim_tween != tween:
			return
		_anim_tween = null
		if spec.fill != PropertyDefinition.FORWARDS:
			_stop_animation(true))   # forwards mantém o último quadro


func _stop_animation(restore: bool) -> void:
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = null
	if _anim_values.is_empty():
		return
	_anim_values.clear()
	if restore:
		apply_style(_last_style, _last_overrides)   # volta ao estilo normal, com transição se houver


## Uma trilha por propriedade: pontos { offset, value }. Sem 0% ou 100%, parte do valor do estilo.
func _build_tracks(keyframes: LCSSKeyframes) -> Dictionary:
	var tracks := {}
	for key in keyframes.property_names():
		var entry: Variant = _contexts.get(key)
		if entry == null:
			push_warning("[LCSSStyleTarget] '%s' não é animável neste componente" % key)
			continue
		var is_family := entry is FamilyBinding
		if is_family and key != entry.shorthand:
			push_warning("[LCSSStyleTarget] anime '%s' inteiro; partes soltas não animam em @keyframes" % entry.shorthand)
			continue
		var points: Array = []
		for frame in keyframes.frames_for(key):
			points.append({
				"offset": frame.offset,
				"value": LuaHelper.parse_distributable(frame.value) if is_family else frame.value,
			})
		var base: Variant = _target_values.get(key)
		if base is Array:
			base = base.map(func(v): return 0.0 if v == null else v)
		if base != null:
			if points[0].offset > 0.0:
				points.push_front({"offset": 0.0, "value": base})
			if points[points.size() - 1].offset < 1.0:
				points.append({"offset": 1.0, "value": base})
		tracks[key] = {
			"property": entry.family if is_family else entry.property,
			"target": entry.target,
			"is_family": is_family,
			"points": points,
		}
	return tracks


func _anim_step(tracks: Dictionary, t: float, easing: StringName) -> void:
	var pair: Array = PropertyDefinition.EASINGS.get(easing, PropertyDefinition.EASINGS[PropertyDefinition.EASE_IN_OUT])
	for key: StringName in tracks:
		var track: Dictionary = tracks[key]
		var target: Node = track.target
		if not is_instance_valid(target):
			continue
		var value: Variant = _sample(track, t, pair)
		if value == null:
			continue
		_anim_values[key] = value
		_drive(key, track.property, value, target, null, track.is_family)


static func _sample(track: Dictionary, t: float, pair: Array) -> Variant:
	var points: Array = track.points
	if points.is_empty():
		return null
	if t <= points[0].offset:
		return points[0].value
	if t >= points[points.size() - 1].offset:
		return points[points.size() - 1].value
	for i in points.size() - 1:
		var a: Dictionary = points[i]
		var b: Dictionary = points[i + 1]
		if t > b.offset:
			continue
		var span: float = b.offset - a.offset
		var r: float = 0.0 if span <= 0.0 else (t - a.offset) / span
		r = Tween.interpolate_value(0.0, 1.0, r, 1.0, pair[0], pair[1])
		var kind := _kind(track.property, a.value, b.value, track.is_family)
		if kind == Kind.NONE:
			return a.value if r < 0.5 else b.value
		return _lerp(kind, _normalize(kind, a.value), _normalize(kind, b.value), r)
	return points[points.size() - 1].value


func _anchor() -> Node:
	for entry in _contexts.values():
		if is_instance_valid(entry.target) and entry.target.is_inside_tree():
			return entry.target
	return null


func _as_float(v: Variant, fallback: float) -> float:
	return float(v) if v != null else fallback


func _as_name(v: Variant, fallback: StringName) -> StringName:
	return StringName(str(v)) if v != null and str(v) != "" else fallback


func _iterations(v: Variant) -> int:
	if v == null:
		return 1
	return -1 if str(v) == "infinite" else int(v)
#endregion
