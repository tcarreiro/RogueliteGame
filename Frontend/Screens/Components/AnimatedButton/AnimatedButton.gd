class_name AnimatedButton extends Button

@export_category("Button")
@export var normal_color: Color
@export var hover_color: Color
@export var pressed_color: Color

@export_category("Label")
@export var font_size: int = 16
@export var label_normal_color: Color
@export var label_hover_color: Color
@export var label_pressed_color: Color

@onready var content_container: MarginContainer = %ContentContainer
@onready var label: Label = %Label

func _ready() -> void:
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	pressed.connect(_on_click)
	_setup()

func _setup() -> void:
	_setup_label()
	_setup_themes()

func _setup_themes()->void:
	add_theme_stylebox_override("normal", _make_style(normal_color))
	add_theme_stylebox_override("focus", _make_style(hover_color))
	add_theme_stylebox_override("hover", _make_style(hover_color))
	add_theme_stylebox_override("pressed", _make_style(pressed_color))
	add_theme_stylebox_override("hover_pressed", _make_style(pressed_color))
	
func _setup_label() -> void:
	label.add_theme_color_override("font_color", label_normal_color)
	
	if not font_size: font_size = 16
	label.add_theme_font_size_override("font_size", clampi(font_size, 1, font_size))
	custom_minimum_size = content_container.get_combined_minimum_size()

func _on_hover_entered() -> void:
	label.add_theme_color_override("font_color", label_hover_color)

func _on_hover_exited() -> void:
	label.add_theme_color_override("font_color", label_normal_color)

func _on_click() -> void:
	label.add_theme_color_override("font_color", label_pressed_color)

func _set_text(msg: String) -> void:
	label.text = msg

func _make_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	return sb
