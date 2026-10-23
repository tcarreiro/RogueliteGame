class_name StyleHelper extends RefCounted

static func strip_native_stylebox(control: Control, slots: Array[String]) -> void:
	var empty := StyleBoxEmpty.new()
	for slot in slots:
		control.add_theme_stylebox_override(slot, empty)
