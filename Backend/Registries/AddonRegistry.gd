#AddonRegistry
extends Node

const CONTEXT_NAME := &"addon"
const ADDON_DIR = "addons"
const ADDONS_JSON_REGISTRY = "addons.json"

var _definitions: Dictionary[StringName, AddonDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Addons
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
	var addons_json_path := metadata.folder_path.path_join("%s/%s"%[ADDON_DIR, ADDONS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(addons_json_path):
		return
	
	var entries := Utils.read_json_array(addons_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: AddonDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("Addon %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("Addon %s registered."%definition.id)


func get_definition(id: StringName) -> AddonDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[AddonDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_addon(id: StringName) -> Addon:
	var definition := get_definition(id)
	if not definition:
		return null
	return Addon.new(definition)


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> AddonDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[AddonRegistry] Addon with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var addon_id := StringName(entry["id"])
	if _definitions.has(addon_id):
		GameLogger.warn("[AddonRegistry] Addon '%s' already defined."%[addon_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[AddonRegistry] Script not fount for addon '%s' at '%s'"%[addon_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[AddonRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := AddonDefinition.new(entry)
	_content_bridge.register_addon_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[AddonDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[AddonDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"initial_addon",
			"display_name": &"Initial Addon",
			"description": "It looks like a small condensed energy.",
			"tier": 1,
			"nature_id": "NONE",
		}
	]
	
	for entry in entries:
		mocked_definitions.append(AddonDefinition.new(entry))
	
	return mocked_definitions
#endregion
