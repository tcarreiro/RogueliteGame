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

	GameLogger.error("[%s] invalid value '%s'. Fallback %s as default." % [context, raw, enum_dict.keys()[0]])
	return 0


static func _enum_key(enum_dict: Dictionary, value: int) -> String:
	for key in enum_dict:
		if enum_dict[key] == value:
			return key
	return str(value)
