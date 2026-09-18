class_name LuaUiPanel extends LuaUiComponent

func get_type_name() -> String:
	return "panel"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel
