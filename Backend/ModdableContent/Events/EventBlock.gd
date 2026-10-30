class_name EventBlock extends RefCounted

enum Mode {
	EVENTS, # Blocks next {amount} whole events. Regardless of events' ticks.
	VALUE, # # Blocks next {amount} ticks, whether the same or different events.
	NEXT_EVENT_VALUE # Blocks next {amount} ticks exclusively from the next event
}

var mode: Mode
var amount: int

func _init(_mode: Mode, _amount: int = 1) -> void:
	mode = _mode
	amount = _amount
