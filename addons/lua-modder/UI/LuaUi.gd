extends Node
## Autoload: LuaUI  (after ComponentRegistry!!)

var state: LuaState
var lcss := LCSSRegistry.new()
var _root: Control

var _stores: Dictionary = {}          # name -> ReactiveDictionary registered by host
var _readonly_stores: Dictionary = {} # name -> bool (true = readonly)
var _root_handles: Dictionary = {}    # name -> handle's Dictionary
var _component_handlers: Dictionary = {}
var _handles: Dictionary = {}         # id -> LuaStoreHandle
var _next_handle_id := 0

var _drag_layer: CanvasLayer

func _ready() -> void:
	state = LuaState.new()
	state.open_libraries(LuaState.LUA_BASE | LuaState.LUA_TABLE | LuaState.LUA_STRING
	| LuaState.LUA_MATH | LuaState.LUA_UTF8 | LuaState.LUA_COROUTINE
	| LuaState.GODOT_VARIANT | LuaState.GODOT_UTILITY_FUNCTIONS | LuaState.GODOT_ENUMS)
	state.globals["dofile"] = null
	state.globals["loadfile"] = null
	state.globals["UI"] = {
		"getTime": _lua_get_current_time,
		"goToScene": _lua_goto_scene,
		"quit": _lua_quit_game,
		"defineComponent": _lua_define_component,
		"getComponent": _lua_get_component,
		"mount": _lua_mount,
		"callMethod": _lua_call_method,
		"store": _lua_store,
		"bind": _lua_bind,
	}
	ComponentRegistry.component_registered.connect(_expose_tag)
	for component_name in ComponentRegistry.get_names():
		_expose_tag(component_name)


## Register components from .lua file
func load_file(path: String) -> bool:
	var result: Variant = state.do_file(path)
	if result is LuaError:
		push_error("[LuaUI] %s: %s" % [path, result])
		return false
	return true


func set_root(root: Control) -> void:
	_root = root
	release_drafts()


## Register lcss style from .lcss file
func load_lcss(path: String) -> void:
	lcss.register_file(path)


## O host registra o que o Lua pode enxergar. Nada fora desta lista é acessível.
func expose_store(store_name: String, store: ReactiveDictionary, readonly := false) -> void:
	_stores[store_name] = store
	_readonly_stores[store_name] = readonly
	var old: Variant = _root_handles.get(store_name)
	if old is Dictionary:
		_handles.erase(int(old["_id"]))
	_root_handles.erase(store_name)


func get_store(store_name: String) -> ReactiveDictionary:
	return _stores.get(store_name)


## Camada do fantasma do drag de dados: acima dos modais (camada 1) e dos popups (LuaPopupLayer.LAYER_INDEX).
func get_drag_layer() -> CanvasLayer:
	if not is_instance_valid(_drag_layer):
		_drag_layer = CanvasLayer.new()
		_drag_layer.name = "DragLayer"
		_drag_layer.layer = LuaPopupLayer.LAYER_INDEX + 1
		add_child(_drag_layer)
	return _drag_layer


func make_draft(source: LuaStoreHandle) -> Dictionary:
	return _register_handle(ReactiveDictionary.new(source.store.value.duplicate(true)), source.store, false, source.readonly)


## Clear drafts from previous screens.
func release_drafts() -> void:
	for id in _handles.keys():
		if (_handles[id] as LuaStoreHandle).is_draft():
			_handles.erase(id)


#region Lua-facing API
func _lua_define_component(component_name: Variant, definition: Variant) -> void:
	ComponentRegistry.register_lua(str(component_name), LuaHelper.as_dict(definition))


func _lua_get_component(component_name: Variant, raw: Variant = null) -> Variant:
	return ComponentRegistry.make_element(str(component_name), LuaHelper.as_dict(raw))


func _lua_call_method(ref: Variant, method: Variant, args: Variant = null) -> Variant:
	var a: Variant = LuaHelper.normalize_lua(args)
	return ComponentRegistry.call_method(str(ref), str(method), a if a is Array else [])

func _lua_get_current_time() -> int:
	return Time.get_ticks_usec()


func _lua_goto_scene(scene_name: String) -> void:
	# TODO: Handle here save game
	Configuration.goto_scene(scene_name)


func _lua_quit_game() -> void:
	get_tree().quit()


func _lua_mount(el: Variant) -> void:
	var element: UIElement = el
	if _root and element:
		if element.ref != null and element.ref != "":
			var _handler_id := element.ref
			if (not _component_handlers.has(_handler_id) or _component_handlers[_handler_id] == null):
				_component_handlers.erase(_handler_id)
				_component_handlers[_handler_id] = ComponentRegistry.instantiate(element)
				_root.add_child(_component_handlers[_handler_id])
				Perf.dump()
			else:
				_component_handlers[_handler_id].queue_free()
			return
		_root.add_child(ComponentRegistry.instantiate(element))


func _lua_store(store_name: Variant) -> Variant:
	var key := str(store_name)
	if not _stores.has(key):
		push_error("[UI] store '%s' not exposed to project" % key)
		return null
	if not _root_handles.has(key):
		_root_handles[key] = _register_handle(_stores[key], null, _readonly_stores.get(key, false))
	return _root_handles[key]


## UI.bind(handle, 'key')             -> get "key" property (kinda vue's ref())
## UI.bind(handle, function() ... end)  -> compute value (kinda vue's compute())
## UI.bind({a, b}, function() ... end)  -> multiple dependencies
func _lua_bind(deps: Variant, source: Variant = null) -> Variant:
	var normalized: Variant = LuaHelper.normalize_lua(deps)
	var entries: Array = normalized if normalized is Array else [normalized]
	var handles: Array[LuaStoreHandle] = []
	for entry in entries:
		if entry is Dictionary and entry.has("_id") and _handles.has(int(entry["_id"])):
			handles.append(_handles[int(entry["_id"])])
		else:
			push_error("[UI] bind: use o resultado de UI.store(...) ou de handle.draft()")
	if handles.is_empty():
		return null

	var stores: Array[Reactive] = []
	for h in handles:
		stores.append_array(h.dependencies())

	var getter: Callable
	if source is String:
		var key: String = source
		getter = func() -> Variant: return handles[0].store.get_at(key)
	else:
		getter = LuaHelper.make_callable(source, "UI.bind")
	if not getter.is_valid():
		push_error("[UI] bind: informe uma chave (texto) ou uma função")
		return null
	return LuaBinding.new(stores, getter)
#endregion


#region Helpers
## Button{...}, Stats{...}: cada componente registrado vira uma função global.
func _expose_tag(component_name: String) -> void:
	if not component_name.is_valid_ascii_identifier():
		return
	state.globals[component_name] = func(raw = null):
		return ComponentRegistry.make_element(component_name, LuaHelper.as_dict(raw))


func _register_handle(store: ReactiveDictionary, origin: ReactiveDictionary = null, readonly := false, origin_readonly := false) -> Dictionary:
	var handle := LuaStoreHandle.new(_next_handle_id, store, origin, readonly, origin_readonly)
	_next_handle_id += 1
	_handles[handle.id] = handle
	return handle.to_lua()
#endregion
