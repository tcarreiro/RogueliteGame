class_name Event extends RefCounted

enum EventTrigger {
	TIMED,
	REACTIVE
}

signal triggered(event: Event, value: int)

var id: StringName
var name: String
var event_trigger: EventTrigger
var throttle: float = 5.0

func _init(definition: EventDefinition) -> void:
	id = definition.id
	name = definition.name
	event_trigger = definition.event_trigger
	throttle = definition.throttle


func trigger(value: int = 1) -> void:
	print("Event %s processed."%id)
	triggered.emit(self, value)
