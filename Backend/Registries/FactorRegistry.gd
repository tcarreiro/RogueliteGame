#FactorRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"factor"
	requires_script = true


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return FactorDefinition.new(entry)


func create_factor(id: StringName) -> Factor:
	var definition := get_definition(id) as FactorDefinition
	if not definition:
		return null
	return Factor.new(definition)
