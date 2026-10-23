extends LuaStyledBox

@onready var _row: HBoxContainer = %Row
@onready var _label: Label = %Label
@onready var _rail: Control = %Rail
@onready var _track: PanelContainer = %Track
@onready var _fill: PanelContainer = %Fill
@onready var _thumb: PanelContainer = %Thumb
@onready var _value_label: Label = %ValueLabel

const DEFAULT_RAIL_WIDTH := 160.0

var _value := 0.0
var _dragging := false


func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.VALUE, PropertyDefinition.MODEL, PropertyDefinition.MIN, PropertyDefinition.MAX, PropertyDefinition.STEP,
		PropertyDefinition.DECIMALS, PropertyDefinition.LABEL, PropertyDefinition.SHOW_VALUE, PropertyDefinition.TRACK_HEIGHT,
		PropertyDefinition.THUMB_SIZE, PropertyDefinition.WIDTH, PropertyDefinition.GAP, PropertyDefinition.DISABLED,
		PropertyDefinition.CURSOR,
	]
	names.append_array(LuaStyledBox.box_names())
	var props := PropertyDefinition.pick(names, {PropertyDefinition.GAP: 12, PropertyDefinition.CURSOR: PropertyDefinition.POINTER})
	for prefix in ["track_", "fill_", "thumb_"]:
		props.merge(PropertyDefinition.pick(PropertyDefinition.PANEL, {}, prefix))
	props.merge(PropertyDefinition.pick(PropertyDefinition.FONT, {}, "label_"))
	props.merge(PropertyDefinition.pick(PropertyDefinition.FONT, {}, "value_"))
	return {"name": "Slider", "props": props, "events": ["changed", "released"]}


func _setup_style_target() -> void:
	_style_target.register_group(PropertyDefinition.PANEL, _track, "track_")
	_style_target.register_group(PropertyDefinition.PANEL, _fill, "fill_")
	_style_target.register_group(PropertyDefinition.PANEL, _thumb, "thumb_")
	_style_target.register_group(PropertyDefinition.FONT, _label, "label_")
	_style_target.register_group(PropertyDefinition.FONT, _value_label, "value_")
	# visual padrão: sem nenhum .lcss o slider já aparece
	_style_target.set_default(&"track_background_color", Color("3a3f55"))
	_style_target.set_default(&"track_border_radius", 3)
	_style_target.set_default(&"fill_background_color", Color("7a8cff"))
	_style_target.set_default(&"fill_border_radius", 3)
	_style_target.set_default(&"thumb_background_color", Color("e8ecff"))
	_style_target.set_default(&"thumb_border_radius", 10)


func _component_ready() -> void:
	for node in [_track, _fill, _thumb, _label, _value_label]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE   # o mouse é do %Rail
	_rail.mouse_filter = Control.MOUSE_FILTER_STOP
	_rail.focus_mode = Control.FOCUS_ALL
	_rail.gui_input.connect(_on_rail_gui_input)
	_rail.resized.connect(_layout)
	_rail.focus_entered.connect(func(): set_state(&"focus", true))
	_rail.focus_exited.connect(func():
		set_state(&"focus", false)
		_end_drag())
	_update_rail_size()
	_sync()


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.VALUE, PropertyDefinition.MODEL, PropertyDefinition.MIN, PropertyDefinition.MAX, PropertyDefinition.STEP:
			_sync()
		PropertyDefinition.DECIMALS:
			_refresh_texts()
		PropertyDefinition.LABEL:
			_label.text = str(value)
			_label.visible = str(value) != ""
		PropertyDefinition.SHOW_VALUE:
			_refresh_texts()
		PropertyDefinition.TRACK_HEIGHT, PropertyDefinition.THUMB_SIZE, PropertyDefinition.WIDTH:
			_update_rail_size()
			_layout()
		PropertyDefinition.GAP:
			_row.add_theme_constant_override("separation", maxi(int(value), 0))
		PropertyDefinition.DISABLED:
			set_state(&"disabled", bool(value))
			_rail.focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
			if value:
				_end_drag()
		PropertyDefinition.CURSOR:
			_rail.mouse_default_cursor_shape = PropertyDefinition.CURSORS.get(StringName(str(value)), Control.CURSOR_POINTING_HAND)
		_:
			super._apply_prop(key, value)


