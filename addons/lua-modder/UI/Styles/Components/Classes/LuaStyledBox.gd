class_name LuaStyledBox extends LuaComponent
## Base de todo componente com wrapper visual: Margin > Background > Padding.

@onready var _margin: MarginContainer = %Margin
@onready var _background: PanelContainer = %Background
@onready var _padding: MarginContainer = %Padding


## Props de caixa para o get_schema() de quem herda:
##   var names: Array = [PropertyDefinition.GAP]
##   names.append_array(LuaStyledBox.box_names())
static func box_names() -> Array:
	var names: Array = []
	names.append_array(PropertyDefinition.BOX_SPACING)
	names.append_array(PropertyDefinition.PANEL)
	names.append_array(PropertyDefinition.TRANSITION)
	names.append_array(PropertyDefinition.TRANSFORM)
	names.append_array(PropertyDefinition.ANIMATION)
	return names


func _ready() -> void:
	_style_target.register_property(PropertyDefinition.MARGIN, _margin)
	_style_target.register_property(PropertyDefinition.PADDING, _padding)
	_style_target.register_group(PropertyDefinition.PANEL, _background)
	_style_target.register_group(PropertyDefinition.TRANSFORM, _background)
	_setup_style_target()
	_bind_style_state_source(_style_state_source())
	_background.gui_input.connect(_on_background_gui_input)
	super._ready()


## Nó que dispara hover/focus. Default = o próprio %Background.
func _style_state_source() -> Control:
	return _background


## Override point: registre aqui os alvos próprios do componente.
func _setup_style_target() -> void:
	pass


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_style_state_active(&"disabled"):
			return
		set_state(&"pressed", event.pressed)


static func strip_native_stylebox(control: Control, slots: Array[String]) -> void:
	var empty := StyleBoxEmpty.new()
	for slot in slots:
		control.add_theme_stylebox_override(slot, empty)


func _drag_target() -> Control:
	return self


func _drag_default_handle() -> Control:
	return _background


func _drag_handle_node() -> Control:
	return _background
