class_name NumberInput extends LineEdit

@export var max_decimal_length: int = 0
@export var only_int:bool = false
#@export var max_value: float = 0.0

var old_text = ""
const separator:String= "."

func _ready():
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text: String):
	if new_text.is_empty() or new_text.is_valid_float() and _int_validation(new_text):
		if max_decimal_length > 0:
			if new_text.contains(separator):
				var decimal = new_text.split(separator)[1]
				if decimal.length() > max_decimal_length:
					_do_not_accept()
					return
		old_text = new_text
	else:
		_do_not_accept()

func _int_validation(_text: String) -> bool:
	return (only_int and _text.is_valid_int()) or not only_int

func _do_not_accept() -> void:
	text = old_text
	set_caret_column(old_text.length())  
