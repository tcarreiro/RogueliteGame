class_name UiBridge extends RefCounted

signal lua_event(event_name: String, data)

const STATE_NAME = "ui_state"
const UI_NAMESPACE = "UI"
const HOST_NAMESPACE = "Host"

var _lua_state: LuaState
var _ui_manager := LuaUiManager.new()

func _init() -> void:
	_setup_lua_state()
	_register_state()

func _setup_lua_state() -> void:
	_lua_state = LuaState.new()
	_lua_state.open_libraries()


func _register_state() -> void:
	LuaBridgeRegistry.register_state(STATE_NAME, get_lua_state())
	
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "doOpen", lua_open)
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "doOpenAt", lua_open_at)
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "doClose", lua_close)
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "doCloseCurrent", lua_close_current)
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "getCurrentValue", lua_get_current_value)
	LuaBridgeRegistry.lua_register(STATE_NAME, UI_NAMESPACE, "setCurrentValue", lua_set_current_value)
	
	LuaBridgeRegistry.lua_register(STATE_NAME, HOST_NAMESPACE, "onEmit", lua_emit)


#region Getters and Setters
func get_lua_state() -> LuaState:
	return _lua_state


func get_ui_namespace_name() -> StringName:
	return UI_NAMESPACE


func get_host_namespace_name() -> StringName:
	return HOST_NAMESPACE


func get_state_name() -> StringName:
	return STATE_NAME
#endregion

#region Lua Scripts
func lua_open(raw_definition):
	return open_ui(_lua_state, raw_definition)


func lua_open_at(raw_definition, anchor):
	return open_at(_lua_state, raw_definition, anchor)


func lua_close(handle_id):
	close(handle_id)


func lua_emit(event_name, data):
	lua_event.emit(str(event_name), LuaHelper.normalize_lua(data))


func lua_close_current():
	_ui_manager.close_current(_lua_state)


func lua_get_current_value(component_id):
	return _ui_manager.get_current_value(_lua_state, component_id)


func lua_set_current_value(component_id, value):
	_ui_manager.set_current_value(_lua_state, component_id, value)

#endregion

#region GDscripts
func open_ui(state: LuaState, raw_definition) -> int:
	var definition = LuaHelper.normalize_lua(raw_definition)

	if not definition is Dictionary:
		push_error("[LuaUiBridge] UI.open espera uma tabela de definição.")
		return -1

	return _ui_manager.open(definition, state)


func open_at(state: LuaState, raw_definition, anchor_control: Control) -> int:
	var definition = LuaHelper.normalize_lua(raw_definition)

	if not definition is Dictionary:
		push_error("[LuaUiBridge] UI.open_at espera uma tabela de definição.")
		return -1

	return _ui_manager.open_at(definition, anchor_control, state)


func close(handle_id: int) -> void:
	_ui_manager.close(handle_id)

#endregion

#region Extension points
func set_translation_resolver(fn: Callable) -> void:
	_ui_manager.set_translation_resolver(fn)


func register_theme(theme_name: String, theme: Theme) -> void:
	_ui_manager.register_theme(theme_name, theme)


func register_animation(name: String, preset: LuaUiAnimationPreset) -> void:
	_ui_manager.register_animation(name, preset)


func register_sound(name: String, stream: AudioStream) -> void:
	_ui_manager.register_sound(name, stream)


func set_ui_root(root: Control) -> void:
	_ui_manager.set_ui_root(root)


func register_component(component: LuaUiComponent) -> void:
	_ui_manager.register_component(component)
#endregion
