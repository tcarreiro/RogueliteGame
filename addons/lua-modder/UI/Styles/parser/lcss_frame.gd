class_name LCSSFrame extends RefCounted

var offset: float
var properties: Dictionary[StringName, LCSSProperty] = {}

func _init(_offset: Variant, _properties: Dictionary[StringName, LCSSProperty] = {}) -> void:
	offset = _offset
	properties = _properties


func add_property(_property: LCSSProperty) -> void:
	properties[_property.name] = _property


func _to_string() -> String:
	return "LCSSFrame(offset=%s, properties=%s)" % [
		offset, properties.values()
	]
