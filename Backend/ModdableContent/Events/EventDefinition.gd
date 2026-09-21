class_name EventDefinition extends Resource

@export var id: StringName
@export var name: String
@export var event_trigger: Event.EventTrigger
@export var throttle: float = 0.2
@export var on_resolved: Callable
@export var on_blocked: Callable
@export var on_trigger: Callable

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
	throttle = float(entry.get("throttle", 0.2))
	watched_event_id = StringName(entry.get("watched_event_id", ""))


func connect_callables(state: LuaState) -> void:
	on_resolved = LuaHelper.make_callable(state.globals["onResolvedEvent"])
	on_blocked = LuaHelper.make_callable(state.globals["onBlockedEvent"])
	on_trigger = LuaHelper.make_callable(state.globals["onTrigger"])
	conditional = LuaHelper.make_callable(state.globals["onWatchedEventTrigger"])
