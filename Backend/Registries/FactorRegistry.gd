#FactorRegistry
extends Node

const CONTEXT_NAME := &"factor"
const FACTOR_DIR = "factors"
const FACTORS_JSON_REGISTRY = "factors.json"

var _definitions: Dictionary[StringName, FactorDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload Factors
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
	var factors_json_path := metadata.folder_path.path_join("%s/%s"%[FACTOR_DIR, FACTORS_JSON_REGISTRY])
	
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


func register(definition: FactorDefinition) -> void:
	if _definitions.has(definition.id):
		push_warning("Factor %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	print("Factor %s registered."%definition.id)


func get_definition(id: StringName) -> FactorDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[FactorDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_factor(id: StringName) -> Factor:
	var definition := get_definition(id)
	if not definition:
		return null
	return Factor.new(definition)


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> FactorDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		push_error("[FactorRegistry] Factor with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var factor_id := StringName(entry["id"])
	if _definitions.has(factor_id):
		push_warning("[FactorRegistry] Factor '%s' already defined."%[factor_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		push_warning("[FactorRegistry] Script not fount for factor '%s' at '%s'"%[factor_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		push_error("[FactorRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := FactorDefinition.new(entry)
	_register_callables(definition, state, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id, CONTEXT_NAME))

	return definition


func _register_callables(definition: FactorDefinition, state: LuaState, state_name:StringName) -> void:
	_content_bridge.register_factor_exclusive_states(definition, state_name)
	
	# Two registered functions:
	# onOverflow and onCreation
	var on_creation_fn = state.globals["onCreation"]
	if on_creation_fn is LuaFunction:
		definition.on_creation = LuaHelper.make_callable(on_creation_fn)
	
	var overflow_fn = state.globals["onOverflow"]
	if overflow_fn is LuaFunction:
		definition.on_overflow = LuaHelper.make_callable(overflow_fn)

#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[FactorDefinition]:
	if mod_id != &"core":
		return []
	
	var mockes_definitions: Array[FactorDefinition] = []
	var entries : Array[Dictionary] = [
		{
			"id": &"factor_resonance",
			"display_name": &"Resonance",
		},
		{
			"id": &"factor_surrender",
			"display_name": &"Surrender",
		},
		{
			"id": &"factor_distortion",
			"display_name": &"Distortion",
		}
	]
	
	for entry in entries:
		mockes_definitions.append(FactorDefinition.new(entry))
	
	return mockes_definitions


#endregion
