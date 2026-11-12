#EventRegistry
extends ContentRegistry

func _init() -> void:
	type_name = &"event"
	requires_script = true


func _make_definition(entry: Dictionary) -> ContentDefinition:
	return EventDefinition.new(entry)


func create_event(id: StringName) -> Event:
	var definition := get_definition(id) as EventDefinition
	if not definition:
		return null
	match definition.event_trigger:
		Event.EventTrigger.TIMED:
			return TimedEvent.new(definition)
		Event.EventTrigger.REACTIVE:
			return ReactiveEvent.new(definition)
	return null
