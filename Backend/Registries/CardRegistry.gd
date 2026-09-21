#CardRegistry
extends Node

const CONTEXT_NAME := &"card"
const CARD_DIR = "cards"
const CARDS_JSON_REGISTRY = "cards.json"

var _definitions: Dictionary[StringName, CardDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Cards
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
	var factors_json_path := metadata.folder_path.path_join("%s/%s"%[CARD_DIR, CARDS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(factors_json_path):
		return
	
	var entries := Utils.read_json_array(factors_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: CardDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("Card %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("Card %s registered."%definition.id)


func get_definition(id: StringName) -> CardDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[CardDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_card(id: StringName) -> Card:
	var definition := get_definition(id)
	if not definition:
		return null
	return Card.new(definition)


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> CardDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[CardRegistry] Card with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var factor_id := StringName(entry["id"])
	if _definitions.has(factor_id):
		GameLogger.warn("[CardRegistry] Card '%s' already defined."%[factor_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[CardRegistry] Script not fount for factor '%s' at '%s'"%[factor_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[CardRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := CardDefinition.new(entry)
	_content_bridge.register_card_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[CardDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[CardDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"initial_card",
			"display_name": &"Initial Card",
			"description": "It looks like a small condensed energy.",
			"tier": 1,
			"nature_id": "NONE",
		}
	]
	
	for entry in entries:
		mocked_definitions.append(CardDefinition.new(entry))
	
	return mocked_definitions
#endregion
