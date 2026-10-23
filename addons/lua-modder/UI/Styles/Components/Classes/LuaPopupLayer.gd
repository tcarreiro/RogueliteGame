class_name LuaPopupLayer extends CanvasLayer
## Camada flutuante ancorada a um Control. Abre acima de tudo e fecha com clique fora ou Esc.

signal dismissed

const LAYER_INDEX := 128

var _anchor: Control
var _content: Control
var _gap := 2.0
var _closing := false


static func open(anchor: Control, content: Control, gap := 2.0) -> LuaPopupLayer:
	var popup := LuaPopupLayer.new()
	popup.layer = LAYER_INDEX
	popup._anchor = anchor
	popup._content = content
	popup._gap = gap
	anchor.get_tree().root.add_child(popup)
	return popup


func _ready() -> void:
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_catcher_input)
	add_child(catcher)
	add_child(_content)
	_anchor.tree_exiting.connect(close)
	_place.call_deferred()   # espera o layout do conteúdo assentar


## Abaixo da âncora, com a largura mínima dela. Inverte para cima se não couber.
func _place() -> void:
	if not is_instance_valid(_anchor) or not is_instance_valid(_content):
		return
	var rect := _anchor.get_global_rect()
	_content.custom_minimum_size.x = maxf(_content.custom_minimum_size.x, rect.size.x)
	_content.reset_size()
	var size := _content.size
	var screen := get_viewport().get_visible_rect().size
	var pos := Vector2(rect.position.x, rect.end.y + _gap)
	if pos.y + size.y > screen.y and rect.position.y - _gap - size.y >= 0.0:
		pos.y = rect.position.y - _gap - size.y
	pos.x = clampf(pos.x, 0.0, maxf(screen.x - size.x, 0.0))
	_content.position = pos


func _on_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	dismissed.emit()
	queue_free()
