#CardRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"card"


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return CardDefinition.new(entry)


func create_card(id: StringName) -> Card:
	var definition := get_definition(id) as CardDefinition
	if not definition:
		return null
	return Card.new(definition)
