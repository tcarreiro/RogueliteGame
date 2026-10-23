extends Node
## Autoload: LuaUI  (depois de ComponentRegistry)
## Dono do LuaState de UI. Expõe o namespace `UI`, uma "tag" global por
## componente, e a LCSSRegistry compartilhada por todos os LuaComponent.

var state: LuaState
var lcss := LCSSRegistry.new()
var _root: Control

var _stores: Dictionary = {}          # nome -> ReactiveDictionary registrado pelo host
var _root_handles: Dictionary = {}    # nome -> Dictionary do handle (um por store)
var _handles: Dictionary = {}         # id -> LuaStoreHandle
var _next_handle_id := 0

func _ready() -> void:
	state = LuaState.new()
	state.open_libraries()
	state.globals["UI"] = {
		"defineComponent": _lua_define_component,
		"getComponent": _lua_get_component,
		"mount": _lua_mount,
		"callMethod": _lua_call_method,
		"store": _lua_store,
		"bind": _lua_bind,
		"playSoundEffect": _lua_play_sound_effect,
	}
	ComponentRegistry.component_registered.connect(_expose_tag)
	for component_name in ComponentRegistry.get_names():
		_expose_tag(component_name)


## Executa um .lua (é assim que componentes Lua são registrados).
func load_file(path: String) -> bool:
	var result: Variant = state.do_file(path)
	if result is LuaError:
		push_error("[LuaUI] %s: %s" % [path, result])
		return false
	return true


func set_root(root: Control) -> void:
	_root = root


## Carrega um arquivo .lcss (LCSS = a linguagem de estilo do framework).
func load_lcss(path: String) -> void:
	lcss.register_file(path)


## O host registra o que o Lua pode enxergar. Nada fora desta lista é acessível.
func expose_store(store_name: String, store: ReactiveDictionary) -> void:
	_stores[store_name] = store


func make_draft(source: LuaStoreHandle) -> Dictionary:
	return _register_handle(ReactiveDictionary.new(source.store.value.duplicate(true)), source.store)


## Chame ao trocar de tela: libera os rascunhos da tela que saiu.
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
		push_error("[UI] store '%s' não foi exposta pelo projeto" % key)
		return null
	if not _root_handles.has(key):
		_root_handles[key] = _register_handle(_stores[key])
	return _root_handles[key]


## UI.bind(handle, 'chave')          -> valor de uma chave
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
		getter = LuaHelper.make_callable(source)
	if not getter.is_valid():
		push_error("[UI] bind: informe uma chave (texto) ou uma função")
		return null
	return LuaBinding.new(stores, getter)


func _lua_play_sound_effect(sound_name: StringName) -> void:
	#TODO create sound registry
	#TODO AudioManager autoload?
	#TODO AudioManager.play_at_bus(sound_name, bus_name)
	print("play sound %s"%[sound_name])

#endregion


#region Helpers
## Button{...}, Stats{...}: cada componente registrado vira uma função global.
func _expose_tag(component_name: String) -> void:
	if not component_name.is_valid_ascii_identifier():
		return
	state.globals[component_name] = func(raw = null):
		return ComponentRegistry.make_element(component_name, LuaHelper.as_dict(raw))

func _register_handle(store: ReactiveDictionary, origin: ReactiveDictionary = null) -> Dictionary:
	var handle := LuaStoreHandle.new(_next_handle_id, store, origin)
	_next_handle_id += 1
	_handles[handle.id] = handle
	return handle.to_lua()
#endregion
