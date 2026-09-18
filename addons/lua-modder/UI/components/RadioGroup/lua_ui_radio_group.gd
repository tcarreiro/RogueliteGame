class_name LuaUiRadioGroup extends LuaUiComponent

func get_type_name() -> String:
	return "radio_group"

func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var direction: String = definition.get("direction", "vertical")
	var container: Container = HBoxContainer.new() if direction == "horizontal" else VBoxContainer.new()

	if definition.has("gap"):
		container.add_theme_constant_override("separation", int(definition["gap"]))

	var group := ButtonGroup.new()
	var options: Array = definition.get("options", [])
	var selected_value = definition.get("value", null)
	var on_change := LuaHelper.make_callable(definition.get("on_change", Callable()))
	var option_style = definition.get("option_style", null)  # estilo compartilhado por todas as opções

	for option in options:
		var button := CheckBox.new()
		button.text = context.resolve_text(option.get("text", ""))
		if option.has("icon"):
			var icon_tex := load(option["icon"]) as Texture2D
			if icon_tex != null:
				button.icon = icon_tex
		button.button_group = group
		var option_value = option.get("value")
		button.button_pressed = option_value == selected_value
		button.toggled.connect(func(pressed: bool):
			if pressed and on_change.is_valid():
				on_change.call(option_value)
		)
		if option.has("height"):
			button.custom_minimum_size.y = float(option.get("height"))
		if option.has("width"):
			button.custom_minimum_size.x = float(option.get("width"))

		var style_to_apply = option.get("style", option_style)
		if style_to_apply != null:
			GDSSUiBridge._set_gdss_classes_on_node(button, [StringName(str(style_to_apply))])

		container.add_child(button)

	return container
