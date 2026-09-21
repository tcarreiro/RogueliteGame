#EventRegistry
extends Node

const CONTEXT_NAME := &"event"
const EVENT_DIR = "events"
const EVENTS_JSON_REGISTRY = "events.json"

var _definitions: Dictionary[StringName, EventDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Events
func load_from_mods(active_mods: Array[StringName]) -> void:
	_mod_manager = GameManager.mod_manager
	_content_bridge = GameManager.content_bridge
	for mod_id in active_mods:
		_load_from_mod(mod_id)


func _load_from_mod(mod_id: StringName) -> void:
	if _is_mocked:
		for definition in _mock_definitions_for(mod_id):
			register(definition)
		return
	
	var metadata := _mod_manager.get_metadata(mod_id)
	if not metadata:
		return
	var events_json_path := metadata.folder_path.path_join("%s/%s"%[EVENT_DIR, EVENTS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(events_json_path):
		return
	
	var entries := Utils.read_json_array(events_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: EventDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("Event %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("Event %s registered."%definition.id)


func get_definition(id: StringName) -> EventDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[EventDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_event(id: StringName) -> Event:
	var definition := get_definition(id)
	if not definition:
		return null
	match definition.event_trigger:
		Event.EventTrigger.TIMED:
			return TimedEvent.new(definition)
		Event.EventTrigger.REACTIVE:
			return ReactiveEvent.new(definition)
	return null


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> EventDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[EventRegistry] Event with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var event_id := StringName(entry["id"])
	if _definitions.has(event_id):
		GameLogger.warn("[EventRegistry] Event '%s' already defined."%[event_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[EventRegistry] Script not fount for factor '%s' at '%s'"%[event_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[EventRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := EventDefinition.new(entry)
	_content_bridge.register_event_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[EventDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[EventDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"resonance_event",
			"name": &"Resonance Event",
			"event_trigger": "TIMED",
			"interval": 30.0,
			"throttle": 5.0
		},
		{
			"id": &"surrender_event",
			"name": &"Surrender Event",
			"event_trigger": "REACTIVE",
			"conditional": "_stumble_conditional_mock",
			"throttle": 0.2
		},
		{
			"id": &"distortion_event",
			"name": &"Distortion Event",
			"event_trigger": "TIMED",
			"interval": 40.0,
			"throttle": 5.0
		},
		{
			"id": &"card_draw_event",
			"name": &"Card Draw Event",
			"event_trigger": "TIMED",
			"interval": 30.0,
			"throttle": 0.3
		},
		{
			"id": &"stumble_event",
			"name": &"Stumble Event",
			"event_trigger": "REACTIVE",
			"watched_event_id": &"card_draw_event",
			"conditional": "_stumble_conditional_mock",
			"on_resolved": "_stumble_result_mock",
			"throttle": 0.2
		}
	]
	
	for entry in entries:
		var def := EventDefinition.new(entry)
		if entry.has("conditional") and entry["conditional"]:
			def.conditional = Callable(self, entry["conditional"])
		if entry.has("on_resolved") and entry["on_resolved"]:
			def.on_resolved = Callable(self, entry["on_resolved"])
		if entry.has("on_blocked") and entry["on_blocked"]:
			def.on_blocked = Callable(self, entry["on_blocked"])
		mocked_definitions.append(def)
	
	return mocked_definitions


func _stumble_conditional_mock(_resolved_event_id: StringName, _value: int) -> bool:
	if randf() < .5:
		return true
	return false


func _stumble_result_mock(_player, _event_id, _amount) -> void:
	_content_bridge.lua_do_change_factor_level("factor_resonance", 2)
	_content_bridge.lua_do_change_factor_level("factor_distortion", 1)
#endregion
