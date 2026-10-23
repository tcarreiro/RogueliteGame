class_name ReactiveDictionary extends Reactive

signal key_changed(key: Variant, value: Variant)

var value: Dictionary:
	set(v):
		value = v
		reactive_changed.emit(self)


func _init(initial_value: Dictionary = {}, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


func has(key: Variant) -> bool:
	return value.has(key)


func get_at(key: Variant, default: Variant = null) -> Variant:
	return value.get(key, default)


func set_at(key: Variant, v: Variant) -> void:
	if value.has(key) and value[key] == v:
		return   # sem mudança, sem emissão
	value[key] = v
	key_changed.emit(key, v)
	reactive_changed.emit(self)


func erase(key: Variant) -> void:
	if value.erase(key):
		reactive_changed.emit(self)


## Substitui o conteúdo por uma cópia. Emite uma vez só.
func assign(dict: Dictionary) -> void:
	value = dict.duplicate(true)


func clear() -> void:
	value.clear()
	reactive_changed.emit(self)
