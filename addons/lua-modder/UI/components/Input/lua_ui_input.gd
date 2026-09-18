class_name LuaUiInput extends LuaUiComponent


func get_type_name() -> String:
	return "input"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var input := LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if definition.has("value"):
		input.text = str(definition["value"])

	if definition.has("placeholder"):
		input.placeholder_text = context.resolve_text(definition["placeholder"])

	if definition.has("max_length"):
		input.max_length = int(definition["max_length"])

	if definition.get("secret", false):
		input.secret = true

	if definition.has("on_value_changed"):
		var callback := LuaHelper.make_callable(definition["on_value_changed"])

		if callback.is_valid():
			input.text_changed.connect(callback)

	if definition.has("on_submit"):
		var callback := LuaHelper.make_callable(definition["on_submit"])

		if callback.is_valid():
			input.text_submitted.connect(callback)

	return input
