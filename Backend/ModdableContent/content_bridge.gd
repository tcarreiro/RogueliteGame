class_name ContentBridge extends RefCounted

const CONTENT_NAMESPACE := "Content"

var _lua_state: LuaState
var _state_name: StringName
var _timers: Dictionary = {}
var _next_id: int = 0

func setup(state_name) -> LuaState:
	_state_name = state_name
	_setup_lua_state()
	_register_common_state()
	return _lua_state


func _setup_lua_state() -> void:
	_lua_state = LuaState.new()
	_lua_state.open_libraries()


func _register_common_state() -> void:
	LuaBridgeRegistry.register_state(_state_name, _lua_state)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getFactorLevel", lua_get_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doChangeFactorLevel", lua_do_change_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doTriggerEvent", lua_do_trigger_event)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addAction", lua_add_action)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "stopAction", lua_stop_action)


#region Factor
func register_factor_exclusive_states(definition: FactorDefinition, state_name: StringName) -> void:
	LuaBridgeRegistry.lua_register(state_name, CONTENT_NAMESPACE, "createThreshold", _create_factor_threshold_by_lua.bind(definition))


func _create_factor_threshold_by_lua(level, repeatable, callback, owner: FactorDefinition):
	var threshold := FactorThreshold.new()
	threshold.level = int(level)
	threshold.repeatable = bool(repeatable)
	threshold.on_reached = LuaHelper.make_callable(callback)
	owner.thresholds.append(threshold)

#endregion

#region Getters and Setters
func get_lua_state() -> LuaState:
	return _lua_state


func get_content_namespace_name() -> StringName:
	return CONTENT_NAMESPACE


func get_state_name() -> StringName:
	return _state_name
#endregion

#region Lua Scripts
func lua_get_factor_level(_factor_id):
	#var factor: Factor = GameManager.factor_manager.get_factor(StringName(factor_id))
	return -1#factor.current_level if factor != null else 0


func lua_do_change_factor_level(factor_id: StringName, new_level:int):
	print("%s changed to %s from lua script"%[factor_id, str(new_level)])
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor != null:
		factor.set_level(new_level)


func lua_do_trigger_event(event_id, value = 1):
	#GameManager.run_manager.event_manager.trigger_by_id(StringName(event_id), int(value))
	print("%s trigerred from lua script with value %d"%[event_id, str(value)])
	

func lua_add_action(callback, time, ...args) -> int:
	print("New action requested from lua %s: %s"%[callback, args])
	_next_id += 1
	var id := _next_id
	var cb := LuaHelper.make_callable(callback)
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("[ContentBridge] SceneTree indisponível.")
		return -1
	
	var timer = tree.create_timer(time / 1000.0)
	timer.timeout.connect(func():
		if _timers.has(id):
			cb.callv(args)
			_timers.erase(id)
	)
	_timers[id] = timer
	return id


func lua_stop_action(action_id) -> void:
	_timers.erase(int(action_id))


#endregion
