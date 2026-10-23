extends LuaStyledBox

@onready var _items: LuaFlowBox = %Items

func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.DISPLAY, PropertyDefinition.GAP, PropertyDefinition.ALIGNMENT, PropertyDefinition.ALIGN_ITEMS]
	names.append_array(LuaStyledBox.box_names())
	names.append_array(PropertyDefinition.DRAG_GRP)
	return {
		"name": "Div",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 4, PropertyDefinition.ALIGNMENT: PropertyDefinition.START}),
		"events": ["drag_started", "drag_ended"],
		"methods": ["reset_drag_position"],
		"slots": {"default": "%Items"},
	}


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.DISPLAY:
			_items.vertical = (value != "flex")
		PropertyDefinition.ALIGNMENT:
			if PropertyDefinition.ALIGNMENTS.has(value):
				_items.alignment = PropertyDefinition.ALIGNMENTS[value]
		PropertyDefinition.GAP:
			_items.add_theme_constant_override("separation", maxi(int(value), 0))
		PropertyDefinition.DISABLED:
			set_state(&"disabled", value)
		PropertyDefinition.ALIGN_ITEMS:
			_items.align_items = StringName(str(value))
		_:
			super._apply_prop(key, value)
