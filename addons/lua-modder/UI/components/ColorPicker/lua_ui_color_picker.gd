class_name LuaUiColorPicker extends LuaUiComponent

func get_type_name() -> String:
	return "colorpicker"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var picker := ColorPicker.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color = LuaHelper.parse_color(definition.get("value", "#ffffff"))

	picker.edit_alpha = definition.get("edit_alpha", true)
	picker.can_add_swatches = definition.get("can_add_swatches", true)
	picker.sampler_visible = definition.get("sampler_visible", true)
	picker.sliders_visible = definition.get("sliders_visible", true)
	picker.hex_visible = definition.get("hex_visible", true)
	picker.presets_visible = definition.get("presets_visible", true)

	if definition.has("color_mode"):
		match str(definition["color_mode"]):
			"rgb": picker.color_mode = ColorPicker.MODE_RGB
			"hsv": picker.color_mode = ColorPicker.MODE_HSV
			"raw": picker.color_mode = ColorPicker.MODE_RAW
			"okhsl": picker.color_mode = ColorPicker.MODE_OKHSL

	if definition.has("on_value_changed"):
		var callback := LuaHelper.make_callable(definition["on_value_changed"])
		if callback.is_valid():
			picker.color_changed.connect(callback)

	return picker
