class_name EventOccurrence extends RefCounted

# Each Event is an instance by itself, and has a value
# so we can block total values, total events or number of values of number of events
var event: Event
var value: int

func _init(_event: Event, _value: int = 1) -> void:
	event = _event
	value = _value