#region Valor
func _min() -> float:
	return float(props.get("min", 0.0))


func _max() -> float:
	return maxf(float(props.get("max", 100.0)), _min())


func _step() -> float:
	return maxf(float(props.get("step", 1.0)), 0.0)


func _to_float(v: Variant, fallback: float) -> float:
	if v is int or v is float:
		return float(v)
	if v is String and v.is_valid_float():
		return v.to_float()
	return fallback


## Lê sempre de `props`: a ordem em que as props chegam não importa.
func _sync() -> void:
	var source: Variant = props.get("model") if _has_model() else props.get("value")
	_apply_value(_to_float(source, _min()))


## Aplica o valor com passo e limites. Devolve true se mudou.
func _apply_value(v: float) -> bool:
	var step := _step()
	if step > 0.0:
		v = snappedf(v - _min(), step) + _min()
	v = clampf(v, _min(), _max())
	var changed := not is_equal_approx(v, _value)
	_value = v
	_refresh_texts()
	_layout()
	return changed


## Mudança feita pelo usuário: notifica o Lua e a store.
func _set_by_user(v: float) -> void:
	if _apply_value(v):
		props["value"] = _value
		emit_event("changed", [_value])
		_write_model(_value)


func _ratio() -> float:
	var span := _max() - _min()
	return 0.0 if span <= 0.0 else (_value - _min()) / span


func _refresh_texts() -> void:
	_value_label.visible = bool(props.get("show_value", false))
	_value_label.text = String.num(_value, maxi(int(props.get("decimals", 0)), 0))
#endregion


#region Geometria
func _thumb_size() -> Vector2:
	var raw: Variant = props.get("thumb_size", 20)
	if raw is Array and raw.size() == 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ONE * float(raw)


func _update_rail_size() -> void:
	var width := int(props.get("width", -1))
	var thickness := float(maxi(int(props.get("track_height", 6)), 1))
	_rail.custom_minimum_size = Vector2(
		float(width) if width >= 0 else DEFAULT_RAIL_WIDTH,
		maxf(_thumb_size().y, thickness))


## Os três painéis moram num Control comum, então a posição é calculada aqui.
func _layout() -> void:
	var rail := _rail.size
	var thumb := _thumb_size()
	var thickness := float(maxi(int(props.get("track_height", 6)), 1))
	var center_x := thumb.x * 0.5 + maxf(rail.x - thumb.x, 0.0) * _ratio()
	var top := (rail.y - thickness) * 0.5
	_track.position = Vector2(0.0, top)
	_track.size = Vector2(rail.x, thickness)
	_fill.position = Vector2(0.0, top)
	_fill.size = Vector2(center_x, thickness)
	_thumb.size = thumb
	_thumb.position = Vector2(center_x - thumb.x * 0.5, (rail.y - thumb.y) * 0.5)
#endregion


#region Entrada
func _on_rail_gui_input(event: InputEvent) -> void:
	if bool(props.get("disabled", false)):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			set_state(&"pressed", true)
			_rail.grab_focus()
			_set_from_mouse()
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _dragging:
		_set_from_mouse()
	elif event.is_action_pressed(&"ui_left"):
		_nudge(-1)
		_rail.accept_event()
	elif event.is_action_pressed(&"ui_right"):
		_nudge(1)
		_rail.accept_event()
	elif event.is_action_pressed(&"ui_home"):
		_set_by_user(_min())
		_rail.accept_event()
	elif event.is_action_pressed(&"ui_end"):
		_set_by_user(_max())
		_rail.accept_event()


func _set_from_mouse() -> void:
	var thumb := _thumb_size()
	var span := _rail.size.x - thumb.x
	if span <= 0.0:
		return
	var ratio := clampf((_rail.get_local_mouse_position().x - thumb.x * 0.5) / span, 0.0, 1.0)
	_set_by_user(_min() + ratio * (_max() - _min()))


func _nudge(direction: int) -> void:
	var increment := _step() if _step() > 0.0 else (_max() - _min()) / 100.0
	_set_by_user(_value + direction * increment)


func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	set_state(&"pressed", false)
	emit_event("released", [_value])
#endregion
