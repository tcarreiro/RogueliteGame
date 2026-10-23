extends LuaComponent

@onready var _body: BoxContainer = %Body

func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.DISPLAY, PropertyDefinition.GAP, PropertyDefinition.ALIGNMENT]
	names.append_array(LuaStyledBox.box_names())
	return {
		"name": "Body",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 4, PropertyDefinition.ALIGNMENT: PropertyDefinition.START}),
		"slots": {"default": "%Body"},
	}


func _apply_prop(key: String, value: Variant) -> void:
	if value == null:
		return
	match StringName(key):
		PropertyDefinition.DISPLAY:
			_body.vertical = (value != "flex")
		PropertyDefinition.ALIGNMENT:
			if PropertyDefinition.ALIGNMENTS.has(value):
				_body.alignment = PropertyDefinition.ALIGNMENTS[value]
		PropertyDefinition.GAP:
			_body.add_theme_constant_override("separation", maxi(int(value), 0))
		_:
			super._apply_prop(key, value)


#func _apply_prop(key: String, value: Variant) -> void:
	#match StringName(key):
		#PropertyDefinition.DISPLAY:
			#_items.vertical = (value != "flex")
		#PropertyDefinition.ALIGNMENT:
			#if PropertyDefinition.ALIGNMENTS.has(value):
				#_items.alignment = PropertyDefinition.ALIGNMENTS[value]
		#PropertyDefinition.GAP:
			#_items.add_theme_constant_override("separation", maxi(int(value), 0))
		#PropertyDefinition.DISABLED:
			#set_state(&"disabled", value)
		#_:
			#super._apply_prop(key, value)
