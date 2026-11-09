extends LuaStyledBox

func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.DISPLAY, PropertyDefinition.GAP, PropertyDefinition.ALIGNMENT, PropertyDefinition.ALIGN_ITEMS]
	names.append_array(LuaStyledBox.box_names())
	names.append_array(PropertyDefinition.DRAG_GRP)
	return {
		"name": "Stack",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 4, PropertyDefinition.ALIGNMENT: PropertyDefinition.START}),
		"slots": {"default": "%Items"},
	}
