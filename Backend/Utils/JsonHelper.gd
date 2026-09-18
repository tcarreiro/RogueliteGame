class_name JsonHelper extends Node


## Lê e valida um .json esperado como array de objetos. Retorna [] em qualquer
## falha (arquivo ausente, JSON inválido, raiz que não é array), logando o motivo.
static func read_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir: %s" % path)
		return []

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("JSON inválido em: %s" % path)
		return []

	if not parsed is Array:
		push_error("Esperado um array em: %s" % path)
		return []

	return parsed
