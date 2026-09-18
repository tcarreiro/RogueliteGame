#FactorRegistry
extends Node

const FACTOR_DIR = "factors"
const FACTORS_JSON_REGISTRY = "factors.json"

var _definitions: Dictionary[StringName, FactorDefinition] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

# Call it to reload Factors
func load_from_mods(active_mods: Array[StringName]) -> void:
	_mod_manager = GameManager.mod_manager
	_content_bridge = ContentBridge.new()
	
	for mod_id in active_mods:
		_load_from_mod(mod_id)


func _load_from_mod(mod_id: StringName) -> void:
	var metadata := _mod_manager.get_metadata(mod_id)
	if not metadata:
		return
	var factors_json_path := metadata.folder_path.path_join("%s/%s"%[FACTOR_DIR, FACTORS_JSON_REGISTRY])
	
	if not FileAccess.file_exists(factors_json_path):
		return
	
	var entries := JsonHelper.read_json_array(factors_json_path)
	if entries.is_empty():
		return
	
	var state := _get_or_create_mod_state(mod_id)
	
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


## Retorna o LuaState já existente do mod (compartilhado por todos os
## "moddable contents" dele — Factor, Event, RunEffect etc.), criando-o na
## primeira vez que qualquer Registry pedir por ele.
func _get_or_create_mod_state(mod_id: StringName) -> LuaState:
	var state_name := StringName("mod_%s" % mod_id)
	var existing := LuaBridgeRegistry.get_lua_state(state_name)
	if existing != null:
		return existing

	var state := LuaState.new()
	state.open_libraries()
	LuaBridgeRegistry.register_state(state_name, state)
	_content_bridge.setup(state_name, state)
	return state


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
	
	var definition := FactorDefinition.new()
	definition.id = factor_id
	definition.display_name = str(entry.get("display_name", String(factor_id)))
	definition.max_level = int(entry.get("max_level", 100))
	definition.default_level = int(entry.get("default_level", 0))
	
	var state_name := StringName("mod_%s" % mod_id)
	LuaBridgeRegistry.lua_register(state_name, "Content", "createThreshold", func(level, repeatable, callback):
		var threshold := FactorThreshold.new()
		threshold.level = int(level)
		threshold.repeatable = bool(repeatable)
		threshold.on_reached = LuaHelper.make_callable(callback)
		definition.thresholds.append(threshold)
	)
	
	var result = state.do_file(script_path)
	if result is LuaError:
		push_error("[FactorRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null

	var create_thresholds_fn = state.globals["createThresholds"]
	if create_thresholds_fn is LuaFunction:
		LuaHelper.call_by_name(state, "createThresholds", [null, String(factor_id)])

	var overflow_fn = state.globals["onOverflow"]
	if overflow_fn is LuaFunction:
		definition.on_overflow = LuaHelper.make_callable(overflow_fn)

	return definition


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[FactorDefinition]:
	if mod_id != &"base_mod":
		return []
	
	var resonance := FactorDefinition.new()
	resonance.id = &"resonance"
	resonance.display_name = &"Resonance"
	
	var surrender := FactorDefinition.new()
	surrender.id = &"surrender"
	surrender.display_name = &"Surrender"
	
	var distortion := FactorDefinition.new()
	distortion.id = &"distortion"
	distortion.display_name = &"Distortion"
	
	return [resonance, surrender, distortion]


#endregion
