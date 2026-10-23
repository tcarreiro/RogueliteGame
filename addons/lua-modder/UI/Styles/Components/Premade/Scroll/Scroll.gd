extends LuaComponent

@onready var _margin: MarginContainer = %Margin
@onready var _items: LuaFlowBox = %Items
@onready var _sc: Variant = self

var _at_start := true
var _at_end := false

func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.PADDING, PropertyDefinition.GAP,
		PropertyDefinition.WIDTH, PropertyDefinition.HEIGHT,
		PropertyDefinition.MAX_WIDTH, PropertyDefinition.MAX_HEIGHT,
		PropertyDefinition.DIRECTION, PropertyDefinition.SCROLLBAR_MODE,
		PropertyDefinition.FOLLOW_FOCUS, PropertyDefinition.EDGE_THRESHOLD,
		PropertyDefinition.SCROLL_HINT, PropertyDefinition.SCROLL_HINT_TILE,
		PropertyDefinition.DISPLAY
	]
	names.append_array(PropertyDefinition.PANEL)
	names.append_array(PropertyDefinition.SCROLLBAR)   # inclui scrollbar_gap e o raio por canto
	return {
		"name": "Scroll",
		"props": PropertyDefinition.pick(names, {PropertyDefinition.GAP: 4}),
		"events": ["scrolled", "reached_start", "reached_end", "scroll_started", "scroll_ended"],
		"methods": ["scroll_to_top", "scroll_to_bottom", "scroll_to_ref"],
		"slots": {"default": "%Items"},
	}


func _ready() -> void:
	_style_target.register_property(PropertyDefinition.PADDING, _margin)
	for prop in PropertyDefinition.SCROLLBAR:
		_style_target.register_property(prop, _sc)
	for prop in PropertyDefinition.PANEL:
		_style_target.register_property(prop, _sc)
	super._ready()


func _component_ready() -> void:
	_sc.scroll_started.connect(func(): emit_event("scroll_started"))
	_sc.scroll_ended.connect(func(): emit_event("scroll_ended"))

	var v_bar: ScrollBar = _sc.get_v_scroll_bar()
	var h_bar: ScrollBar = _sc.get_h_scroll_bar()
	v_bar.value_changed.connect(func(_v): _on_scrolled())
	h_bar.value_changed.connect(func(_v): _on_scrolled())
	# max_value/page mudam quando o conteúdo cresce, sem o value mudar
	v_bar.changed.connect(_check_edges)
	h_bar.changed.connect(_check_edges)


func _apply_prop(key: String, value: Variant) -> void:
	match key:
		PropertyDefinition.DIRECTION, PropertyDefinition.SCROLLBAR_MODE:
			_refresh_scroll_modes()
		PropertyDefinition.WIDTH:
			if value != null and int(value) >= 0:
				custom_minimum_size.x = value
		PropertyDefinition.HEIGHT:
			if value != null and int(value) >= 0:
				custom_minimum_size.y = value
		PropertyDefinition.MAX_WIDTH:
			if value != null:
				custom_maximum_size.x = float(value)   # < 0 = sem limite (doc)
		PropertyDefinition.MAX_HEIGHT:
			if value != null:
				custom_maximum_size.y = float(value)
		PropertyDefinition.GAP:
			_items.add_theme_constant_override("separation", int(value))
		PropertyDefinition.FOLLOW_FOCUS:
			_sc.follow_focus = value
		PropertyDefinition.SCROLL_HINT:
			_sc.scroll_hint_mode = PropertyDefinition.HINT_MODES.get(StringName(value), ScrollContainer.SCROLL_HINT_MODE_DISABLED)
		PropertyDefinition.SCROLL_HINT_TILE:
			_sc.tile_scroll_hint = value
		PropertyDefinition.DISPLAY:
			_items.vertical = (value != PropertyDefinition.FLEX)
			_items.refresh_flow()
		_:
			super._apply_prop(key, value)


func _refresh_scroll_modes() -> void:
	var dir := StringName(props.get(PropertyDefinition.DIRECTION, PropertyDefinition.BOTH))
	var base: int = PropertyDefinition.SCROLL_MODES.get(
			StringName(props.get(PropertyDefinition.SCROLLBAR_MODE, PropertyDefinition.AUTO)), ScrollContainer.SCROLL_MODE_AUTO)
	var h_max := int(props.get(PropertyDefinition.MAX_WIDTH, -1)) >= 0
	var v_max := int(props.get(PropertyDefinition.MAX_HEIGHT, -1)) >= 0
	_sc.horizontal_scroll_mode = _axis_mode(dir != PropertyDefinition.VERTICAL, h_max, base)
	_sc.vertical_scroll_mode = _axis_mode(dir != PropertyDefinition.HORIZONTAL, v_max, base)
	_sc.scroll_horizontal_by_default = (dir == PropertyDefinition.HORIZONTAL)


func _axis_mode(enabled: bool, has_max: bool, base: int) -> int:
	if not enabled:
		return ScrollContainer.SCROLL_MODE_DISABLED
	if base == ScrollContainer.SCROLL_MODE_AUTO and has_max:
		return ScrollContainer.SCROLL_MODE_MAXIMIZE_FIRST
	return base


#region Métodos expostos ao Lua (UI.callMethod)
func scroll_to_top() -> void:
	_sc.scroll_vertical = 0


func scroll_to_bottom() -> void:
	await get_tree().process_frame   # o layout precisa assentar (doc de scroll_vertical)
	var bar: ScrollBar = _sc.get_v_scroll_bar()
	_sc.scroll_vertical = int(bar.max_value - bar.page)


func scroll_to_ref(ref: String) -> void:
	var target := ComponentRegistry.get_ref(ref)
	if target:
		await get_tree().process_frame   # não funciona no mesmo frame em que o nó foi adicionado (doc)
		_sc.ensure_control_visible(target)
#endregion


#region Eventos
func _on_scrolled() -> void:
	emit_event("scrolled", [_sc.scroll_horizontal, _sc.scroll_vertical])
	_check_edges()


func _check_edges() -> void:
	var horizontal: bool = props.get(PropertyDefinition.DIRECTION, PropertyDefinition.BOTH) == PropertyDefinition.HORIZONTAL
	var bar: ScrollBar = _sc.get_h_scroll_bar() if horizontal else _sc.get_v_scroll_bar()
	var max_scroll: float = bar.max_value - bar.page
	if max_scroll <= 0.0:
		_at_start = true
		_at_end = false
		return   # o conteúdo cabe, não há o que rolar

	var threshold: float = props.get(PropertyDefinition.EDGE_THRESHOLD, 0)
	var at_start: bool = bar.value <= threshold
	var at_end: bool = bar.value >= max_scroll - threshold
	if at_start and not _at_start:
		emit_event("reached_start")
	if at_end and not _at_end:
		emit_event("reached_end")
	_at_start = at_start
	_at_end = at_end
#endregion
