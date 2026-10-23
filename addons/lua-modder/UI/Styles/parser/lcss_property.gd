class_name LCSSProperty extends RefCounted

var name: StringName
var value: Variant

func _init(_name: StringName, _value: Variant) -> void:
	name = _name
	value = _value


func _to_string() -> String:
	return "LCSSProperty(name=%s, value=%s)" % [name, value]
