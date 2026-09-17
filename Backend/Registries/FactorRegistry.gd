#FactorRegistry
extends Node

var _definitions: Dictionary[StringName, FactorDefinition] = {}

func load_from_mods(active_mods: Array[StringName]) -> void:
	for mod_id in active_mods:
		_load_from_mod(mod_id)


func _load_from_mod(mod_id: StringName) -> void:
	# TODO: get from ModManager
	#var metadata := ModManager.get_metadata(mod_id)
	#if not metadata:
		#return
	#var factor_path := metadata.folder_path.path_join("factor")
	# TODO real: DirAccess.open(factor_path), listar *.lua, parsear cada um
	# chamando register() por resultado.
	for definition in _mock_definitions_for(mod_id):
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
