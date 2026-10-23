class_name LuaFlowBox extends BoxContainer
## Slot dos componentes com filhos (Div, Scroll, Body). Funciona como um flexbox:
## block = coluna, flex = linha (BoxContainer.vertical).
##   eixo principal: o filho ocupa o conteúdo; com flex_grow, uma fatia do espaço livre
##   eixo cruzado:   o filho estica, a menos que tenha tamanho explícito, align_self ou align_items

var align_items: StringName = PropertyDefinition.STRETCH:
	set(value):
		align_items = value
		refresh_flow()

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	refresh_flow()


func refresh_flow() -> void:
	for child in get_children():
		if child is Control:
			refresh_child(child)


func refresh_child(child: Control) -> void:
	_apply_flow_sizing(child)
	_watch(child)


func _on_child_entered(child: Node) -> void:
	if child is Control:
		refresh_child(child)


#func _watch(child: Control) -> void:
	## quem tem flex_grow já definiu as próprias flags (em LuaComponent._apply_flex_grow)
	#if float(child.get_meta(PropertyDefinition.FLEX_GROW, 0.0)) > 0.0:
		#return
	#var cb := _apply_flow_sizing.bind(child)
	#if not child.minimum_size_changed.is_connected(cb):
		#child.minimum_size_changed.connect(cb)

func _watch(child: Control) -> void:
	var cb := _apply_flow_sizing.bind(child)
	if not child.minimum_size_changed.is_connected(cb):
		child.minimum_size_changed.connect(cb)


#func _apply_flow_sizing(child: Control) -> void:
	#if float(child.get_meta(PropertyDefinition.FLEX_GROW, 0.0)) > 0.0: return
	#var has_explicit_width := child.custom_minimum_size.x > 0.0
#
	#if vertical:
		## block: ocupa a linha inteira, a menos que tenha width (vira min-width)
		#child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if has_explicit_width else Control.SIZE_FILL
		#child.size_flags_vertical = Control.SIZE_FILL
	#else:
		## flex: eixo principal já é fit-content por padrão do BoxContainer;
		## flex_grow (já tratado nas BASE_PROPS) cuida de quem deve crescer.
		#child.size_flags_vertical = Control.SIZE_FILL
func _apply_flow_sizing(child: Control) -> void:
	var grow := float(child.get_meta(&"flex_grow", 0.0))
	var main_flag := Control.SIZE_EXPAND_FILL if grow > 0.0 else Control.SIZE_FILL

	var align := StringName(child.get_meta(&"align_self", PropertyDefinition.AUTO))
	if align == PropertyDefinition.AUTO:
		align = align_items
	var cross_flag: int = PropertyDefinition.CROSS_ALIGNS.get(align, Control.SIZE_FILL)

	# tamanho explícito no eixo cruzado vale como mínimo e não estica
	var explicit_cross := (child.custom_minimum_size.x if vertical else child.custom_minimum_size.y) > 0.0
	if explicit_cross and align == PropertyDefinition.STRETCH:
		cross_flag = Control.SIZE_SHRINK_BEGIN

	if vertical:
		child.size_flags_vertical = main_flag
		child.size_flags_horizontal = cross_flag
	else:
		child.size_flags_horizontal = main_flag
		child.size_flags_vertical = cross_flag
	child.size_flags_stretch_ratio = grow if grow > 0.0 else 1.0
