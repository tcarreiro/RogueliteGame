class_name LuaDragController extends Node
## Arrasta um componente por uma ou mais regiões (handles).
## Move o nó via offset_transform_position: o offset não mexe no layout do pai
## (CenterContainer, flow box...) e, com visual_only = false, a área de clique acompanha o visual.

signal drag_started
signal drag_ended(offset: Vector2)

var _component: LuaComponent
var _moving: Control
var _default_handle: Control
var _custom_handles: Array[Control] = []

var _enabled := false
var _mode: StringName = PropertyDefinition.HOLD
var _bounds: StringName = PropertyDefinition.VIEWPORT
var _hover_cursor: Control.CursorShape = Control.CURSOR_MOVE

var _connected: Dictionary = {}     # handle -> Callable (gui_input)
var _prev_cursor: Dictionary = {}   # handle -> cursor original

var _dragging := false
var _grab_mouse := Vector2.ZERO
var _grab_offset := Vector2.ZERO
var _prev_z := 0
var _stopped_frame := -1


func _ready() -> void:
	set_process_input(false)


func setup(component: LuaComponent, moving: Control, default_handle: Control) -> void:
	_component = component
	_moving = moving
	_default_handle = default_handle


func configure(enabled: bool, mode: StringName, bounds: StringName, cursor: Control.CursorShape) -> void:
	_enabled = enabled
	_mode = mode
	_bounds = bounds
	_hover_cursor = cursor
	if enabled:
		_moving.offset_transform_enabled = true
		_moving.offset_transform_visual_only = false   # a área de clique acompanha o visual
	else:
		_stop()
	_rebind()


## Handles declarados com drag_handle = true. Vazio = usa a região padrão do componente.
func set_handles(handles: Array[Control]) -> void:
	_custom_handles = handles
	_rebind()


func reset() -> void:
	_stop()
	_moving.offset_transform_position = Vector2.ZERO


#region Handles
func _rebind() -> void:
	var wanted: Array[Control] = []
	if _enabled:
		if not _custom_handles.is_empty():
			wanted.assign(_custom_handles)
		elif _default_handle != null:
			wanted.append(_default_handle)

	for handle in _connected.keys():
		if not is_instance_valid(handle) or not wanted.has(handle):
			_unbind(handle)
	for handle in wanted:
		if not is_instance_valid(handle):
			continue
		if not _connected.has(handle):
			_bind(handle)
		handle.mouse_default_cursor_shape = _hover_cursor


func _bind(handle: Control) -> void:
	if handle.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		push_warning("[LuaDragController] a região de arraste ignora o mouse (mouse_filter = IGNORE).")
	_prev_cursor[handle] = handle.mouse_default_cursor_shape
	var callback := _on_handle_input.bind(handle)
	_connected[handle] = callback
	handle.gui_input.connect(callback)


func _unbind(handle: Variant) -> void:
	var callback: Callable = _connected.get(handle, Callable())
	if is_instance_valid(handle):
		if callback.is_valid() and handle.gui_input.is_connected(callback):
			handle.gui_input.disconnect(callback)
		handle.mouse_default_cursor_shape = _prev_cursor.get(handle, Control.CURSOR_ARROW)
	_connected.erase(handle)
	_prev_cursor.erase(handle)
#endregion


#region Arraste
func _on_handle_input(event: InputEvent, _handle: Control) -> void:
	if not _enabled or _dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# o clique que acabou de soltar (toggle) não pode iniciar outro arraste no mesmo frame
		if Engine.get_process_frames() == _stopped_frame:
			return
		if _component.is_style_state_active(&"disabled"):
			return
		_start()


func _start() -> void:
	_dragging = true
	_grab_mouse = _moving.get_global_mouse_position()
	_grab_offset = _moving.offset_transform_position
	_prev_z = _moving.z_index
	_moving.z_index = _prev_z + 100   # por cima dos irmãos enquanto arrasta
	set_process_input(true)
	_set_active_cursor(true)
	drag_started.emit()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		if _mode == PropertyDefinition.HOLD and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_stop()   # soltou fora da janela do jogo
			return
		_update()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _mode == PropertyDefinition.HOLD and not event.pressed:
			_update()
			_stop()
		elif _mode == PropertyDefinition.TOGGLE and event.pressed:
			get_viewport().set_input_as_handled()
			_update()
			_stop()


func _update() -> void:
	var mouse := _moving.get_global_mouse_position()
	if _bounds == PropertyDefinition.VIEWPORT:
		var screen := get_viewport().get_visible_rect()
		mouse = mouse.clamp(screen.position, screen.end)
	var delta := mouse - _grab_mouse
	var parent := _moving.get_parent() as CanvasItem
	if parent != null:
		delta = parent.get_global_transform().affine_inverse().basis_xform(delta)
	_moving.offset_transform_position = _grab_offset + delta


func _stop() -> void:
	if not _dragging:
		return
	_dragging = false
	_stopped_frame = Engine.get_process_frames()
	_moving.z_index = _prev_z
	set_process_input(false)
	_set_active_cursor(false)
	drag_ended.emit(_moving.offset_transform_position)


func _set_active_cursor(active: bool) -> void:
	for handle in _connected.keys():
		if is_instance_valid(handle):
			handle.mouse_default_cursor_shape = Control.CURSOR_DRAG if active else _hover_cursor
#endregion
