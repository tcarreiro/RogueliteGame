extends LuaStyledBox

@onready var _value_label: Label = %Value
@onready var _caret: Label = %Caret

var _options: Array = []
var _selected: Variant = null
var _popup: LuaPopupLayer


func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.OPTION_LIST, PropertyDefinition.VALUE, PropertyDefinition.MODEL, PropertyDefinition.PLACEHOLDER,
		PropertyDefinition.CARET, PropertyDefinition.DISABLED, PropertyDefinition.OPTION_CLASS, PropertyDefinition.LIST_CLASS,
		PropertyDefinition.LIST_MAX_HEIGHT, PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
	]
	names.append_array(PropertyDefinition.FONT)
	names.append_array(LuaStyledBox.box_names())
	var props := PropertyDefinition.pick(names, {
		PropertyDefinition.OPTION_CLASS: "dropdown-option",
		PropertyDefinition.LIST_CLASS: "dropdown-list",
	})
	props.merge(PropertyDefinition.pick(PropertyDefinition.FONT, {}, "caret_"))
	return {
		"name": "Dropdown",
		"props": props,
		"events": ["changed", "opened", "closed"],
		"methods": ["open", "close", "toggle"],
	}


func _setup_style_target() -> void:
	_style_target.register_group(PropertyDefinition.FONT, _value_label)
	_style_target.register_group(PropertyDefinition.FONT, _caret, "caret_")


func _component_ready() -> void:
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.focus_mode = Control.FOCUS_ALL
	_options = LuaHelper.parse_options(props.get(PropertyDefinition.OPTIONS))
	_selected = props.get("model") if _has_model() else props.get(PropertyDefinition.VALUE)
	_refresh_label()
	tree_exiting.connect(close)


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.OPTION_LIST:
			_options = LuaHelper.parse_options(value)
			_refresh_label()
		PropertyDefinition.VALUE:
			if not _has_model():
				_selected = value
				_refresh_label()
		PropertyDefinition.MODEL:
			if value != null:
				_selected = value
				_refresh_label()
		PropertyDefinition.PLACEHOLDER:
			_refresh_label()
		PropertyDefinition.CARET:
			_caret.text = str(value)
		PropertyDefinition.WIDTH:
			if int(value) >= 0:
				custom_minimum_size.x = value
		PropertyDefinition.HEIGHT:
			if int(value) >= 0:
				custom_minimum_size.y = value
		PropertyDefinition.DISABLED:
			set_state(&"disabled", bool(value))
			_background.focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
			if value:
				close()
		_:
			super._apply_prop(key, value)


func _refresh_label() -> void:
	var text := str(props.get(PropertyDefinition.PLACEHOLDER, ""))
	for opt in _options:
		if LuaHelper.same_value(opt.value, _selected):
			text = opt.label
			break
	_value_label.text = text


func _on_background_gui_input(event: InputEvent) -> void:
	super._on_background_gui_input(event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle()
	elif event.is_action_pressed(&"ui_accept"):
		toggle()


func toggle() -> void:
	if _popup != null:
		close()
	else:
		open()


func open() -> void:
	if _popup != null or bool(props.get(PropertyDefinition.DISABLED, false)) or _options.is_empty():
		return
	_popup = LuaPopupLayer.open(_background, _build_list())
	_popup.dismissed.connect(_on_popup_dismissed)
	set_state(&"open", true)
	emit_event("opened")


func close() -> void:
	if _popup != null:
		_popup.close()


func _on_popup_dismissed() -> void:
	_popup = null
	set_state(&"open", false)
	emit_event("closed")


## A lista é montada com os próprios componentes do framework (Scroll > Div > Button).
## Ela mora fora desta árvore, então o estilo vem de option_class e list_class
## (seletores de descendente não alcançam a lista).
func _build_list() -> Control:
	var items: Array = []
	for opt in _options:
		var option_class := str(props.get(PropertyDefinition.OPTION_CLASS, ""))
		if LuaHelper.same_value(opt.value, _selected):
			option_class += " selected"
		items.append(ComponentRegistry.make_element("Button", {
			"label": opt.label,
			"class": option_class,
			"disabled": opt.disabled,
			"on_pressed": _select.bind(opt.value),
		}))
	var list := ComponentRegistry.make_element("Div", {
		"class": str(props.get(PropertyDefinition.LIST_CLASS, "")), "gap": 2, "children": items,
	})
	var scroll := ComponentRegistry.make_element("Scroll", {
		"scrollbar_mode": "grow", "max_height": int(props.get(PropertyDefinition.LIST_MAX_HEIGHT, 240)), "children": [list],
	})
	return ComponentRegistry.instantiate(scroll)


func _select(value: Variant) -> void:
	var changed := not LuaHelper.same_value(_selected, value)
	_selected = value
	_refresh_label()
	close()
	if changed:
		emit_event("changed", [value])
		_write_model(value)
