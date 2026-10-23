class_name LCSSToken extends RefCounted

var start_position: int
var end_position: int
var value: String
var kind: StringName #LCSS.KIND

func _init(_kind: StringName, _start: int, _end: int, _value: String) -> void:
	kind = _kind
	start_position = _start
	end_position = _end
	value = _value


func _to_string() -> String:
	return "LCSSToken(start_position=%s, end_position=%s, value=%s, kind=%s)" % [
		start_position, end_position, value, kind
	]
