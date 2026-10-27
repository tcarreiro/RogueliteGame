#EquipmentRegistry
extends Node

const CONTEXT_NAME := &"equipment"
const EQUIPMENT_DIR = "equipments"
const EQUIPMENTS_JSON_REGISTRY = "equipments.json"

var _definitions: Dictionary[StringName, EquipmentDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Equipments
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
	var equipments_json_path := metadata.folder_path.path_join("%s/%s"%[EQUIPMENT_DIR, EQUIPMENTS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(equipments_json_path):
		return
	
	var entries := Utils.read_json_array(equipments_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id, CONTEXT_NAME)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: EquipmentDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("Equipment %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	GameLogger.debug("Equipment %s registered."%definition.id)


func get_definition(id: StringName) -> EquipmentDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[EquipmentDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_equipment(id: StringName) -> Equipment:
	var definition := get_definition(id)
	if not definition:
		return null
	match definition.type:
		Equipment.EquipmentType.GAUNTLET:
			return Gauntlet.new(definition)
	return null


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> EquipmentDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		GameLogger.error("[EquipmentRegistry] Equipment with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var equipment_id := StringName(entry["id"])
	if _definitions.has(equipment_id):
		GameLogger.warn("[EquipmentRegistry] Equipment '%s' already defined."%[equipment_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[EquipmentRegistry] Script not fount for equipment '%s' at '%s'"%[equipment_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		GameLogger.error("[EquipmentRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := EquipmentDefinition.new(entry)
	_content_bridge.register_equipment_exclusive_states(definition, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))
	definition.connect_callables(state)
	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[EquipmentDefinition]:
	if mod_id != &"core":
		return []
	
	var mocked_definitions: Array[EquipmentDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"gauntlet",
			"display_name": &"Gauntlet",
			"description": "A magical gauntlet",
			"tier": 1,
			"nature_id": "NONE",
			"cost": 0.0,
			"socket_slots": 0,
			"type": "GAUNTLET",
			"max_active_deck_size": 10,
		}
	]
	
	for entry in entries:
		mocked_definitions.append(EquipmentDefinition.new(entry))
	
	return mocked_definitions
#endregion
