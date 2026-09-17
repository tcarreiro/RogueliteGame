#RunRegistry
extends Node

var _definitions: Dictionary[StringName, RunEffect] = {}

func load_from_mods(active_mods: Array[StringName]) -> void:
	for mod_id in active_mods:
		_load_from_mod(mod_id)


func _load_from_mod(mod_id: StringName) -> void:
	# TODO: get from ModManager
	#var metadata := ModManager.get_metadata(mod_id)
	#if not metadata:
		#return
	#var run_effects_path := metadata.folder_path.path_join("run_effects")
	# TODO real: DirAccess.open(run_effects_path), listar *.lua, parsear cada um
	# em um RunEffect + suas RunEffectAction, chamando register() por resultado.
	for definition in _mock_definitions_for(mod_id):
		register(definition)


func register(definition: RunEffect) -> void:
	if _definitions.has(definition.id):
		push_warning("RunEffect %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	print("RunEffect %s registered."%definition.id)


func get_definition(id: StringName) -> RunEffect:
	return _definitions.get(id)


func get_all_definitions() -> Array[RunEffect]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[RunEffect]:
	if mod_id != &"base_mod":
		return []
	
	var echo_addon := RunEffect.new()
	echo_addon.id = &"echo_addon_effect"
	echo_addon.display_name = &"Echo Addon"
	echo_addon.description = "Increase max Resonance level by 20"
	echo_addon.stack_mode = RunEffect.RunEffectStackMode.UNIQUE
	
	return [echo_addon]


#endregion
