#LuaBridgeRegistry: Autoload
extends Node

var _states: Dictionary[StringName, LuaState] = {}


func register_state(state_name: StringName, state: LuaState) -> void:
	if _states.has(state_name):
		push_warning("[LuaBridgeRegistry] '%s' already registered at '%s'"%[state_name, state])
		return
	_states[state_name] = state


func lua_register(state_name: StringName, namespace_name: StringName, callable_name: StringName, callable: Callable) -> void:
	var state = get_lua_state(state_name)
	if state == null:
		push_error("[LuaBridgeRegistry] state '%s' not registered." % state_name)
		return
	
	# Checks if namespace already exists
	var namespace_table = state.globals[namespace_name]
	if namespace_table == null or not (namespace_table is LuaTable or namespace_table is Dictionary):
		namespace_table = {}
		state.globals[namespace_name] = namespace_table
	
	if namespace_table is Dictionary and namespace_table.has(callable_name):
		push_warning("[LuaBridgeRegistry] '%s' already registered at '%s.%s'"%[callable_name, state, namespace_name])
		return
	
	namespace_table[callable_name] = callable
	state.globals[namespace_name] = namespace_table


func unregister_state(state_name: StringName) -> void:
	_states.erase(state_name)


func get_lua_state(state_name: StringName) -> LuaState:
	return _states.get(state_name)


func get_all_state_names() -> Array[StringName]:
	return _states.keys()


func get_state_name_by_mod_id(mod_id: StringName, context: StringName) -> StringName:
	return StringName("state_mod_%s_%s" % [mod_id, context])
