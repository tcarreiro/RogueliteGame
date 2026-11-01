extends Node
## Autoload: LuaUI  (after ComponentRegistry!!)

var state: LuaState
var lcss := LCSSRegistry.new()
var _root: Control

var _stores: Dictionary = {}          # nome -> ReactiveDictionary registrado pelo host
var _readonly_stores: Dictionary = {} # nome -> true quando o Lua só pode ler
var _root_handles: Dictionary = {}    # nome -> Dictionary do handle (um por store)
var _handles: Dictionary = {}         # id -> LuaStoreHandle
var _next_handle_id := 0

func _ready() -> void:
	state = LuaState.new()
	state.open_libraries(LuaState.LUA_BASE | LuaState.LUA_TABLE | LuaState.LUA_STRING
	| LuaState.LUA_MATH | LuaState.LUA_UTF8 | LuaState.LUA_COROUTINE
	| LuaState.GODOT_VARIANT | LuaState.GODOT_UTILITY_FUNCTIONS | LuaState.GODOT_ENUMS)
	state.globals["dofile"] = null
	state.globals["loadfile"] = null
	state.globals["UI"] = {
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


func _lua_mount(el: Variant) -> void:
	var element: UIElement = el
	if _root and element:
		_root.add_child(ComponentRegistry.instantiate(element))


func _lua_store(store_name: Variant) -> Variant:
	var key := str(store_name)
	if not _stores.has(key):
		push_error("[UI] store '%s' not exposed to project" % key)
		return null
	if not _root_handles.has(key):
		_root_handles[key] = _register_handle(_stores[key], null, _readonly_stores.get(key, false))
	return _root_handles[key]


## UI.bind(handle, 'chave')             -> valor de uma chave
## UI.bind(handle, function() ... end)  -> valor calculado (reavalia quando a store muda)
## UI.bind({a, b}, function() ... end)  -> várias dependências
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
