#AddonRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"addon"


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return AddonDefinition.new(entry)


func create_addon(id: StringName) -> Addon:
	var definition := get_definition(id) as AddonDefinition
	if not definition:
		return null
	return Addon.new(definition)
