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
