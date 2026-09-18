class_name LuaUiManager extends RefCounted

var _factory := LuaUiFactory.new()
var _translation_resolver: Callable = Callable(self, "_default_translation_resolver")
var _ui_root: Control = null
var _open_handles: Dictionary = {}
var _component_index: Dictionary = {}
var _last_handle_by_state: Dictionary = {}
var _next_handle_id: int = 0
var _themes: Dictionary = {}
var _animation_presets: Dictionary = {}  # nome -> LuaUiAnimationPreset
var _sounds: Dictionary = {}             # nome -> AudioStream


func _init() -> void:
	_factory.set_manager(self)
	
# ---------------------------------------------------------------------------
# Framework API
# ---------------------------------------------------------------------------

func set_translation_resolver(fn: Callable) -> void:
	_translation_resolver = fn
	_factory.set_translation_resolver(fn)


func register_theme(theme_name: String, theme: Theme) -> void:
	_themes[theme_name] = theme


func get_theme(theme_name: String) -> Theme:
	return _themes.get(theme_name, null)


func register_animation(name: String, preset: LuaUiAnimationPreset) -> void:
	_animation_presets[name] = preset


func get_animation_preset(name: String) -> LuaUiAnimationPreset:
	return _animation_presets.get(name, null)


func register_sound(name: String, stream: AudioStream) -> void:
	_sounds[name] = stream


func get_sound(name: String) -> AudioStream:
	return _sounds.get(name, null)


func set_ui_root(root: Control) -> void:
	_ui_root = root


func register_component(component: LuaUiComponent) -> void:
	_factory.register_component(component)


# ---------------------------------------------------------------------------
# Open
# ---------------------------------------------------------------------------

func open(definition: Dictionary, state: LuaState = null) -> int:
	return _open_from_dict(definition, null, state)


func open_at(definition: Dictionary, anchor_control: Control, state: LuaState = null) -> int:
	return _open_from_dict(definition, anchor_control, state)


func _open_from_dict(definition: Dictionary, anchor_control: Control, state: LuaState = null) -> int:
	var index := {}
	var context := LuaUiBuildContext.new(_factory, index, _translation_resolver, self)
	var content := _factory.build_content(definition, index, context)

	if definition.has("theme"):
		var theme: Theme = get_theme(str(definition["theme"]))
		if theme != null:
			content.theme = theme
	
	var has_background: bool = definition.get("panel", true)
	var layers := _factory.build_layered_root(definition, content, has_background)
	var root_wrapper: Control = layers["root"]
	
	var size = _resolve_size(definition.get("size"))
	if size != null:
		root_wrapper.custom_minimum_size = size
	
	var is_modal: bool = definition.get("modal", false)
	var position_def: Dictionary = definition.get("position", {"mode": "center"})
	var root_control: Control
	
	match position_def.get("mode", "center"):
		"center":
			var center := CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			center.mouse_filter = Control.MOUSE_FILTER_STOP if is_modal else Control.MOUSE_FILTER_IGNORE
			center.add_child(root_wrapper)
			root_control = center
		"anchor":
			root_wrapper.set_anchors_preset(_anchor_preset(position_def.get("anchor", "full")))
			root_control = root_wrapper
		"at":
			root_wrapper.set_anchors_preset(Control.PRESET_TOP_LEFT)
			root_wrapper.position = Vector2(float(position_def.get("x", 0)), float(position_def.get("y", 0)))
			root_control = root_wrapper
		"relative":
			root_wrapper.set_anchors_preset(Control.PRESET_TOP_LEFT)
			root_control = root_wrapper
		_:
			root_control = root_wrapper

	var handle_id := _register_open_handle(root_control, index)
	
	if position_def.get("mode") == "relative" and anchor_control != null:
		var placement: String = position_def.get("placement", "below_left")
		var offset := Vector2.ZERO
		if position_def.has("offset"):
			var off: Array = position_def["offset"]
			offset = Vector2(float(off[0]), float(off[1]))
		_apply_relative_position_deferred(root_control, anchor_control, placement, offset)

	if state != null:
		_last_handle_by_state[state] = handle_id

	return handle_id


# ---------------------------------------------------------------------------
# Size
# ---------------------------------------------------------------------------

func _resolve_size(size_def):
	if size_def == null:
		return null

	var viewport_size := _get_viewport_size()

	if size_def is String and size_def == "full":
		return viewport_size

	if size_def is Array and size_def.size() == 2:
		var width := viewport_size.x if size_def[0] is String and size_def[0] == "full" else float(size_def[0])
		var height := viewport_size.y if size_def[1] is String and size_def[1] == "full" else float(size_def[1])
		return Vector2(width, height)

	return null


func _get_viewport_size() -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree

	if tree == null:
		return Vector2(1920, 1080)

	return tree.root.get_viewport().get_visible_rect().size


# ---------------------------------------------------------------------------
# Position
# ---------------------------------------------------------------------------

