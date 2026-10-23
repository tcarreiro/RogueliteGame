extends LuaComponent

@onready var _backdrop: PanelContainer = %Backdrop
@onready var _content_slot: MarginContainer = %ModalContent
@onready var _background: PanelContainer = %Background

const DEFAULT_BACKDROP_COLOR := Color(0, 0, 0, 0.25)

func get_schema() -> Dictionary:
	var names: Array = [
		PropertyDefinition.BLOCKING, PropertyDefinition.BACKDROP_COLOR, PropertyDefinition.MARGIN,
		PropertyDefinition.DROP_SHADOW_COLOR, PropertyDefinition.DROP_SHADOW_SIZE,
		PropertyDefinition.DROP_SHADOW_OFFSET,
	]
	names.append_array(LuaStyledBox.box_names())
	names.append_array(PropertyDefinition.DRAG_GRP)
	return {
		"name": "Modal",
		"props": PropertyDefinition.pick(names),
		"events": ["closed", "drag_started", "drag_ended"],
		"methods": ["close","reset_drag_position"],
		"slots": {"content": "%Background"},
	}


func _drag_target() -> Control:
	return _background   # o card visível (e a sombra dele); o CenterContainer não o reposiciona de volta


func _drag_default_handle() -> Control:
	return _background


func _ready() -> void:
	# contexto: no .lua/.lcss o nome é "backdrop_color"; o applier recebe BACKGROUND_COLOR
	_style_target.register_property(PropertyDefinition.BACKGROUND_COLOR, _backdrop, PropertyDefinition.BACKDROP_COLOR)
	_style_target.register_property(PropertyDefinition.MARGIN, _content_slot)
	_style_target.register_property(PropertyDefinition.DROP_SHADOW_COLOR, _background)
	_style_target.register_property(PropertyDefinition.DROP_SHADOW_SIZE, _background)
	_style_target.register_property(PropertyDefinition.DROP_SHADOW_OFFSET, _background)
	# default: um valor vindo do .lua ou do .lcss sobrescreve
	LCSSAppliers.apply(PropertyDefinition.BACKGROUND_COLOR, DEFAULT_BACKDROP_COLOR, _backdrop)
	super._ready()

func _component_ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _apply_prop(key: String, value: Variant) -> void:
	match StringName(key):
		PropertyDefinition.BLOCKING:
			_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		_:
			super._apply_prop(key, value)


func close() -> void:
	emit_event("closed")
	dispose()
