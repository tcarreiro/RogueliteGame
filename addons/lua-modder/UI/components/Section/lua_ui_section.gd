class_name LuaUiSection extends LuaUiComponent

const BACKGROUND_META := "lua_ui_background"

func get_type_name() -> String:
	return "section"

func get_style_target(built_node: Control) -> Control:
	return built_node.get_meta(BACKGROUND_META, null)


func build(definition: Dictionary, context: LuaUiBuildContext) -> Control:
	var flow_container: Container = _build_flow_container(definition)

	if definition.has("gap"):
		flow_container.add_theme_constant_override("separation", int(definition["gap"]))

	if flow_container is BoxContainer and definition.has("align"):
		match str(definition["align"]):
			"start": flow_container.alignment = BoxContainer.ALIGNMENT_BEGIN
			"center": flow_container.alignment = BoxContainer.ALIGNMENT_CENTER
			"end": flow_container.alignment = BoxContainer.ALIGNMENT_END

	var flow_children: Array = []
	var absolute_children: Array = []

	for raw_child in definition.get("children", []):
		var pos_mode = raw_child.get("position", {}).get("mode", "")
		if pos_mode == "absolute":
			absolute_children.append(raw_child)
		else:
			flow_children.append(raw_child)

	for child_def in flow_children:
		flow_container.add_child(context.build_node(child_def))

	var content: Control = flow_container
	if definition.has("padding"):
		content = context.factory.wrap_with_padding(flow_container, definition["padding"])

	var has_background: bool = definition.get("panel", false)
	var layers := context.factory.build_layered_root(definition, content, has_background)
	var root: Control = layers["root"]

	if layers["background"] != null:
		root.set_meta(BACKGROUND_META, layers["background"])

	for child_def in absolute_children:
		var child_node := context.build_node(child_def)
		_apply_absolute_position(child_node, child_def.get("position", {}))
		root.add_child(child_node)

	return root


func _build_flow_container(definition: Dictionary) -> Container:
	match definition.get("direction", "vertical"):
		"horizontal":
			return HBoxContainer.new()
		"grid":
			var grid := GridContainer.new()
			grid.columns = int(definition.get("columns", 2))
			return grid
		_:
			return VBoxContainer.new()


func _apply_absolute_position(node: Control, position_def: Dictionary) -> void:
	if position_def.has("anchor"):
		match str(position_def["anchor"]):
			"top_left": node.set_anchors_preset(Control.PRESET_TOP_LEFT)
			"top_right": node.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			"bottom_left": node.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			"bottom_right": node.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			"full": node.set_anchors_preset(Control.PRESET_FULL_RECT)
			_: node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	else:
		node.set_anchors_preset(Control.PRESET_TOP_LEFT)

	if position_def.has("x") or position_def.has("y"):
		node.position = Vector2(float(position_def.get("x", 0)), float(position_def.get("y", 0)))
