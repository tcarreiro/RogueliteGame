class_name EventBlock extends RefCounted

enum Mode {
	EVENTS,
	VALUE,
	NEXT_EVENT_VALUE
}

var mode: Mode
var amount: int

func _init(_mode: Mode, _amount: int = 1) -> void:
	mode = _mode
	amount = _amount
