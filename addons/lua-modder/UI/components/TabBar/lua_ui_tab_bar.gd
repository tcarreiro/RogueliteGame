class_name LuaUiTabbar extends LuaUiComponent


func get_type_name() -> String:
	return "tabbar"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var pages: Array = definition.get("tabs", [])

	for i in range(pages.size()):
		var page_def: Dictionary = pages[i]
		var page_node = context.build_node(page_def.get("content", {}))
		tabs.add_child(page_node)
		tabs.set_tab_title(i, context.resolve_text(page_def.get("title", "")))

	if definition.has("on_tab_changed"):
		var callback := LuaHelper.make_callable(definition["on_tab_changed"])

		if callback.is_valid():
			tabs.tab_changed.connect(callback)

	return tabs
