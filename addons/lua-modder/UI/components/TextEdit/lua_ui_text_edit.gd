class_name LuaUiTextEdit extends LuaUiComponent


func get_type_name() -> String:
	return "textedit"


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var edit := TextEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit.text = str(definition.get("value", ""))
	edit.editable = definition.get("editable", true)
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if definition.get("wrap", true) else TextEdit.LINE_WRAPPING_NONE

	if definition.has("on_value_changed"):
		var callback := LuaHelper.make_callable(definition["on_value_changed"])

		if callback.is_valid():
			edit.text_changed.connect(func(): callback.call(edit.text))

	return edit
