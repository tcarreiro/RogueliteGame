class_name Event extends Resource

enum EventTrigger {
	TIMED,
	REACTIVE
}

signal triggered(event: Event, amount: int)

var id: StringName
var name: String
var event_trigger: EventTrigger
var throttle: float = 0.2
var on_trigger: Callable
var on_resolved: Callable
var on_blocked: Callable

func _init(definition: EventDefinition) -> void:
	id = definition.id
	name = definition.name
	event_trigger = definition.event_trigger
	throttle = definition.throttle
	on_resolved = definition.on_resolved
	on_blocked = definition.on_blocked
	on_trigger = definition.on_trigger


func trigger(amount: int = 1) -> void:
	GameLogger.debug("Event %s being processed."%id)
	triggered.emit(self, amount)
	if on_trigger.is_valid():
		on_trigger.call(null, id, amount)


func resolve_event(amount: int) -> void:
	if on_resolved.is_valid():
		on_resolved.call(null, id, amount)


func block_event(amount: int) -> void:
	if on_blocked.is_valid():
		on_blocked.call(null, id, amount)
