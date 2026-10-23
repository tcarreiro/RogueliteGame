extends LuaStyledBox

@onready var _btn: Button = %Button

func get_schema() -> Dictionary:
	var names: Array = [PropertyDefinition.LABEL]
	names.append_array(PropertyDefinition.FONT)
	names.append_array(LuaStyledBox.box_names())
	return {
		"name": "Button",
		"props": PropertyDefinition.pick(names),
		"events": ["pressed", "mouse_entered", "mouse_exited", "focus_entered", "focus_exited"],
	}


func _setup_style_target() -> void:
	_style_target.register_group(PropertyDefinition.FONT, _btn)


func _component_ready() -> void:
	LuaStyledBox.strip_native_stylebox(_btn, ["normal", "hover", "pressed", "disabled", "focus"])
	_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE   # o mouse é do %Background
	_background.gui_input.connect(_on_click)

	forward_signal(_background.mouse_entered, "mouse_entered")
	forward_signal(_background.mouse_exited, "mouse_exited")
	_btn.focus_entered.connect(func():
		set_state(&"focus", true)
		emit_event("focus_entered"))
	_btn.focus_exited.connect(func():
		set_state(&"focus", false)
		emit_event("focus_exited"))


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.LABEL:
			_btn.text = str(value)
		PropertyDefinition.DISABLED:
			_btn.disabled = value
			set_state(&"disabled", value)
		_:
			super._apply_prop(key, value)


func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if props.get("disabled", false):
			return
		emit_event("pressed")
