class_name LuaUiCheckbox extends LuaUiComponent


func get_type_name() -> String:
	return "checkbox"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var box := CheckBox.new()
	box.text = context.resolve_text(definition.get("text", ""))
	box.button_pressed = definition.get("checked", false)

	if definition.has("on_toggled"):
		var callback := LuaHelper.make_callable(definition["on_toggled"])

		if callback.is_valid():
			box.toggled.connect(callback)

	return box
