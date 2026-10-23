class_name LuaGridBox extends GridContainer
## Slot do Grid. fill = true: cada filho preenche a célula (colunas dividem o espaço extra).
## justify_self e align_self por filho funcionam como no Stack.

var fill := true:
	set(value):
		fill = value
		for child in get_children():
			if child is Control:
				refresh_child(child)


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	for child in get_children():
		if child is Control:
			refresh_child(child)


func refresh_child(child: Control) -> void:
	_apply(child)
	var cb := _apply.bind(child)
	if not child.minimum_size_changed.is_connected(cb):
		child.minimum_size_changed.connect(cb)


func _on_child_entered(child: Node) -> void:
	if child is Control:
		refresh_child(child)


func _apply(child: Control) -> void:
	var h := StringName(child.get_meta(&"justify_self", PropertyDefinition.AUTO))
	var v := StringName(child.get_meta(&"align_self", PropertyDefinition.AUTO))
	child.size_flags_horizontal = _flag(h, child.custom_minimum_size.x > 0.0)
	child.size_flags_vertical = _flag(v, child.custom_minimum_size.y > 0.0)


func _flag(align: StringName, explicit: bool) -> int:
	if align == PropertyDefinition.AUTO:
		align = PropertyDefinition.STRETCH if fill else PropertyDefinition.START
	if align == PropertyDefinition.STRETCH:
		return Control.SIZE_SHRINK_BEGIN if explicit else Control.SIZE_EXPAND_FILL
	return PropertyDefinition.CROSS_ALIGNS.get(align, Control.SIZE_FILL)
