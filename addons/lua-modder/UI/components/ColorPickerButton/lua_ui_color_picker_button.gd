class_name LuaUiColorPickerButton extends LuaUiComponent

func get_type_name() -> String:
	return "colorpicker_button"


func build(definition: Dictionary, _context: LuaUiBuildContext) -> Control:
	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color = LuaHelper.parse_color(definition.get("value", "#ffffff"))

	if definition.has("on_value_changed"):
		var callback := LuaHelper.make_callable(definition["on_value_changed"])
		if callback.is_valid():
			picker.color_changed.connect(callback)

	return picker
