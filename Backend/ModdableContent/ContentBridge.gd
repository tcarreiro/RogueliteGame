class_name ContentBridge extends RefCounted

const CONTENT_NAMESPACE := "Content"

var _lua_state: LuaState
var _state_name: StringName
var _timers: Dictionary = {}
var _next_id: int = 0

func get_or_create_mod_state(mod_id: StringName, context: StringName) -> LuaState:
	_state_name = LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, context)
	var existing := LuaBridgeRegistry.get_lua_state(_state_name)
	if existing != null:
		return existing
	return _setup()


func _setup() -> LuaState:
	_setup_lua_state()
	_register_common_state()
	return _lua_state


func _setup_lua_state() -> void:
	_lua_state = LuaState.new()
	_lua_state.open_libraries()


func _register_common_state() -> void:
	LuaBridgeRegistry.register_state(_state_name, _lua_state)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getFactorLevel", lua_get_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getFactorMaxLevel", lua_get_factor_max_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doChangeFactorLevel", lua_do_change_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doChangeFactorMaxLevel", lua_do_change_factor_max_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doTriggerEvent", lua_do_trigger_event)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addAction", lua_add_action)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "stopAction", lua_stop_action)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "createFactorThreshold", lua_create_factor_threshold)


#region Factor
func register_factor_exclusive_states(_definition: FactorDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Event
func register_event_exclusive_states(_definition: EventDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region RunEffect
func register_run_effect_exclusive_states(_definition: RunEffectDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Equipment
func register_equipment_exclusive_states(_definition: EquipmentDefinition, __state_name: StringName) -> void:
	pass
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
func lua_get_factor_level(factor_id: StringName):
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		push_error("Factor '%s' not found"%[factor_id])
		return 0
	return factor.current_level


func lua_get_factor_max_level(factor_id: StringName):
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		push_error("Factor '%s' not found"%[factor_id])
		return 0
	return factor.max_level


func lua_do_change_factor_level(factor_id: StringName, new_level:int):
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor != null:
		factor.increase_level(new_level)
	print("%s changed to %s from lua script"%[factor_id, str(factor.current_level)])


func lua_do_change_factor_max_level(factor_id: StringName, new_level:int):
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor != null:
		factor.set_max_level(new_level)
	print("%s max level changed to %s from lua script"%[factor_id, str(factor.max_level)])


func lua_do_trigger_event(event_id: StringName, value: int = 1):
	#GameManager.run_manager.event_manager.trigger_by_id(StringName(event_id), int(value))
	print("%s trigerred from lua script with value %d"%[event_id, str(value)])
	

func lua_add_action(callback: Callable, time: int, ...args) -> int:
	_next_id += 1
	var id := _next_id
	var cb := LuaHelper.make_callable(callback)
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("[ContentBridge] SceneTree not available.")
		return -1
	
	var timer = tree.create_timer(time / 1000.0)
	timer.timeout.connect(func():
		if _timers.has(id):
			cb.callv(args)
			_timers.erase(id)
	)
	_timers[id] = timer
	return id


func lua_stop_action(action_id: int) -> void:
	_timers.erase(int(action_id))


func lua_create_factor_threshold(factor_id, level, infinite, charges, direction, callback):
	var factor: Factor = GameManager.get_factor(factor_id)
	if not factor:
		return
	var threshold := FactorThreshold.new(level, infinite, charges, direction, callback)
	factor.add_threshold(threshold)
#endregion
