class_name EventDefinition extends Resource

@export var id: StringName
@export var name: String
@export var event_trigger: Event.EventTrigger
@export var throttle: float = 5.0
@export var on_resolved: Callable
@export var on_blocked: Callable

@export_category("Timed")
@export var interval: float = 5.0

@export_category("Reactive")
@export var watched_event_id: StringName
@export var conditional: Callable

func parse_event_trigger(raw: String, event_id: StringName) -> Event.EventTrigger:
	match raw.to_upper():
		"TIMED":
			return Event.EventTrigger.TIMED
		"REACTIVE":
			return Event.EventTrigger.REACTIVE
		_:
			push_error("[EventRegistry] event_trigger inválido '%s' para evento '%s'. Usando TIMED como padrão." % [raw, event_id])
			return Event.EventTrigger.TIMED
