#RunRegistry
extends Node

const CONTEXT_NAME := &"run_effect"
const RUN_EFFECT_DIR := "runEffects"
const RUN_EFFECTS_JSON_REGISTRY := "runEffects.json"

var _definitions: Dictionary[StringName, RunEffectDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload RunEffects
func load_from_mods(active_mods: Array[StringName]) -> void:
	_mod_manager = GameManager.mod_manager
	_content_bridge = GameManager.content_bridge
	_definitions = {}
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
	var run_effects_json_path := metadata.folder_path.path_join("%s/%s"%[RUN_EFFECT_DIR, RUN_EFFECTS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(run_effects_json_path):
		return
	
	var entries := Utils.read_json_array(run_effects_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: RunEffectDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("RunEffect %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("RunEffect %s registered."%definition.id)


func get_definition(id: StringName) -> RunEffectDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[RunEffectDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_run_effect(effect_id: StringName) -> RunEffect:
	if not _definitions.has(effect_id):
		return null
	return RunEffect.new(_definitions.get(effect_id))


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> RunEffectDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[RunEffectRegistry] RunEffect with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var run_effect_id := StringName(entry["id"])
	if _definitions.has(run_effect_id):
		GameLogger.warn("[RunEffectRegistry] RunEffect '%s' already defined."%[run_effect_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[RunEffectRegistry] Script not fount for factor '%s' at '%s'"%[run_effect_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[RunEffectRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := RunEffectDefinition.new(entry)
	_content_bridge.register_run_effect_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[RunEffectDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[RunEffectDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"echo_addon_effect",
			"display_name": &"Echo Addon",
			"description": "Increase max Resonance level by 20",
			"unique": true,
			"category": "BUFF"
		}
	]
	
	for entry in entries:
		var def := RunEffectDefinition.new(entry)
		if entry.has("on_equip") and entry["on_equip"]:
			def.on_equip = Callable(self, entry["on_equip"])
		if entry.has("on_unequip") and entry["on_unequip"]:
			def.on_unequip = Callable(self, entry["on_unequip"])
		if entry.has("on_run_start") and entry["on_run_start"]:
			def.on_run_start = Callable(self, entry["on_run_start"])
		mocked_definitions.append(def)
	
	return mocked_definitions
#endregion
