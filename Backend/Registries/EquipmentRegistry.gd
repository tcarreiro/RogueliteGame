#EquipmentRegistry
extends Node

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
	var factors_json_path := metadata.folder_path.path_join("%s/%s"%[EQUIPMENT_DIR, EQUIPMENTS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(factors_json_path):
		return
	
	var entries := Utils.read_json_array(factors_json_path)
	if entries.is_empty():
		return
	
	var state := _content_bridge.get_or_create_mod_state(mod_id)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)


func register(definition: EquipmentDefinition) -> void:
	if _definitions.has(definition.id):
		push_warning("Equipment %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	print("Equipment %s registered."%definition.id)


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
		Equipment.EQUIPMENT_TYPE.GAUNTLET:
			return Gauntlet.new(definition)
	return null


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> EquipmentDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		push_error("[EquipmentRegistry] Equipment with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var factor_id := StringName(entry["id"])
	if _definitions.has(factor_id):
		push_warning("[EquipmentRegistry] Equipment '%s' already defined."%[factor_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		push_warning("[EquipmentRegistry] Script not fount for factor '%s' at '%s'"%[factor_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		push_error("[EquipmentRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := _create_definition_from_raw(entry)
	_register_factor_exclusive_contract(definition, state, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id))

	return definition


func _create_definition_from_raw(entry) -> EquipmentDefinition:
	var definition := EquipmentDefinition.new()
	definition.id = StringName(entry["id"])
	definition.display_name = str(entry.get("display_name", definition.id))
	definition.description = str(entry.get("description", definition.id))
	definition.tier = int(entry.get("tier", 1))
	definition.nature_id = str(entry.get("nature_id", definition.id))
	definition.cost = float(entry.get("cost", 0.0))
	definition.socket_slots = int(entry.get("socket_slots", 0))
	definition.type = Utils.parse_string_into_enum(
		Equipment.EQUIPMENT_TYPE, str(entry.get("type", "GAUNTLET")), "[EquipmentDefinition - type]") as Equipment.EQUIPMENT_TYPE
	# TBD TODO: get initial addons and effects from script? 
	#var addons: Dictionary[int, Addon] = {} # slot_id
	#var effects: Dictionary[StringName, RunEffect] = {}
	definition.max_active_deck_size = int(entry.get("max_active_deck_size", 10))
	
	return definition


func _register_factor_exclusive_contract(definition: EquipmentDefinition, state: LuaState, state_name:StringName) -> void:
	_content_bridge.register_equipment_exclusive_states(definition, state_name)
	
	# Two registered functions:
	# setupAddons and setupEffects
	var setup_addons_fn = state.globals["setupAddons"]
	if setup_addons_fn is LuaFunction:
		# Immediatly calls setupAddons, so each threshold's callable is registered at definition
		LuaHelper.call_by_name(state, "setupAddons", [null, String(definition.id)])
	
	var setup_effects_fn = state.globals["setupEffects"]
	if setup_effects_fn is LuaFunction:
		# Immediatly calls setupEffects, so each threshold's callable is registered at definition
		LuaHelper.call_by_name(state, "setupEffects", [null, String(definition.id)])

	#var overflow_fn = state.globals["onOverflow"]
	#if overflow_fn is LuaFunction:
		#definition.on_overflow = LuaHelper.make_callable(overflow_fn)

#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[EquipmentDefinition]:
	if mod_id != &"core":
		return []
	
	var gauntlet := EquipmentDefinition.new()
	gauntlet.id = &"gauntlet"
	gauntlet.display_name = &"Gauntlet"
	gauntlet.description = "A magical gauntlet"
	gauntlet.tier = 1
	gauntlet.nature_id = "NONE"
	gauntlet.cost = 0.0
	gauntlet.socket_slots = 0
	gauntlet.type = Equipment.EQUIPMENT_TYPE.GAUNTLET
	gauntlet.max_active_deck_size = 10
	
	return [gauntlet]


#endregion
