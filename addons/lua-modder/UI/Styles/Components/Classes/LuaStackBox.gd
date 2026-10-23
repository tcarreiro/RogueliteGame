class_name LuaStackBox extends MarginContainer
## Slot de camadas. Todos os filhos ocupam a mesma área; o último fica por cima.
##   justify_self -> horizontal, align_self -> vertical.

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	for child in get_children():
		if child is Control:
			refresh_child(child)


func refresh_child(child: Control) -> void:
	_apply_layer(child)
	var cb := _apply_layer.bind(child)
	if not child.minimum_size_changed.is_connected(cb):
		child.minimum_size_changed.connect(cb)


func _on_child_entered(child: Node) -> void:
	if child is Control:
		refresh_child(child)


func _apply_layer(child: Control) -> void:
	var h := StringName(child.get_meta(&"justify_self", PropertyDefinition.AUTO))
	var v := StringName(child.get_meta(&"align_self", PropertyDefinition.AUTO))
	child.size_flags_horizontal = _flag(h, child.custom_minimum_size.x > 0.0)
	child.size_flags_vertical = _flag(v, child.custom_minimum_size.y > 0.0)


## stretch (e auto) estica, a menos que haja tamanho explícito: aí vira o tamanho dele.
func _flag(align: StringName, explicit: bool) -> int:
	if align == PropertyDefinition.AUTO:
		align = PropertyDefinition.STRETCH
	if align == PropertyDefinition.STRETCH and explicit:
		return Control.SIZE_SHRINK_BEGIN
	return PropertyDefinition.CROSS_ALIGNS.get(align, Control.SIZE_FILL)
