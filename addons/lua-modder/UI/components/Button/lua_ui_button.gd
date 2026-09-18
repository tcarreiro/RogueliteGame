class_name LuaUiButton extends LuaUiComponent

func get_type_name() -> String:
	return "button"

func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var button := Button.new()
	button.text = context.resolve_text(definition.get("text", ""))

	if definition.has("icon"):
		var texture := load(definition["icon"]) as Texture2D
		if texture != null:
			button.icon = texture
		else:
			push_warning("[LuaUiButton] Ícone não encontrado: %s" % definition["icon"])

	var text_position: String = definition.get("text_position", "center")
	match text_position:
		"left":
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		"right":
			button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"center":
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		"fill":
			button.alignment = HORIZONTAL_ALIGNMENT_FILL

	var icon_position: String = definition.get("icon_position", "left")
	match icon_position:
		"left":
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		"right":
			button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"center":
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		"fill":
			button.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	var vertical_icon_position: String = definition.get("vertical_icon_position", "center")
	match vertical_icon_position:
		"top":
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		"bottom":
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
		"center":
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		"fill":
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_FILL

	if definition.get("expand_icon", false):
		button.expand_icon = true

	if definition.has("on_click"):
		var callback := LuaHelper.make_callable(definition["on_click"])
		if callback.is_valid():
			button.pressed.connect(callback)

	return button
