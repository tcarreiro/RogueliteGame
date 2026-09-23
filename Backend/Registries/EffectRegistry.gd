#RunRegistry
extends Node

const CONTEXT_NAME := &"effect"
const EFFECT_DIR := "effects"
const EFFECTS_JSON_REGISTRY := "effects.json"

var _definitions: Dictionary[StringName, EffectDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Effects
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
	var effects_json_path := metadata.folder_path.path_join("%s/%s"%[EFFECT_DIR, EFFECTS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(effects_json_path):
		return
	
	var entries := Utils.read_json_array(effects_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: EffectDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("Effect %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("Effect %s registered."%definition.id)


func get_definition(id: StringName) -> EffectDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[EffectDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_effect(effect_id: StringName) -> Effect:
	if not _definitions.has(effect_id):
		return null
	return Effect.new(_definitions.get(effect_id))


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> EffectDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[EffectRegistry] Effect with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var effect_id := StringName(entry["id"])
	if _definitions.has(effect_id):
		GameLogger.warn("[EffectRegistry] Effect '%s' already defined."%[effect_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[EffectRegistry] Script not fount for factor '%s' at '%s'"%[effect_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[EffectRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := EffectDefinition.new(entry)
	_content_bridge.register_effect_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[EffectDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[EffectDefinition] = []
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
		var def := EffectDefinition.new(entry)
		if entry.has("on_equip") and entry["on_equip"]:
			def.on_equip = Callable(self, entry["on_equip"])
		if entry.has("on_unequip") and entry["on_unequip"]:
			def.on_unequip = Callable(self, entry["on_unequip"])
		if entry.has("on_run_start") and entry["on_run_start"]:
			def.on_run_start = Callable(self, entry["on_run_start"])
		mocked_definitions.append(def)
	
	return mocked_definitions
#endregion
