class_name Utils extends Node


## Lê e valida um .json esperado como array de objetos. Retorna [] em qualquer
## falha (arquivo ausente, JSON inválido, raiz que não é array), logando o motivo.
static func read_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		GameLogger.error("Não foi possível abrir: %s" % path)
		return []

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		GameLogger.error("JSON inválido em: %s" % path)
		return []

	if not parsed is Array:
		GameLogger.error("Esperado um array em: %s" % path)
		return []

	return parsed


static func parse_string_into_enum(enum_dict: Dictionary, raw: String, context: String) -> int:
	var key := raw.to_upper()
	if enum_dict.has(key):
		return enum_dict[key]

	GameLogger.warn("[%s] invalid value '%s'. Fallback %s as default." % [context, raw, enum_dict.keys()[0]])
	return 0


static func _enum_key(enum_dict: Dictionary, value: int) -> String:
	for key in enum_dict:
		if enum_dict[key] == value:
			return key
	return str(value)


static func format_timer(time: float) -> String:
	var total_seconds := int(time)

	var hours := int(total_seconds / 3600.0)
	var minutes := int((total_seconds % 3600) / 60.0)
	var seconds := total_seconds % 60

	return "%02d:%02d:%02d" % [hours, minutes, seconds]


static func clear_connections(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		if sig.is_connected(callable):
			sig.disconnect(callable)


static func ensure_disconnected(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


static func ensure_connected(sig: Signal, callable: Callable, flags: int = 0) -> void:
	if sig.is_connected(callable):
		return
	sig.connect(callable, flags)
