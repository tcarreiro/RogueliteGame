extends LuaStyledBox

@onready var _items: LuaFlowBox = %Items

var _options: Array = []
var _selected: Variant = null
var _nodes: Array[LuaComponent] = []


func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.OPTION_LIST, PropertyDefinition.VALUE, PropertyDefinition.MODEL, PropertyDefinition.DISPLAY,
		PropertyDefinition.GAP, PropertyDefinition.DISABLED, PropertyDefinition.OPTION_CLASS,
	]
	names.append_array(LuaStyledBox.box_names())
	return {
		"name": "RadioGroup",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 8, PropertyDefinition.OPTION_CLASS: "radio"}),
		"events": ["changed"],
	}


func _component_ready() -> void:
	_options = LuaHelper.parse_options(props.get("options"))
	_selected = props.get("model") if _has_model() else props.get("value")
	_rebuild()


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.DISPLAY:
			_items.vertical = (value != "flex")
			_items.refresh_flow()
		PropertyDefinition.GAP:
			_items.add_theme_constant_override("separation", maxi(int(value), 0))
		PropertyDefinition.DISABLED:
			set_state(&"disabled", bool(value))
			if _is_ready:
				_rebuild()
		PropertyDefinition.OPTION_LIST, PropertyDefinition.OPTION_CLASS:
			if _is_ready:
				_options = LuaHelper.parse_options(props.get("options"))
				_rebuild()
		PropertyDefinition.VALUE:
			if _is_ready and not _has_model():
				_select(value, false)
		PropertyDefinition.MODEL:
			if _is_ready and value != null:
				_select(value, false)
		_:
			super._apply_prop(key, value)


func _rebuild() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		if child is LuaComponent:
			child.dispose()
		else:
			child.queue_free()
	_nodes.clear()
	for opt in _options:
		var el := ComponentRegistry.make_element("Checkbox", {
			"label": opt.label,
			"radio": true,
			"checked": LuaHelper.same_value(opt.value, _selected),
			"disabled": opt.disabled or bool(props.get("disabled", false)),
			"class": str(props.get("option_class", "")),
			"on_changed": _on_option_changed.bind(opt.value),
		})
		var node := ComponentRegistry.instantiate(el) as LuaComponent
		_items.add_child(node)
		_nodes.append(node)


## O Callable recebe (marcado) do evento e depois o valor ligado no bind.
func _on_option_changed(checked: bool, value: Variant) -> void:
	if checked:
		_select(value, true)


func _select(value: Variant, notify: bool) -> void:
	_selected = value
	for i in mini(_options.size(), _nodes.size()):
		_nodes[i].set_prop("checked", LuaHelper.same_value(_options[i].value, value))
	if notify:
		emit_event("changed", [value])
		_write_model(value)
