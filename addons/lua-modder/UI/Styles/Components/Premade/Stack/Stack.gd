extends LuaStyledBox

func get_schema() -> Dictionary:
	return {
		"name": "Stack",
		"props": PropertyDefinition.pick(LuaStyledBox.box_names()),
		"slots": {"default": "%Items"},
	}
