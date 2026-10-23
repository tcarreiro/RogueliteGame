class_name LuaComponent extends Control
## Raiz de todo componente. Um componente fora de um slot flow usa
## o tamanho natural do próprio root

signal prop_changed(key: String, value: Variant)
signal disposing

# Common methods allowd in UI.callMethod()
const BASE_METHODS: Array[String] = ["add_class", "remove_class", "toggle_class", "set_state", "get_state", "set_prop",
		"set_effect_param", "tween_effect_param"]
const DRAG_EVENTS := ["drag_started", "drag_ended"]

var component_name: String = ""
var component_id: String = ""
var props: Dictionary = {}
var handlers: Dictionary = {}

## Classes LCSS atribuídas via prop "class".
var style_classes: Array[StringName] = []

var _style: LCSSStyle
var _style_target := LCSSStyleTarget.new()
var _style_overrides: Dictionary[StringName, Variant] = {}

var _fx_material: ShaderMaterial
var _fx_specs: Array = []
var _fx_tweens: Dictionary = {}

var _schema: Dictionary = {}
var _is_ready := false
var _slot_cache: Dictionary = {}

var _bindings: Dictionary = {}
var _binding_links: Array = []   # [binding, callable]

var _drag: LuaDragController
var _drag_refresh_queued := false

#region Override points
func get_schema() -> Dictionary:
	return {}

func _apply_prop(key: String, value: Variant) -> void:
	var prop := StringName(key)
	if value != null and _style_target.has_property(prop):
		_style_overrides[prop] = value
		_style_target.apply_style(_style, _style_overrides)

func _component_ready() -> void:
	pass
#endregion


#region Lifecycle
func setup(p_name: String, p_props: Dictionary, p_handlers: Dictionary, p_schema: Dictionary, p_bindings: Dictionary = {}) -> void:
	component_name = p_name
	props = p_props
	handlers = p_handlers
	_schema = p_schema
	_bindings = p_bindings


func _ready() -> void:
	_style_target.register_transitions()
	for key: String in props:
		_apply_prop_internal(key, props[key])
	_is_ready = true
	_component_ready()
	_style_target.enable_transitions()
	_connect_bindings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		handlers.clear()


func dispose() -> void:
	disposing.emit()
	handlers.clear()
	queue_free()
#endregion


#region Props
func set_prop(key: String, value: Variant) -> void:
	var def: Dictionary = ComponentRegistry.get_prop_def(_schema, key)
	if def.is_empty():
		push_warning("[LuaComponent:%s] prop desconhecida '%s'" % [component_name, key])
		return
	props[key] = ComponentRegistry.coerce(value, def)
	if _is_ready:
		_apply_prop_internal(key, props[key])
		prop_changed.emit(key, props[key])


func _apply_prop_internal(key: String, value: Variant) -> void:
	if PropertyDefinition.DRAG_GRP.has(StringName(key)):
		_apply_drag_prop(StringName(key))
		return
	match key:
		PropertyDefinition.ID:
			component_id = value
			if value != "":
				name = value
		PropertyDefinition.CLASS:
			style_classes = LuaHelper.parse_style_classes(value)
			_refresh_style(true, _is_ready)
		PropertyDefinition.VISIBLE:
			visible = value
		PropertyDefinition.TOOLTIP:
			tooltip_text = value
		PropertyDefinition.FLEX_GROW:
			_apply_flex_grow(float(value))
		PropertyDefinition.ALIGN_SELF:
			_apply_align_self(StringName(str(value)))
		PropertyDefinition.JUSTIFY_SELF:
			_apply_justify_self(StringName(str(value)))
		PropertyDefinition.POINTER_EVENTS:
			mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED if str(value) == "none" else Control.MOUSE_BEHAVIOR_INHERITED
		PropertyDefinition.EFFECTS:
			_apply_effects(value)
		_:
			_apply_prop(key, value)

func _refresh_style(deep := false, animate := true) -> void:
	# o resolve cria um LCSSStyle novo: preserva os estados ativos (hover etc.)
	
	var active: Array = _style.get_active_states() if _style != null else []
	_style = LCSSResolver.resolve(self, LuaUi.lcss)
	for state in active:
		_style.set_state_active(state, true)
	_style_target.apply_style(_style, _style_overrides, animate)
	if deep:
		_refresh_descendant_styles(self, animate)


func _refresh_descendant_styles(node: Node, animate: bool) -> void:
	for child in node.get_children():
		if child is LuaComponent:
			(child as LuaComponent)._refresh_style(false, animate)
		_refresh_descendant_styles(child, animate)
#endregion


#region Drag
## Override: nó que se move no arraste. null = o componente não é arrastável.
func _drag_target() -> Control:
	return null


## Override: região usada quando nenhum descendente declara drag_handle = true.
func _drag_default_handle() -> Control:
	return null


