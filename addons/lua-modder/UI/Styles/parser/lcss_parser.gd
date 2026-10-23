class_name LCSSParser extends RefCounted


static func parse(text: String) -> LCSSStyleSheet:
	var stylesheet := LCSSStyleSheet.new()
	text = _extract_comments(stylesheet, text)
	var position := 0

	while position < text.length():
		var open_brace := text.find(LCSS.BRACKET_OPENER, position)
		if open_brace == -1:
			break

		var raw_selector := text.substr(position, open_brace - position)
		var selector := raw_selector.strip_edges()
		var close_brace := _find_matching_brace(text, open_brace)
		if close_brace == -1:
			push_error("[LCSSParser] bloco não fechado para '%s'" % selector)
			break

		if not selector.is_empty():
			var start := position + raw_selector.length() - raw_selector.lstrip(" \t\r\n").length()
			var value := text.substr(start, close_brace - start + LCSS.BRACKET_CLOSER.length())
			if selector.begins_with(LCSS.KEYFRAMES_OPENER):
				var token := LCSSToken.new(LCSS.KEYFRAMES, start, close_brace, value)
				stylesheet.add_keyframes(LCSSKeyframes.new(stylesheet, token))
			elif selector.begins_with(LCSS.STYLE_CLASS_OPENER):
				var token := LCSSToken.new(LCSS.STYLE_CLASS, start, close_brace, value)
				var style_class := LCSSStyleClass.new(stylesheet, token)
				if not style_class.selectors.is_empty():   # seletor inválido: já avisado, regra ignorada
					stylesheet.add_style_class(style_class)
		position = close_brace + 1

	return stylesheet


static func parse_keyframes(keyframe: LCSSKeyframes) -> LCSSKeyframes:
	var body := keyframe.token.value
	var first_brace := body.find(LCSS.BRACKET_OPENER)
	if first_brace == -1:
		push_error("[LCSSKeyframes] Invalid format")
		return keyframe
	keyframe.name = body.substr(0, first_brace).replace(LCSS.KEYFRAMES_OPENER, "").strip_edges()

	var pos := first_brace + LCSS.BRACKET_OPENER.length()
	while pos < body.length():
		var open := body.find(LCSS.BRACKET_OPENER, pos)
		if open == -1:
			break
		var close := _find_matching_brace(body, open)
		if close == -1:
			break

		var props := _parse_properties(body.substr(open + 1, close - open - 1))
		for raw in body.substr(pos, open - pos).split(",", false):
			var key := raw.strip_edges()
			var offset := -1.0
			if key == LCSS.FROM:
				offset = 0.0
			elif key == LCSS.TO:
				offset = 1.0
			elif key.ends_with("%") and key.trim_suffix("%").is_valid_float():
				offset = clampf(key.trim_suffix("%").to_float() / 100.0, 0.0, 1.0)
			if offset >= 0.0:
				keyframe.add_frame(offset, props)
		pos = close + 1
	return keyframe


static func parse_style_class(style_class: LCSSStyleClass) -> LCSSStyleClass:
	var body := style_class.token.value
	var first_brace := body.find(LCSS.BRACKET_OPENER)
	if first_brace == -1:
		push_error("[LCSSStyleClass] Invalid format")
		return style_class

	for selector in _parse_selector_chain(body.substr(0, first_brace)):
		style_class.add_style_selector(selector)
	if style_class.selectors.is_empty():
		return style_class

	var close := _find_matching_brace(body, first_brace)
	if close == -1:
		push_error("[LCSSStyleClass] bloco não fechado")
		return style_class
	for property: LCSSProperty in _parse_properties(body.substr(first_brace + 1, close - first_brace - 1)).values():
		style_class.add_property(property)
	return style_class


#region Selectors
## Seletor -> cadeia de trechos separados por espaço (descendente). Dentro de um trecho,
## .classe e :estado colados exigem o MESMO componente. Seletor inválido devolve cadeia
## vazia (a regra é ignorada), em vez de um trecho vazio que casaria com qualquer componente.
static func _parse_selector_chain(selector_text: String) -> Array[LCSSStyleClass.LCSSStyleSelector]:
	var chain: Array[LCSSStyleClass.LCSSStyleSelector] = []
	var text := selector_text.strip_edges()
	if text.contains(","):
		push_warning("[LCSSParser] vírgula em seletor ainda não é suportada, regra ignorada: '%s' (escreva uma regra por seletor)" % text)
		return chain
	for ws in ["\n", "\r", "\t"]:
		text = text.replace(ws, " ")

	for raw_part in text.split(" ", false):
		var part := _parse_compound(raw_part)
		if part == null:
			push_warning("[LCSSParser] seletor inválido, regra ignorada: '%s'" % selector_text.strip_edges())
			chain.clear()
			return chain
		chain.append(part)
	return chain


static func _parse_compound(raw: String) -> LCSSStyleClass.LCSSStyleSelector:
	var selector := LCSSStyleClass.LCSSStyleSelector.new()
	var remaining := raw
	while not remaining.is_empty():
		var opener := remaining[0]
		if opener != LCSS.STYLE_CLASS_OPENER and opener != LCSS.STATE_OPENER:
			push_warning("[LCSSParser] token inesperado em '%s': '%s' (só .classe e :estado)" % [raw, remaining])
			return null
		var end := _find_token_end(remaining, 1)
		var token_name := remaining.substr(1, end - 1)
		if token_name.is_empty():
			return null
		if opener == LCSS.STYLE_CLASS_OPENER:
			selector.classes.append(StringName(token_name))
		else:
			selector.states.append(StringName(token_name))
		remaining = remaining.substr(end)

	if selector.states.size() > 1:
		push_warning("[LCSSParser] '%s': só o primeiro estado (:%s) é usado" % [raw, selector.states[0]])
	return selector


