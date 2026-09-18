class_name LuaUiSlider extends LuaUiComponent


func get_type_name() -> String:
	return "slider"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var direction: String = definition.get("direction", "horizontal")
	var slider: Range = VSlider.new() if direction == "vertical" else HSlider.new()

	slider.min_value = float(definition.get("min", 0))
	slider.max_value = float(definition.get("max", 100))
	slider.step = float(definition.get("step", 1))
	slider.value = float(definition.get("value", slider.min_value))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if definition.has("on_value_changed"):
		var callback := LuaHelper.make_callable(definition["on_value_changed"])

		if callback.is_valid():
			slider.value_changed.connect(callback)

	return slider
