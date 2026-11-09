class_name LuaComponent extends Control
## Raiz de todo componente. Um componente fora de um slot flow usa
## o tamanho natural do próprio root

signal prop_changed(key: String, value: Variant)
signal disposing

static var debug_skip_style := false

# Common methods allowd in UI.callMethod()
const BASE_METHODS: Array[String] = ["add_class", "remove_class", "toggle_class", "set_state", "get_state", "set_prop",
		"set_effect_param", "tween_effect_param"]
const BASE_EVENTS: Array[String] = ["drag_preview", "can_drop", "drop", "drag_start", "drag_end"]

var component_name: String = ""
var component_id: String = ""
var props: Dictionary = {}
var handlers: Dictionary = {}

var _given: Dictionary = {}
var _has_given := false

## Classes LCSS atribuídas via prop "class".
var style_classes: Array[StringName] = []

var _style: LCSSStyle
var _style_target := LCSSStyleTarget.new()
var _style_overrides: Dictionary[StringName, Variant] = {}
var _batching := false

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

const DND_KEY := &"lua_drag_type"
var _dnd_installed := false
var _dnd_source := false
var _dnd_feedback := &""

#region Override points
func get_schema() -> Dictionary:
	return {}

func _apply_prop(key: String, value: Variant) -> void:
	var prop := StringName(key)
	if value != null and _style_target.has_property(prop):
		_style_overrides[prop] = value
		if not _batching:
			_style_target.apply_style(_style, _style_overrides)

func _component_ready() -> void:
	pass
#endregion


#region Lifecycle
func setup(p_name: String, p_props: Dictionary, p_handlers: Dictionary, p_schema: Dictionary, p_bindings: Dictionary = {}, p_given: Variant = null) -> void:
	component_name = p_name
	props = p_props
	handlers = p_handlers
	_schema = p_schema
	_bindings = p_bindings
	# disponíveis antes de entrar na árvore: resolve único e correto no _ready
	var cls = props.get(PropertyDefinition.CLASS)
	if cls != null:
		style_classes = LuaHelper.parse_style_classes(cls)
	if p_given != null:
		_given = p_given
		_has_given = true


func _ready() -> void:
	_style_target.register_transitions()
	_batching = true
	var base := ComponentRegistry.base_props()
	for key: String in props:
		if _has_given and not _given.has(key) and base.has(key) and key != PropertyDefinition.VISIBLE:
			continue
		_apply_prop_internal(key, props[key])
	_batching = false
	_refresh_style(false, false)
	_is_ready = true
	_component_ready()
	_style_target.enable_transitions()
	_connect_bindings()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			handlers.clear()
		NOTIFICATION_DRAG_END:   # chega a TODOS os controles da árvore quando qualquer drag termina
			_dnd_finish()


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
	if PropertyDefinition.DND_GRP.has(StringName(key)):
		_refresh_dnd()
		return
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
			if not _batching:
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
	if debug_skip_style:
		return
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


#region Drag & drop de dados
## Arrasta DADOS entre componentes (itens de inventário, cartas...) com o drag nativo do Godot:
## a origem fica onde está e um "fantasma" segue o mouse. (Não confundir com `draggable`, que MOVE o componente.)
##
## Props:  drag_payload = { ... }  tabela não vazia liga o arraste; viaja com o drag
##         drag_type    = "tipo"   etiqueta do payload
##         drop_accept  = "tipo"   tipos aceitos como alvo, separados por espaço ("" = não é alvo)
## Hooks (Lua):
##   on_drag_preview()              -> componente usado como fantasma (sem ele, não há fantasma)
##   on_can_drop(payload, mods)     -> bool. Roda a CADA movimento do mouse sobre o alvo: mantenha leve
##   on_drop(payload, mods)         mods = { shift, ctrl, alt } no momento da soltura
##   on_drag_start()  /  on_drag_end(dropped)
## Classes automáticas: "dragging" na origem; "drop-ok" / "drop-deny" no alvo sob o mouse.

## Override: o Control que recebe o mouse (e portanto o drag). Padrão: o próprio componente.
func _dnd_surface() -> Control:
	return self


