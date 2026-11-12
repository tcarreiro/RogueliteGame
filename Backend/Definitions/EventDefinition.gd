class_name EventDefinition extends ContentDefinition

@export var name: String
@export var event_trigger: Event.EventTrigger
@export var throttle: float = 0.2
var on_resolved: Callable
var on_blocked: Callable
var on_trigger: Callable

@export_category("Timed")
@export var interval: float = 5.0

@export_category("Reactive")
@export var watched_event_id: StringName
var conditional: Callable


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


func connect_callables(hooks: LuaTable) -> void:
	on_resolved = LuaHelper.make_callable(hooks.rawget("onResolvedEvent"))
	on_blocked = LuaHelper.make_callable(hooks.rawget("onBlockedEvent"))
	on_trigger = LuaHelper.make_callable(hooks.rawget("onTrigger"))
	conditional = LuaHelper.make_callable(hooks.rawget("onWatchedEventTrigger"))