## Override: o Control que vira região quando ESTE componente declara drag_handle = true.
func _drag_handle_node() -> Control:
	return null


func _apply_drag_prop(key: StringName) -> void:
	if key == PropertyDefinition.DRAG_HANDLE:
		if _is_ready:
			_notify_ancestor_drag()   # handle novo ou removido em runtime
		return
	# em lote: as 4 props de arraste chegam em sequência no _ready, e os descendentes já estão prontos
	if not _drag_refresh_queued:
		_drag_refresh_queued = true
		_refresh_drag.call_deferred()


func _refresh_drag() -> void:
	_drag_refresh_queued = false
	var enabled := bool(props.get("draggable", false))
	if _drag == null:
		if not enabled:
			return
		var target := _drag_target()
		if target == null:
			push_warning("[LuaComponent:%s] 'draggable' não é suportado: falta _drag_target()." % component_name)
			return
		_drag = LuaDragController.new()
		add_child(_drag)
		_drag.setup(self, target, _drag_default_handle())
		_drag.drag_started.connect(func():
			set_state(&"dragging", true)
			emit_event("drag_started"))
		_drag.drag_ended.connect(func(offset: Vector2):
			set_state(&"dragging", false)
			emit_event("drag_ended", [offset.x, offset.y]))
	_drag.configure(
		enabled,
		StringName(str(props.get("drag_mode", "hold"))),
		StringName(str(props.get("drag_bounds", "viewport"))),
		PropertyDefinition.CURSORS.get(StringName(str(props.get("drag_cursor", "move"))), Control.CURSOR_MOVE))
	_refresh_drag_handles()


func _refresh_drag_handles() -> void:
	if _drag != null:
		_drag.set_handles(_collect_drag_handles())


func _collect_drag_handles() -> Array[Control]:
	var out: Array[Control] = []
	_collect_handles_in(self, out)
	return out


func _collect_handles_in(node: Node, out: Array[Control]) -> void:
	for child in node.get_children():
		var component := child as LuaComponent
		if component != null:
			if bool(component.props.get("draggable", false)):
				continue   # um arrastável aninhado é dono dos próprios handles
			if bool(component.props.get("drag_handle", false)):
				var handle := component._drag_handle_node()
				if handle != null:
					out.append(handle)
		_collect_handles_in(child, out)


func _notify_ancestor_drag() -> void:
	var node := get_parent()
	while node != null:
		var component := node as LuaComponent
		if component != null and component._drag != null:
			component._refresh_drag_handles()
			return
		node = node.get_parent()


## Exposto ao Lua: volta o componente para a posição original.
func reset_drag_position() -> void:
	if _drag != null:
		_drag.reset()
#endregion

#region LCSS
func has_class(style_class: StringName) -> bool:
	return style_classes.has(style_class)


func is_style_state_active(state: StringName) -> bool:
	return _style != null and _style.is_state_active(state)


func set_state(state: StringName, active: bool) -> void:
	if _style == null:
		return
	_style.set_state_active(state, active)
	_style_target.apply_style(_style, _style_overrides)


func get_state(state: StringName) -> bool:
	if _style == null:
		return false
	return _style.get_active_states().has(state)


## Conecta hover/focus/pressed de um Control interno (ex: o Button real
## dentro do slot) aos estados LCSS. Chame em _component_ready() do
## componente que tiver essa superfície.
func _bind_style_state_source(source: Control) -> void:
	source.mouse_entered.connect(func(): set_state(&"hover", true))
	source.mouse_exited.connect(func(): set_state(&"hover", false))
	source.focus_entered.connect(func(): set_state(&"focus", true))
	source.focus_exited.connect(func(): set_state(&"focus", false))
	if source.has_signal("button_down"):
		source.button_down.connect(func(): set_state(&"pressed", true))
		source.button_up.connect(func(): set_state(&"pressed", false))
#endregion


#region Lua communication
func emit_event(event: String, args: Array = []) -> void:
	var cb: Callable = handlers.get("on_" + event, Callable())
	if cb.is_valid():
		cb.callv(args)


func call_hook(hook: String, args: Array = [], default: Variant = null) -> Variant:
	var cb: Callable = handlers.get(hook, Callable())
	if not cb.is_valid():
		return default
	var result: Variant = cb.callv(args)
	return default if result == null else result


func forward_signal(source: Signal, event: String) -> void:
	source.connect(func(...args): emit_event(event, args))


func call_exposed(method: String, args: Array = []) -> Variant:
	if method not in BASE_METHODS and method not in _schema.get("methods", []):
		push_error("[LuaComponent:%s] método '%s' não está exposto no schema" % [component_name, method])
		return null
	if not has_method(method):
		push_error("[LuaComponent:%s] método '%s' declarado mas não implementado" % [component_name, method])
		return null
	return callv(method, args)


func add_class(style_class: String) -> void:
	var sn := StringName(style_class)
	if sn == &"" or style_classes.has(sn):
		return
	style_classes.append(sn)
	_refresh_style(true)