func _apply_relative_position_deferred(control: Control, anchor_control: Control, placement: String, offset: Vector2) -> void:
	await anchor_control.get_tree().process_frame
	await anchor_control.get_tree().process_frame

	if not is_instance_valid(control) or not is_instance_valid(anchor_control):
		return

	var rect := anchor_control.get_global_rect()
	var my_size := control.size
	var pos := rect.position

	match placement:
		"below_left":
			pos = Vector2(rect.position.x, rect.end.y)

		"below_right":
			pos = Vector2(rect.end.x - my_size.x, rect.end.y)

		"above_left":
			pos = Vector2(rect.position.x, rect.position.y - my_size.y)

		"above_right":
			pos = Vector2(rect.end.x - my_size.x, rect.position.y - my_size.y)

		"right_top":
			pos = Vector2(rect.end.x, rect.position.y)

		"left_top":
			pos = Vector2(rect.position.x - my_size.x, rect.position.y)

	control.global_position = pos + offset


func _anchor_preset(anchor: String) -> int:
	match anchor:
		"top_left":
			return Control.PRESET_TOP_LEFT
		"top_right":
			return Control.PRESET_TOP_RIGHT
		"bottom_left":
			return Control.PRESET_BOTTOM_LEFT
		"bottom_right":
			return Control.PRESET_BOTTOM_RIGHT
		"top_full":
			return Control.PRESET_TOP_WIDE
		"bottom_full":
			return Control.PRESET_BOTTOM_WIDE
		"left_full":
			return Control.PRESET_LEFT_WIDE
		"right_full":
			return Control.PRESET_RIGHT_WIDE
		_:
			return Control.PRESET_FULL_RECT


# ---------------------------------------------------------------------------
# Root
# ---------------------------------------------------------------------------

func _resolve_ui_root() -> Control:
	if _ui_root != null:
		return _ui_root

	var tree := Engine.get_main_loop() as SceneTree

	if tree == null:
		push_error("[LuaUiManager] SceneTree indisponível.")
		return null

	var layer := tree.root.get_node_or_null("LuaUiLayer")

	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "LuaUiLayer"
		tree.root.add_child(layer)

	var default_root := layer.get_node_or_null("DefaultUiRoot") as Control

	if default_root == null:
		default_root = Control.new()
		default_root.name = "DefaultUiRoot"
		default_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		default_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(default_root)

	return default_root


# ---------------------------------------------------------------------------
# Handles
# ---------------------------------------------------------------------------

func _register_open_handle(root_node: Control, index: Dictionary) -> int:
	var root := _resolve_ui_root()

	if root == null:
		return -1

	root.add_child(root_node)

	var handle_id := _next_handle_id
	_next_handle_id += 1

	_open_handles[handle_id] = root_node
	_component_index[handle_id] = index

	return handle_id


func close(handle_id: int) -> void:
	if not _open_handles.has(handle_id):
		return

	var node: Control = _open_handles[handle_id]

	if is_instance_valid(node):
		node.queue_free()

	_open_handles.erase(handle_id)
	_component_index.erase(handle_id)

	for state in _last_handle_by_state:
		if _last_handle_by_state[state] == handle_id:
			_last_handle_by_state.erase(state)


func close_current(state: LuaState) -> void:
	if not _last_handle_by_state.has(state):
		return

	var handle_id: int = _last_handle_by_state[state]
	close(handle_id)
	_last_handle_by_state.erase(state)


func close_all() -> void:
	for handle_id in _open_handles.keys():
		var node: Control = _open_handles[handle_id]

		if is_instance_valid(node):
			node.queue_free()

	_open_handles.clear()
	_component_index.clear()
	_last_handle_by_state.clear()


func dispose() -> void:
	close_all()
	_ui_root = null
	_themes.clear()


# ---------------------------------------------------------------------------
# Component values
# ---------------------------------------------------------------------------

func get_current_value(state: LuaState, component_id: String):
	if not _last_handle_by_state.has(state):
		return null

	return get_value(_last_handle_by_state[state], component_id)


func set_current_value(state: LuaState, component_id: String, value) -> void:
	if not _last_handle_by_state.has(state):
		return

	set_value(_last_handle_by_state[state], component_id, value)


func set_value(handle_id: int, component_id: String, value) -> void:
	var component := _find_component(handle_id, component_id)

	if component == null:
		return

	if component is Range:
		component.value = value
	elif component is Label or component is Button or component is TextEdit or component is LineEdit:
		component.text = str(value)
	elif component is CheckBox:
		component.button_pressed = bool(value)
	elif component is ColorPickerButton or component is ColorPicker:
		component.color = LuaHelper.parse_color(value)


func get_value(handle_id: int, component_id: String):
	var component := _find_component(handle_id, component_id)

	if component == null:
		return null

	if component is Range:
		return component.value
	if component is LineEdit or component is TextEdit or component is Label or component is Button:
		return component.text
	if component is CheckBox:
		return component.button_pressed
	if component is ColorPickerButton or component is ColorPicker:
		return component.color

	return null


func _find_component(handle_id: int, component_id: String) -> Control:
	if not _component_index.has(handle_id):
		return null

	return _component_index[handle_id].get(component_id, null)


func _default_translation_resolver(key: String) -> String:
	return key
