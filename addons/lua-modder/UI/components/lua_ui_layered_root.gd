class_name LuaUiLayeredRoot extends Control

var _measured_content: Control = null

func set_measured_content(content: Control) -> void:
	_measured_content = content
	if content != null and not content.minimum_size_changed.is_connected(_on_content_min_size_changed):
		content.minimum_size_changed.connect(_on_content_min_size_changed)

func _on_content_min_size_changed() -> void:
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	if _measured_content != null and is_instance_valid(_measured_content):
		return _measured_content.get_combined_minimum_size()
	return Vector2.ZERO