func _refresh_dnd() -> void:
	if _dnd_installed:
		return   # instalado uma vez; os callbacks leem as props na hora, então mudar em runtime funciona
	var payload: Variant = props.get(PropertyDefinition.DRAG_PAYLOAD)
	var is_source := payload is Dictionary and not (payload as Dictionary).is_empty()
	var is_target := str(props.get(PropertyDefinition.DROP_ACCEPT, "")) != ""
	if not is_source and not is_target:
		return
	var surface := _dnd_surface()
	if surface == null:
		push_warning("[LuaComponent:%s] drag_payload/drop_accept não suportado: sem superfície de mouse." % component_name)
		return
	_dnd_installed = true
	# o drag do Godot começa no controle sob o mouse e só sobe aos pais se o filtro dele não for STOP;
	# por isso o forwarding vai na superfície que de fato recebe o mouse, não no nó raiz
	surface.set_drag_forwarding(_dnd_begin, _dnd_can_drop, _dnd_drop)
	surface.mouse_exited.connect(_dnd_clear_feedback)


func _dnd_begin(_at_position: Vector2) -> Variant:
	var payload: Variant = props.get(PropertyDefinition.DRAG_PAYLOAD)
	if not (payload is Dictionary) or (payload as Dictionary).is_empty():
		return null
	var preview: Variant = call_hook("on_drag_preview")
	if preview is UIElement:
		_dnd_set_preview(preview as UIElement)
	_dnd_source = true
	add_class("dragging")
	emit_event("drag_start")
	return {DND_KEY: str(props.get(PropertyDefinition.DRAG_TYPE, "")), "payload": (payload as Dictionary).duplicate(true)}


## O fantasma vive numa camada própria, sempre acima de modais e popups (ver LuaDragGhost).
func _dnd_set_preview(element: UIElement) -> void:
	var node := ComponentRegistry.instantiate(element) as Control
	if node != null:
		LuaDragGhost.spawn(node)


func _dnd_accepts(data: Variant) -> bool:
	if not (data is Dictionary) or not (data as Dictionary).has(DND_KEY):
		return false
	var accepted := str(props.get(PropertyDefinition.DROP_ACCEPT, "")).split(" ", false)
	return str(data[DND_KEY]) in accepted


func _dnd_can_drop(_at_position: Vector2, data: Variant) -> bool:
	if not _dnd_accepts(data):
		_dnd_clear_feedback()
		return false
	var ok := true
	var hook: Callable = handlers.get("on_can_drop", Callable())
	if hook.is_valid():
		ok = hook.call(data["payload"], _dnd_modifiers()) == true
	_dnd_set_feedback(&"drop-ok" if ok else &"drop-deny")
	return ok


func _dnd_drop(_at_position: Vector2, data: Variant) -> void:
	_dnd_clear_feedback()
	# adiado: o on_drop costuma mudar a store, e isso recria a lista inteira; fazer isso
	# no meio do despacho de entrada do Godot (com a origem e o alvo ainda em uso) é arriscado
	_dnd_emit_drop.call_deferred(data["payload"], _dnd_modifiers())


func _dnd_emit_drop(payload: Variant, mods: Dictionary) -> void:
	emit_event("drop", [payload, mods])


func _dnd_finish() -> void:
	_dnd_clear_feedback()
	if _dnd_source:
		_dnd_source = false
		remove_class("dragging")
		emit_event("drag_end", [get_viewport().gui_is_drag_successful()])


func _dnd_clear_feedback() -> void:
	_dnd_set_feedback(&"")


func _dnd_set_feedback(feedback: StringName) -> void:
	if feedback == _dnd_feedback:
		return
	if _dnd_feedback != &"":
		remove_class(_dnd_feedback)
	_dnd_feedback = feedback
	if feedback != &"":
		add_class(feedback)


static func _dnd_modifiers() -> Dictionary:
	return {
		"shift": Input.is_key_pressed(KEY_SHIFT),
		"ctrl": Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META),
		"alt": Input.is_key_pressed(KEY_ALT),
	}
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
