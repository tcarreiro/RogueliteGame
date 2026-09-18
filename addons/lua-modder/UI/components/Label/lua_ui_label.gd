class_name LuaUiLabel extends LuaUiComponent


func get_type_name() -> String:
	return "label"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var label := Label.new()
	label.text = context.resolve_text(definition.get("text", ""))
	return label
