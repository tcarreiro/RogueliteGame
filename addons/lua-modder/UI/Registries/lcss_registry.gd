class_name LCSSRegistry extends RefCounted

var _stylesheets: Array[LCSSStyleSheet] = []


func register(text: String) -> LCSSStyleSheet:
	# Parses lcss text into stylesheet and caches it
	var stylesheet := LCSSParser.parse(text)
	return register_stylesheet(stylesheet)


func register_file(path: String) -> LCSSStyleSheet:
	# Reads the file at 'path', extract its content and sends it to register()
	if not FileAccess.file_exists(path):
		push_error("[LCSSRegistry] arquivo não encontrado: '%s'" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("[LCSSRegistry] não foi possível abrir o arquivo: '%s'" % path)
		return null

	return register(file.get_as_text())


func register_stylesheet(stylesheet: LCSSStyleSheet) -> LCSSStyleSheet:
	if stylesheet == null:
		return
	_stylesheets.append(stylesheet)
	return stylesheet


func unregister(stylesheet: LCSSStyleSheet) -> void:
	_stylesheets.erase(stylesheet)


func clear() -> void:
	_stylesheets.clear()


func get_stylesheets() -> Array[LCSSStyleSheet]:
	return _stylesheets.duplicate()


func get_stylesheet_count() -> int:
	return _stylesheets.size()


# as of now, it returns the first found. What would happen if two
# equally named keyframes are registered?
func find_keyframes(anim_name: StringName) -> LCSSKeyframes:
	for i in range(get_stylesheet_count() - 1, -1, -1):
		var found: LCSSKeyframes = _stylesheets[i].get_keyframes().get(anim_name)
		if found != null:
			return found
	return null

# as of now, it returns the first found. What would happen if two
# equally named style classes are registered?
#func find_style_classes(style_class_name: StringName) -> LCSSStyleClass:
	#for i in range(get_stylesheet_count() - 1, -1, -1):
		#var found: Variant = _stylesheets[i].get_style_classes()
		#.find_custom(func(sc: LCSSStyleClass): return sc.token)
		#pass
	#return null
