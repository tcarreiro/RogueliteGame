class_name GDSSUiBridge extends Node

static func _set_gdss_classes_on_node(node: Control, classes: Array[StringName]) -> void:
	_set_gdss_enable(node)
	_clear_gdss_classes(node)
	_add_gdss_classes_to_node(node, classes)


static func _set_instance_var(node: Control, var_name: StringName, value: Variant) -> void:
	GDSS.set_instance_var(node, var_name, value)


static func _set_override(node: Control, prop_name: StringName, value: Variant) -> void:
	GDSS.set_prop_override(node, prop_name, value)


static func _get_gdss_classes(node: Control) -> Array[StringName]:
	var result: Array[StringName] = []
	if node.has_meta(GDSS.CLASSES_META):
		var raw: PackedStringArray = node.get_meta(GDSS.CLASSES_META)
		for s in raw:
			result.append(StringName(s))
	return result


## Adiciona classes sem apagar as que já existem no node (diferente de
## _set_gdss_classes_on_node, que substitui a lista inteira).
static func _add_gdss_classes(node: Control, new_classes: Array[StringName]) -> void:
	_set_gdss_enable(node)
	var classes := _get_gdss_classes(node)
	for c in new_classes:
		if not classes.has(c):
			classes.append(c)
	_add_gdss_classes_to_node(node, classes)


static func _add_gdss_class(node: Control, class_name_value: StringName) -> void:
	_add_gdss_classes(node, [class_name_value])


static func _add_gdss_classes_to_node(node: Control, classes: Array[StringName]) -> void:
	node.set_meta(GDSS.CLASSES_META, PackedStringArray(classes))
	GdssNodeHandler.refresh(node)


static func _set_gdss_inherit(node: Control) -> void:
	GdssNodeHandler.set_mode_state(node, GDSS.GdssMode.INHERIT, false)
	GdssNodeHandler.refresh(node)


static func _set_gdss_enable(node: Control) -> void:
	GdssNodeHandler.set_mode_state(node, GDSS.GdssMode.ENABLE, false)
	GdssNodeHandler.refresh(node)


static func _set_gdss_disable(node: Control) -> void:
	GdssNodeHandler.set_mode_state(node, GDSS.GdssMode.DISABLE, false)
	_clear_gdss_classes(node)


static func _clear_gdss_classes(node: Control) -> void:
	node.set_meta(GDSS.CLASSES_META, PackedStringArray([]))
	GdssNodeHandler.refresh(node)