static func _find_token_end(value: String, start: int) -> int:
	var index := start
	while index < value.length():
		var c := value[index]
		if c == LCSS.STYLE_CLASS_OPENER or c == LCSS.STATE_OPENER:
			break
		index += 1
	return index
#endregion


#region Comments
## Uma varredura só: registra os comentários no stylesheet (para o editor) e devolve o texto com
## cada comentário trocado por espaços do mesmo tamanho, então as posições continuam valendo.
## Chaves e ponto e vírgula dentro de comentários deixam de atrapalhar o resto do parser.
## Aspas são respeitadas: texture('res://x.png') não vira comentário.
static func _extract_comments(stylesheet: LCSSStyleSheet, text: String) -> String:
	var out := ""
	var quote := ""
	var i := 0
	while i < text.length():
		var c := text[i]
		if quote != "":
			out += c
			if c == quote:
				quote = ""
			i += 1
			continue
		if c == "'" or c == '"':
			quote = c
			out += c
			i += 1
			continue

		var is_block := text.substr(i, 2) == LCSS.MULTI_LINE_COMMENT_OPENER
		var is_line := text.substr(i, 2) == LCSS.SINGLE_LINE_COMMENT
		if not is_block and not is_line:
			out += c
			i += 1
			continue

		var end: int
		if is_block:
			var close := text.find(LCSS.MULTI_LINE_COMMENT_CLOSER, i + 2)
			end = text.length() - 1 if close == -1 else close + LCSS.MULTI_LINE_COMMENT_CLOSER.length() - 1
		else:
			var newline := text.find("\n", i)
			end = text.length() - 1 if newline == -1 else newline - 1
		stylesheet.add_comment(LCSSToken.new(LCSS.COMMENT, i, end, text.substr(i, end - i + 1)))
		for j in range(i, end + 1):
			out += "\n" if text[j] == "\n" else " "
		i = end + 1
	return out
#endregion


static func _find_matching_brace(text: String, open_brace: int) -> int:
	var depth := 0
	for i in range(open_brace, text.length()):
		match text[i]:
			LCSS.BRACKET_OPENER:
				depth += 1
			LCSS.BRACKET_CLOSER:
				depth -= 1
				if depth == 0:
					return i
	return -1


#region Properties and values (iguais aos seus)
static func _parse_properties(body: String) -> Dictionary[StringName, LCSSProperty]:
	var properties: Dictionary[StringName, LCSSProperty] = {}

	for declaration in body.split(LCSS.PROPERTY_CLOSER):
		declaration = declaration.strip_edges()
		if declaration.is_empty():
			continue

		var separator := declaration.find(LCSS.PROPERTY_SEPARATOR)
		if separator == -1:
			push_warning("[LCSSParser] declaração sem ':' ignorada: '%s'" % declaration)
			continue

		var name := declaration.substr(0, separator).strip_edges()
		var raw_value := declaration.substr(separator + 1).strip_edges()
		if name.is_empty():
			continue
		properties[StringName(name)] = LCSSProperty.new(name, _parse_value(raw_value))
	return properties


static func _parse_value(value: String) -> Variant:
	if value.is_empty():
		return null
	if value.is_valid_int():
		return value.to_int()
	if value.is_valid_float():
		return value.to_float()
	if value.ends_with("ms") and value.trim_suffix("ms").is_valid_float():
		return value.trim_suffix("ms").to_float() / 1000.0
	if value.ends_with("s") and value.trim_suffix("s").is_valid_float():
		return value.trim_suffix("s").to_float()
	if value.begins_with("[") and value.ends_with("]"):
		return _parse_array(value)
	if value.ends_with(")") and value.find("(") > 0:
		return _parse_call(value)
	var tokens := value.split(" ", false)   # "5 4" / "5 2 1 3"
	if tokens.size() > 1:
		var numbers: Array = []
		for t in tokens:
			if not (t.is_valid_int() or t.is_valid_float()):
				return value
			numbers.append(_parse_value(t))
		return numbers
	return value


static func _parse_call(value: String) -> Variant:
	var open := value.find("(")
	var fn_name := value.substr(0, open).strip_edges()
	var inner := value.substr(open + 1, value.length() - open - 2).strip_edges()
	var args: Array = []
	for raw in inner.split(","):
		args.append(_strip_quotes(raw.strip_edges()))

	match fn_name:
		PropertyDefinition.TEXTURE_FN, PropertyDefinition.URL_FN:
			if args.is_empty() or str(args[0]) == "":
				push_warning("[LCSSParser] %s() sem caminho" % fn_name)
				return null
			return args[0]
		_:
			push_warning("[LCSSParser] função desconhecida: '%s'" % fn_name)
			return value


static func _parse_array(value: String) -> Array:
	var content := value.substr(1, value.length() - 2).strip_edges()
	if content.is_empty():
		return []
	var result: Array = []
	for item in content.split(","):
		result.append(_parse_value(item.strip_edges()))
	return result


static func _strip_quotes(s: String) -> String:
	if s.length() >= 2 and (s[0] == '"' or s[0] == "'") and s[s.length() - 1] == s[0]:
		return s.substr(1, s.length() - 2)
	return s
#endregion
