class_name ContentBridge extends RefCounted

signal lua_event(event_name: String, data)

const STATE_NAME = "content_state"
const CONTENT_NAMESPACE := "Content"

var _lua_state: LuaState
var _timers: Dictionary = {}
var _next_id: int = 0

func _init() -> void:
	_setup_lua_state()
	_register_state()


func _setup_lua_state() -> void:
	_lua_state = LuaState.new()
	_lua_state.open_libraries()


func _register_state() -> void:
	LuaBridgeRegistry.register_state(STATE_NAME, get_lua_state())
	
	LuaBridgeRegistry.lua_register(STATE_NAME, CONTENT_NAMESPACE, "getFactorLevel", lua_get_factor_level)
	LuaBridgeRegistry.lua_register(STATE_NAME, CONTENT_NAMESPACE, "doChangeFactorLevel", lua_do_change_factor_level)
	LuaBridgeRegistry.lua_register(STATE_NAME, CONTENT_NAMESPACE, "doTriggerEvent", lua_do_trigger_event)
	register_action(STATE_NAME, CONTENT_NAMESPACE)


func register_action(state_name: StringName, namespace_name: StringName) -> void:
	LuaBridgeRegistry.lua_register(state_name, namespace_name, "addAction", lua_add_action)
	LuaBridgeRegistry.lua_register(state_name, namespace_name, "stopAction", lua_stop_action)


#region Getters and Setters
func get_lua_state() -> LuaState:
	return _lua_state


func get_content_namespace_name() -> StringName:
	return CONTENT_NAMESPACE


func get_state_name() -> StringName:
	return STATE_NAME
#endregion

#region Lua Scripts
func lua_get_factor_level(factor_id):
	#var factor: Factor = GameManager.factor_manager.get_factor(StringName(factor_id))
	return -1#factor.current_level if factor != null else 0


func lua_do_change_factor_level(factor_id, new_level):
	#var factor: Factor = GameManager.factor_manager.get_factor(StringName(factor_id))
	#if factor != null:
		#factor.current_level = int(new_level)
	print("%s changed to %s from lua script"%[factor_id, str(new_level)])


func lua_do_trigger_event(event_id, value = 1):
	#GameManager.run_manager.event_manager.trigger_by_id(StringName(event_id), int(value))
	print("%s trigerred from lua script with value %d"%[event_id, str(value)])
	

func lua_add_action(callback, time, ...args) -> int:
	_next_id += 1
	var id := _next_id
	var cb := LuaHelper.make_callable(callback)
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("[ContentBridge] SceneTree indisponível.")
		return -1
	
	var timer = Engine.get_main_loop().create_timer(time / 1000.0)
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
