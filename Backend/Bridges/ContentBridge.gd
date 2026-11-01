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
	_lua_state.open_libraries(LuaState.LUA_BASE | LuaState.LUA_TABLE | LuaState.LUA_STRING
	| LuaState.LUA_MATH | LuaState.LUA_UTF8 | LuaState.LUA_COROUTINE
	| LuaState.GODOT_VARIANT | LuaState.GODOT_UTILITY_FUNCTIONS | LuaState.GODOT_ENUMS)
	_lua_state.globals["dofile"] = null
	_lua_state.globals["loadfile"] = null


func _register_common_state() -> void:
	LuaBridgeRegistry.register_state(_state_name, _lua_state)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "pause", lua_pause)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "resume", lua_resume)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "isEnchantable", lua_is_enchantable)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getFactorLevel", lua_get_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getFactorMaxLevel", lua_get_factor_max_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doChangeFactorLevel", lua_do_change_factor_level)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doChangeFactorMaxLevel", lua_do_change_factor_max_level)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getMaxHandSize", lua_max_hand_size)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "getCurrentHandSize", lua_get_current_hand_size)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addCardToHand", lua_add_card_to_hand)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "hasAvailableCardsToDraw", lua_has_available_cards_to_draw)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addFactorBlock", lua_add_factor_block)
	
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addEventBlock", lua_add_event_block)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "removeEventBlock", lua_remove_block_event)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doTriggerEvent", lua_do_trigger_event)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "addAction", lua_add_action)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "stopAction", lua_stop_action)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "createFactorThreshold", lua_create_factor_threshold)
	LuaBridgeRegistry.lua_register(_state_name, CONTENT_NAMESPACE, "doCreateEffect", lua_create_effect)


