#EquipmentRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"equipment"


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return EquipmentDefinition.new(entry)


func create_equipment(id: StringName) -> Equipment:
	var definition := get_definition(id) as EquipmentDefinition
	if not definition:
		return null
	match definition.kind:
		Gauntlet.KIND_GAUNTLET:
			return Gauntlet.new(definition)
	return null
