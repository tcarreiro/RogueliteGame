class_name LCSSKeyframes extends RefCounted
## Quadros de um @keyframes: offset de 0 a 1 -> propriedades.

#var frames: Array[Dictionary] = []   # { "offset": float, "properties": Dictionary }
var style_sheet: LCSSStyleSheet
var token: LCSSToken
var name: StringName
var frames: Array[LCSSFrame] = []

func _init(_style_sheet: LCSSStyleSheet, _token: LCSSToken) -> void:
	style_sheet = _style_sheet
	token = _token
	parse()


func parse() -> void:
	LCSSParser.parse_keyframes(self)


func add_frame(offset: float, properties: Dictionary[StringName, LCSSProperty]) -> void:
	var frame := LCSSFrame.new(offset, properties)
	frames.append(frame)
	frames.sort_custom(func(a: LCSSFrame, b: LCSSFrame) -> bool: return a.offset < b.offset)


func property_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for frame:LCSSFrame in frames:
		for p in frame.properties:
			if not names.has(p):
				names.append(p)
	return names


## [{ offset, value }] em ordem.
func frames_for(property: StringName) -> Array:
	var out: Array = []
	for frame:LCSSFrame in frames:
		var found_props := frame.properties.values().filter(func(prop: LCSSProperty): return prop.name == property)
		if found_props.size() > 0:
			for prop in found_props:
				out.append({"offset": frame.offset, "value": prop.value})
	return out


func _to_string() -> String:
	return "LCSSKeyframes(name=%s, frames=%s)" % [
		name, frames
	]
