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


func _init(entry: Dictionary):
	id = StringName(entry["id"])
	name = str(entry.get("name", id))
	event_trigger = Utils.parse_string_into_enum(
		Event.EventTrigger, 
		str(entry.get("event_trigger", "TIMED")), 
		"[EventDefinition - event_trigger]") as Event.EventTrigger
	interval = float(entry.get("interval", 30.0))
	throttle = float(entry.get("throttle", 5.0))
	watched_event_id = StringName(entry.get("watched_event_id", ""))
