#DatashardRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"datashard"


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return DatashardDefinition.new(entry)


func create_datashard(id: StringName) -> Datashard:
	var definition := get_definition(id) as DatashardDefinition
	if not definition:
		return null
	return Datashard.new(definition)
