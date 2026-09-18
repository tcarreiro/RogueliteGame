class_name LuaUiScroll extends LuaUiComponent


func get_type_name() -> String:
	return "scroll"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var direction: String = definition.get("direction", "vertical")

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if direction == "vertical" else ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if direction == "horizontal" else ScrollContainer.SCROLL_MODE_AUTO

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for raw_child in definition.get("children", []):
		inner.add_child(context.build_node(raw_child))

	scroll.add_child(inner)

	return scroll