func remove_class(style_class: String) -> void:
	var sn := StringName(style_class)
	if not style_classes.has(sn):
		return
	style_classes.erase(sn)
	_refresh_style(true)


func toggle_class(style_class: String, force: Variant = null) -> void:
	var want: bool = (not has_class(StringName(style_class))) if force == null else bool(force)
	if want:
		add_class(style_class)
	else:
		remove_class(style_class)


#endregion


#region Slots
func get_slot(slot_name: String) -> Node:
	if _slot_cache.has(slot_name):
		return _slot_cache[slot_name]
	var path: String = _schema.get("slots", {}).get(slot_name, "")
	if path == "":
		return null
	var node := get_node_or_null(path)
	_slot_cache[slot_name] = node
	return node
#endregion

#region Bindings
func _connect_bindings() -> void:
	if _bindings.is_empty():
		return
	for key: String in _bindings:
		var binding: LuaBinding = _bindings[key]
		var callback := _on_binding_changed.bind(key, binding)
		binding.changed.connect(callback)
		_binding_links.append([binding, callback])
	tree_exiting.connect(_disconnect_bindings)


func _disconnect_bindings() -> void:
	for link in _binding_links:
		if link[0].changed.is_connected(link[1]):
			link[0].changed.disconnect(link[1])
	_binding_links.clear()


func _on_binding_changed(key: String, binding: LuaBinding) -> void:
	set_prop(key, binding.evaluate())
#endregion


#region Model
func _has_model() -> bool:
	return _bindings.has(String(PropertyDefinition.MODEL))


## Componentes de valor chamam isto quando o USUÁRIO muda o valor.
func _write_model(value: Variant) -> void:
	var model := _bindings.get(String(PropertyDefinition.MODEL)) as LuaModel
	if model != null:
		model.write(value)
#endregion


#region Flow (layout dentro de um LuaFlowBox)
func _apply_flex_grow(grow: float) -> void:
	set_meta(PropertyDefinition.FLEX_GROW, grow)
	_refresh_in_parent_flow()


func _apply_align_self(value: StringName) -> void:
	set_meta(PropertyDefinition.ALIGN_SELF, value)
	_refresh_in_parent_flow()


func _apply_justify_self(value: StringName) -> void:
	set_meta(&"justify_self", value)
	_refresh_in_parent_flow()


func _refresh_in_parent_flow() -> void:
	var parent := get_parent()
	if parent != null and parent.has_method(&"refresh_child"):
		parent.refresh_child(self)
#endregion


#region Effects
func _apply_effects(raw: Variant) -> void:
	if raw == null and _fx_material == null:
		return
	_fx_specs = LuaEffectLibrary.parse_specs(raw)
	if _fx_specs.is_empty():
		_fx_material = null
		material = null
		_share_material(self, false)
		return
	_fx_material = LuaEffectLibrary.build_material(_fx_specs)
	material = _fx_material
	_share_material(self, true)


## Os descendentes desenham com o material do componente. Um componente aninhado que tem
## material próprio fica de fora, junto com o que há dentro dele.
func _share_material(node: Node, on: bool) -> void:
	for child in node.get_children():
		if child is CanvasItem and (child as CanvasItem).material == null:
			(child as CanvasItem).use_parent_material = on
			_share_material(child, on)


## Exposto ao Lua. O índice é o do Lua (1 = primeiro efeito).
func set_effect_param(index: int, param: String, value: Variant) -> void:
	var default: Variant = _effect_default(index, param)
	if default != null:
		_fx_material.set_shader_parameter(LuaEffectLibrary.uniform_name(index - 1, param), LuaEffectLibrary.convert(default, value))


func tween_effect_param(index: int, param: String, to: float, seconds: float) -> void:
	var default: Variant = _effect_default(index, param)
	if default == null or default is Color:
		return
	var uname := LuaEffectLibrary.uniform_name(index - 1, param)
	var current: Variant = _fx_material.get_shader_parameter(uname)
	if _fx_tweens.has(uname) and is_instance_valid(_fx_tweens[uname]):
		_fx_tweens[uname].kill()
	var tween := create_tween()
	_fx_tweens[uname] = tween
	tween.tween_method(func(v: float): _fx_material.set_shader_parameter(uname, v),
			float(current if current != null else default), to, seconds)


func _effect_default(index: int, param: String) -> Variant:
	if _fx_material == null or index < 1 or index > _fx_specs.size():
		push_warning("[Effects] não há efeito no índice %d" % index)
		return null
	var defaults: Dictionary = LuaEffectLibrary.PRESETS[_fx_specs[index - 1].name].defaults
	if not defaults.has(param):
		push_warning("[Effects] '%s' não é parâmetro (use: %s)" % [param, str(defaults.keys())])
		return null
	return defaults[param]
#endregion
