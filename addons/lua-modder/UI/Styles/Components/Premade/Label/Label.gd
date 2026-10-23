extends LuaComponent

## A raiz é um Label, mas o script herda de LuaComponent (Control): Variant resolve em runtime.
@onready var _label: Variant = self


func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.TEXT, PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
			PropertyDefinition.MAX_WIDTH, PropertyDefinition.MAX_HEIGHT]
	names.append_array(PropertyDefinition.TEXT_LAYOUT)
	names.append_array(PropertyDefinition.LABEL_ONLY)
	names.append_array(PropertyDefinition.FONT)
	names.append_array(PropertyDefinition.TEXT_SHADOW)
	return {"name": "Label", "props": PropertyDefinition.pick(names, {PropertyDefinition.AUTOWRAP: "off"})}


func _ready() -> void:
	_style_target.register_group(PropertyDefinition.FONT, self)
	_style_target.register_group(PropertyDefinition.TEXT_SHADOW, self)
	_style_target.register_property(PropertyDefinition.LINE_SPACING, self)
	_style_target.register_property(PropertyDefinition.PARAGRAPH_SPACING, self)
	super._ready()


func _apply_prop(key: String, value: Variant) -> void:
	if not value:
		return
	match StringName(key):
		PropertyDefinition.TEXT:
			_label.text = str(value)
		PropertyDefinition.TEXT_ALIGN:
			_label.horizontal_alignment = PropertyDefinition.H_ALIGNS.get(StringName(str(value)), HORIZONTAL_ALIGNMENT_LEFT)
		PropertyDefinition.TEXT_VALIGN:
			_label.vertical_alignment = PropertyDefinition.V_ALIGNS.get(StringName(str(value)), VERTICAL_ALIGNMENT_TOP)
		PropertyDefinition.AUTOWRAP:
			_label.autowrap_mode = PropertyDefinition.AUTOWRAP_MODES.get(StringName(str(value)), TextServer.AUTOWRAP_OFF)
		PropertyDefinition.UPPERCASE:
			_label.uppercase = bool(value)
		PropertyDefinition.TEXT_OVERFLOW:
			_label.text_overrun_behavior = PropertyDefinition.TEXT_OVERFLOWS.get(StringName(str(value)), TextServer.OVERRUN_NO_TRIMMING)
		PropertyDefinition.CLIP_TEXT:
			_label.clip_text = bool(value)
		PropertyDefinition.MAX_LINES:
			_label.max_lines_visible = int(value)
		PropertyDefinition.LINES_SKIPPED:
			_label.lines_skipped = int(value)
		PropertyDefinition.VISIBLE_CHARACTERS:
			_label.visible_characters = int(value)
		PropertyDefinition.VISIBLE_RATIO:
			_label.visible_ratio = float(value)
		PropertyDefinition.AUTO_FONT_SIZE:
			_label.resize_font_to_fit = bool(value)
		PropertyDefinition.MIN_FONT_SIZE:
			_label.minimum_font_size = int(value)
		PropertyDefinition.MAX_FONT_SIZE:
			_label.maximum_font_size = int(value)
		PropertyDefinition.WIDTH:
			if int(value) >= 0: custom_minimum_size.x = value
		PropertyDefinition.HEIGHT:
			if int(value) >= 0: custom_minimum_size.y = value
		PropertyDefinition.MAX_WIDTH:
			custom_maximum_size.x = float(value)   # < 0 = sem limite
		PropertyDefinition.MAX_HEIGHT:
			custom_maximum_size.y = float(value)
		_:
			super._apply_prop(key, value)