#region Factor
func register_factor_exclusive_states(_definition: FactorDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Event
func register_event_exclusive_states(_definition: EventDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Equipment
func register_equipment_exclusive_states(_definition: EquipmentDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Datashard
func register_datashard_exclusive_states(_definition: DatashardDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Addon
func register_addon_exclusive_states(_definition: AddonDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Addon
func register_effect_exclusive_states(_definition: EffectDefinition, __state_name: StringName) -> void:
	pass
#endregion


#region Card
func register_card_exclusive_states(_definition: CardDefinition, __state_name: StringName) -> void:
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
func lua_pause() -> void:
	GameManager.game_state.pause()


func lua_resume() -> void:
	GameManager.game_state.resume()


func lua_is_enchantable(parent) -> bool:
	return parent is Enchantable


func lua_create_effect(_config_table) -> StringName:
	#if not GameManager.run_manager.is_run_active():
		#return &""
	#var config = LuaHelper.normalize_lua(config_table)
	#var effect_definition := EffectDefinition.new(config)
	#EffectRegistry.register(effect_definition)
	#GameManager.get_effect_manager().register_effect(EffectRegistry.create_effect(effect_definition.id))
	#return effect_definition.id
	return &""


func lua_add_effect(_effect_id):
	# TODO: a way to query uuid loot and add effects
	#if parent is Enchantable:
		#parent.add_effect(self)
	pass


func lua_get_factor_level(factor_id: StringName) -> int:
	if not GameManager.run_manager.is_run_active():
		return 0
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		GameLogger.error("Factor '%s' not found"%[factor_id])
		return 0
	return factor.current_level


func lua_get_factor_max_level(factor_id: StringName) -> int:
	if not GameManager.run_manager.is_run_active():
		return 0
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		GameLogger.error("Factor '%s' not found"%[factor_id])
		return 0
	return factor.max_level


func lua_do_change_factor_level(factor_id: StringName, new_level:int):
	if not GameManager.run_manager.is_run_active():
		return
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		GameLogger.error("Factor %s not found"%factor_id)
		return
	factor.increase_level(new_level)
	GameLogger.debug("%s changed to %s from lua script"%[factor_id, str(factor.current_level)])


func lua_do_change_factor_max_level(factor_id: StringName, new_level:int):
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		GameLogger.error("Factor %s not found"%factor_id)
		return
	factor.increase_max_level(new_level)
	GameLogger.debug("%s max level changed to %s from lua script"%[factor_id, str(factor.max_level)])


func lua_max_hand_size() -> int:
	if not GameManager.run_manager.is_run_active():
		return 0
	GameLogger.debug("querying max hand size from lua script")
	return GameManager.get_equipped_gauntlet().max_hand_deck_size


func lua_get_current_hand_size() -> int:
	if not GameManager.run_manager.is_run_active():
		return 0
	GameLogger.debug("querying current hand size from lua script")
	return GameManager.get_run_state().run_deck_manager.hand_pile.get_deck_size()


func lua_add_card_to_hand(amount: int) -> Array[UUID]:
	if not GameManager.run_manager.is_run_active():
		return []
	GameLogger.debug("adding card to hand from lua script")
	return GameManager.get_run_state().run_deck_manager.draw(amount).map(func(c: Card): return c.uuid)


func lua_has_available_cards_to_draw() -> int:
	if not GameManager.run_manager.is_run_active():
		return 0
	GameLogger.debug("querying available cards on draw pile from lua script")
	return 1 if GameManager.get_run_state().run_deck_manager.draw_pile.get_deck_size() > 0 else 0


func lua_add_factor_block(factor_id: StringName, amount:int):
	if not GameManager.run_manager.is_run_active():
		return
	var factor: Factor = GameManager.get_factor(StringName(factor_id))
	if factor == null:
		GameLogger.error("Factor %s not found"%factor_id)
		return
	factor.add_block(amount)
	GameLogger.debug("%s blocks addedd to factor %s from lua script"%[amount, factor_id])


func lua_add_event_block(event_id: StringName, mode: String, amount:int):
	if not GameManager.run_manager.is_run_active():
		return
	var event: Event = GameManager.get_event(StringName(event_id))
	if not event:
		GameLogger.warn("Event '%s' not found"%[event_id])
		return
	var block_mode := Utils.parse_string_into_enum(EventBlock.Mode, mode, "") as EventBlock.Mode
	var event_block := EventBlock.new(block_mode, amount)
	GameManager.get_event_manager().add_block(event_id, event_block)
	GameLogger.debug("%s event blocks of mode %s added to %s from lua script"%[event_block.amount, EventBlock.Mode.keys()[block_mode], event_id])


func lua_remove_block_event(event_id: StringName, mode: String, amount:int):
	if not GameManager.run_manager.is_run_active():
		return
	var event: Event = GameManager.get_event(StringName(event_id))
	if not event:
		GameLogger.warn("Event '%s' not found"%[event_id])
		return
	var block_mode := Utils.parse_string_into_enum(EventBlock.Mode, mode, "") as EventBlock.Mode
	var event_block := EventBlock.new(block_mode, amount)
	GameManager.get_event_manager().remove_block(event_id, event_block)
	GameLogger.debug("%s event blocks of mode %s added to %s from lua script"%[event_block.amount, EventBlock.Mode.keys()[block_mode], event_id])


func lua_do_trigger_event(event_id: StringName, value: int = 1):
	if not GameManager.run_manager.is_run_active():
		return
	GameManager.get_event_manager().get_event(event_id).trigger(value)
	GameLogger.debug("%s trigerred from lua script with value %s"%[event_id, str(value)])
	

func lua_add_action(callback, time, ...args) -> int:
	_next_id += 1
	var id := _next_id
	var cb := LuaHelper.make_callable(callback)
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		GameLogger.error("[ContentBridge] SceneTree not available.")
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


func lua_clear_pending_actions() -> void:
	_timers.clear()


func lua_create_factor_threshold(factor_id, level, infinite, charges, direction, callback):
	var factor: Factor = GameManager.get_factor(factor_id)
	if not factor:
		return
	var threshold := FactorThreshold.new(level, infinite, charges, direction, callback)
	factor.add_threshold(threshold)
#endregion
