#EffectRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"effect"
	requires_script = true


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return EffectDefinition.new(entry)


func create_effect(id: StringName) -> Effect:
	var definition := get_definition(id) as EffectDefinition
	if not definition:
		return null
	return Effect.new(definition)
