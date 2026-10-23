class_name LCSSStyleSheet extends RefCounted

var _style_classes: Array[LCSSStyleClass] = []
var _keyframes: Dictionary[StringName, LCSSKeyframes] = {}
var _comments: Array[LCSSToken] = []


func add_style_class(style_class: LCSSStyleClass) -> void:
	_style_classes.append(style_class)


func add_keyframes(frames: LCSSKeyframes) -> void:
	_keyframes[frames.name] = frames


func add_comment(comment: LCSSToken) -> void:
	_comments.append(comment)


func get_style_classes() -> Array[LCSSStyleClass]:
	return _style_classes


func get_comments() -> Array[LCSSToken]:
	return _comments

func get_keyframes() ->  Dictionary[StringName, LCSSKeyframes]:
	return _keyframes

func _to_string() -> String:
	return "LCSSStyleSheet(style_classes=%s, keyframes=%s, comments=%s)" % [
		_style_classes, _keyframes, _comments
	]
