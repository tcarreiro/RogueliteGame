class_name UiBridge extends RefCounted

const STATE_NAME := &"ui"

static var _namespace_owner: Dictionary = {}

## Bridge main store. Exposed to UI via UI.store(store_name) (readonly).
var store := ReactiveDictionary.new()
var store_name: String

var _attached := false
var _links: Dictionary = {}   # escopo -> Array de [Signal, Callable]
var _owned_namespaces: Array[StringName] = []

func _init(p_store_name: String) -> void:
	store_name = p_store_name


#region Life Cycle
func attach() -> void:
	if _attached:
		return
	_attached = true
	if LuaBridgeRegistry.get_lua_state(STATE_NAME) == null:
		LuaBridgeRegistry.register_state(STATE_NAME, LuaUi.state)
	LuaUi.expose_store(store_name, store, true)
	_on_attach()
	refresh()


func detach() -> void:
	if not _attached:
		return
	_attached = false
	_on_detach()
	for scope in _links.keys():
		_unlink(scope)
	for namespace_name in _owned_namespaces:
		if _namespace_owner.get(namespace_name) == self:
			_namespace_owner.erase(namespace_name)
			LuaUi.state.globals[namespace_name] = null
	_owned_namespaces.clear()


## Builds store with backend data
func refresh() -> void:
	store.assign(_build_snapshot())
#endregion


#region Extension Points
func _on_attach() -> void:
	pass


func _on_detach() -> void:
	pass


func _build_snapshot() -> Dictionary:
	return {}
#endregion


#region Internal
## Store extra, também readonly para o Lua (ex.: o relógio da run, que muda todo segundo).
func _expose_store(name: String, extra_store: ReactiveDictionary) -> void:
	LuaUi.expose_store(name, extra_store, true)


## Bridge's exclusive namespace (eg.: Game). Erases old data
func _bind_actions(namespace_name: StringName, actions: Dictionary) -> void:
	LuaUi.state.globals[namespace_name] = null
	for function_name in actions:
		LuaBridgeRegistry.lua_register(STATE_NAME, namespace_name, function_name, actions[function_name])
	_namespace_owner[namespace_name] = self
	if not _owned_namespaces.has(namespace_name):
		_owned_namespaces.append(namespace_name)


## Bridge's shared namespaces (ex.: Inventory, each container with its own bridge)
func _register_shared(namespace_name: StringName, function_name: String, callable: Callable) -> void:
	var table: Variant = LuaUi.state.globals[namespace_name]
	if not (table is Dictionary and table.has(function_name)):
		LuaBridgeRegistry.lua_register(STATE_NAME, namespace_name, function_name, callable)


## Create new connection and groups by scope
func _link(sig: Signal, callable: Callable, scope: StringName = &"bridge") -> void:
	sig.connect(callable)
	if not _links.has(scope):
		_links[scope] = []
	_links[scope].append([sig, callable])


## Erases all scope's connections
func _unlink(scope: StringName = &"bridge") -> void:
	for pair in _links.get(scope, []):
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	_links.erase(scope)
#endregion
