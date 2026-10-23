extends LuaStyledBox

@onready var _row: HBoxContainer = %Row
@onready var _box: PanelContainer = %Box
@onready var _inset: MarginContainer = %Inset
@onready var _mark: PanelContainer = %Mark
@onready var _label: Label = %Label

var _checked := false


func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.CHECKED, PropertyDefinition.LABEL, PropertyDefinition.RADIO, PropertyDefinition.DISABLED,
		PropertyDefinition.MODEL, PropertyDefinition.INDICATOR_SIZE, PropertyDefinition.MARK_INSET, PropertyDefinition.GAP,
	]
	names.append_array(LuaStyledBox.box_names())
	var props := PropertyDefinition.pick(names, {PropertyDefinition.GAP: 8})
	props.merge(PropertyDefinition.pick(PropertyDefinition.PANEL, {}, "box_"))
	props.merge(PropertyDefinition.pick(PropertyDefinition.PANEL, {}, "mark_"))
	props.merge(PropertyDefinition.pick(PropertyDefinition.FONT, {}, "label_"))
	return {"name": "Checkbox", "props": props, "events": ["changed"], "methods": ["toggle"]}


func _setup_style_target() -> void:
	_style_target.register_group(PropertyDefinition.PANEL, _box, "box_")
	_style_target.register_group(PropertyDefinition.PANEL, _mark, "mark_")
	_style_target.register_group(PropertyDefinition.FONT, _label, "label_")


func _component_ready() -> void:
	for node in [_box, _inset, _mark, _label]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE   # o clique é do %Background
	_background.focus_mode = Control.FOCUS_ALL


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.CHECKED:
			if not _has_model():
				_set_checked(bool(value), false)
		PropertyDefinition.MODEL:
			if value != null:
				_set_checked(bool(value), false)
		PropertyDefinition.LABEL:
			_label.text = str(value)
			_label.visible = str(value) != ""
		PropertyDefinition.GAP:
			_row.add_theme_constant_override("separation", maxi(int(value), 0))
		PropertyDefinition.INDICATOR_SIZE:
			_box.custom_minimum_size = Vector2.ONE * maxi(int(value), 1)
		PropertyDefinition.MARK_INSET:
			for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
				_inset.add_theme_constant_override(side, maxi(int(value), 0))
		PropertyDefinition.DISABLED:
			set_state(&"disabled", bool(value))
			_background.focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
		_:
			super._apply_prop(key, value)


func _on_background_gui_input(event: InputEvent) -> void:
	super._on_background_gui_input(event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle()
	elif event.is_action_pressed(&"ui_accept"):
		toggle()


## Chamado pelo usuário (clique, Enter, Espaço) e exposto ao Lua.
func toggle() -> void:
	if bool(props.get("disabled", false)):
		return
	if bool(props.get("radio", false)):
		if _checked:
			return
		_set_checked(true, true)
	else:
		_set_checked(not _checked, true)


func _set_checked(value: bool, notify: bool) -> void:
	_checked = value
	_mark.visible = value
	props["checked"] = value
	set_state(&"checked", value)
	if notify:
		emit_event("changed", [value])
		_write_model(value)
