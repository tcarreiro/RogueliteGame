#RunRegistry
extends Node

const RUN_EFFECT_DIR = "runEffects"
const RUN_EFFECTS_JSON_REGISTRY = "runEffects.json"

var _definitions: Dictionary[StringName, RunEffectDefinition] = {}
var _run_effects: Dictionary[StringName, RunEffect] = {}
var _content_bridge: ContentBridge
var _mod_manager: ModManager

var _is_mocked: bool = false

# Call it to reload RunEffects
func load_from_mods(active_mods: Array[StringName]) -> void:
	_mod_manager = GameManager.mod_manager
	_content_bridge = GameManager.content_bridge
	_definitions = {}
	_run_effects = {}
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
	
	var state := _content_bridge.get_or_create_mod_state(mod_id)
	
	for entry in entries:
		var definition := _load_definition_from_entry(entry, metadata.folder_path, mod_id, state)
		if definition != null:
			register(definition)
			create_run_effect(definition)


func register(definition: RunEffectDefinition) -> void:
	if _definitions.has(definition.id):
		push_warning("RunEffect %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	print("RunEffect %s registered."%definition.id)


func get_definition(id: StringName) -> RunEffectDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[RunEffectDefinition]:
	return _definitions.values()


func get_run_effects(id: StringName) -> RunEffect:
	return _run_effects.get(id)


func get_all_run_effects() -> Array[RunEffect]:
	return _run_effects.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_run_effect(definition: RunEffectDefinition) -> RunEffect:
	_run_effects[definition.id] = RunEffect.new(definition)
	return _run_effects[definition.id]


func _load_definition_from_entry(entry: Dictionary, mod_base_path: String, mod_id: StringName, state: LuaState) -> RunEffectDefinition:
	if not entry.has("id") or not entry.has("script_path"):
		push_error("[RunEffectRegistry] RunEffect with no 'id' or 'script_path' at '%s'"%[mod_id])
		return null
	
	var run_effect_id := StringName(entry["id"])
	if _definitions.has(run_effect_id):
		push_warning("[RunEffectRegistry] RunEffect '%s' already defined."%[run_effect_id])
		return null
	
	var script_path := mod_base_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		push_warning("[RunEffectRegistry] Script not fount for factor '%s' at '%s'"%[run_effect_id, script_path])
		return null
	
	var result = state.do_file(script_path)
	if result is LuaError:
		push_error("[RunEffectRegistry] Erro ao carregar '%s': %s" % [script_path, result])
		return null
		
	var definition := _create_definition_from_raw(entry)
	_register_run_effect_exclusive_contract(definition, state, LuaBridgeRegistry.get_state_name_by_mod_id(mod_id))

	return definition


func _create_definition_from_raw(entry) -> RunEffectDefinition:
	var definition := RunEffectDefinition.new()
	definition.id = StringName(entry["id"])
	definition.display_name = str(entry.get("display_name", definition.id))
	definition.description = str(entry.get("description", definition.id))
	definition.unique = bool(entry.get("unique", false))
	#definition.stack_mode = Utils.parse_string_into_enum(
		#RunEffect.RunEffectStackMode, str(entry.get("stack_mode", "UNIQUE")), "[RunEffectDefinition - stack_mode]") as RunEffect.RunEffectStackMode
	definition.category = Utils.parse_string_into_enum(
		RunEffect.RunEffectCategory, str(entry.get("category", "BUFF")), "[RunEffectDefinition - category]") as RunEffect.RunEffectCategory
	return definition


func _register_run_effect_exclusive_contract(definition: RunEffectDefinition, state: LuaState, state_name:StringName) -> void:
	_content_bridge.register_run_effect_exclusive_states(definition, state_name)
	
	# Three registered functions:
	# onEquip, onUnequip and onEffectTrigger
	var on_equip_fn = state.globals["onEquip"]
	if on_equip_fn is LuaFunction:
		definition.on_equip = LuaHelper.make_callable(on_equip_fn)

	var on_unequip_fn = state.globals["onUnequip"]
	if on_unequip_fn is LuaFunction:
		definition.on_unequip = LuaHelper.make_callable(on_unequip_fn)

	var on_effect_trigger_fn = state.globals["onEffectTrigger"]
	if on_effect_trigger_fn is LuaFunction:
		definition.on_effect_triggered = LuaHelper.make_callable(on_effect_trigger_fn)


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[RunEffectDefinition]:
	if mod_id != &"core":
		return []
	
	var echo_addon := RunEffectDefinition.new()
	echo_addon.id = &"echo_addon_effect"
	echo_addon.display_name = &"Echo Addon"
	echo_addon.description = "Increase max Resonance level by 20"
	#echo_addon.stack_mode = RunEffect.RunEffectStackMode.UNIQUE
	echo_addon.unique = true
	echo_addon.category = RunEffect.RunEffectCategory.BUFF
	
	return [echo_addon]
#endregion
