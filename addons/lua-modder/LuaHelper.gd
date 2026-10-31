class_name LuaHelper extends RefCounted

static var error_hook: Callable = Callable()

static func call_by_name(lua_state: LuaState, function_name: String, args: Array = []):
	var fn = lua_state.globals[function_name]
	if not (fn is LuaFunction):
		push_error("[Lua] '%s' function not found." % function_name)
		return null

	var result = fn.invoke.callv(args)
	if result is LuaError:
		push_error("[Lua] error trying to execute '%s': %s" % [function_name, result])
		return null

	return result


static func report_error(context: String, error: LuaError) -> void:
	var where := context if context != "" else "função Lua"
	push_error("[Lua] %s: %s" % [where, error.message])
	if error_hook.is_valid():
		error_hook.call(where, str(error.message))


static func make_callable(value, context := "") -> Callable:
	if value is Callable:
		return value

	if value is LuaFunction:
		return func(...args):
			var r = value.invoke.callv(args)
			if r is LuaError:
				report_error(context, r)
				return null
			return r

	if value != null:
		push_warning("[LuaHelper] %s: lua function expected. Instead, %s" % [context if context != "" else "callback", type_string(typeof(value))])
	return Callable()


static func as_dict(value) -> Dictionary:
	var v = normalize_lua(value)
	return v if v is Dictionary else {}


static func normalize_lua(value):
	if value is LuaTable:
		var as_array: Array = value.to_array()
		if as_array.size() > 0:
			var arr := []
			for v in as_array:
				arr.append(normalize_lua(v))
			return arr
		var as_dict: Dictionary = value.to_dictionary()
		var dict := {}
		for k in as_dict:
			dict[k] = normalize_lua(as_dict[k])
		return dict
	if value is Dictionary:
		var dict := {}
		for k in value:
			dict[k] = normalize_lua(value[k])
		return dict
	if value is Array:
		var arr := []
		for v in value:
			arr.append(normalize_lua(v))
		return arr
	return value


#region Lua Value Convertion
static func parse_color(value) -> Color:
	if value is Color:
		return value

	if value is String:
		return Color(value)

	if value is Array and value.size() >= 3:
		var alpha := 1.0

		if value.size() > 3:
			alpha = float(value[3])
		return Color(float(value[0]), float(value[1]), float(value[2]), alpha)

	return Color.WHITE


static func parse_padding(value) -> Array:
	if value == null:
		return [0.0, 0.0, 0.0, 0.0]

	if value is int or value is float:
		var v := float(value)
		return [v, v, v, v]

	if value is Array:
		if value.size() == 2:
			var h := float(value[0])
			var v := float(value[1])
			return [h, v, h, v]

		if value.size() == 4:
			return [float(value[0]), float(value[1]), float(value[2]), float(value[3])]

	push_warning("[LuaUiFactory] padding inválido: %s" % str(value))
	return [0.0, 0.0, 0.0, 0.0]


static func parse_distributable(_val) -> Array:
	var value = _val
	if _val is LCSSProperty:
		value = _val.value
	
	if value == null:
		return [0.0, 0.0, 0.0, 0.0]

	if value is int or value is float:
		var v := float(value)
		return [v, v, v, v]

	if value is Array:
		if value.size() == 2:
			var h := float(value[0])
			var v := float(value[1])
			return [h, v, h, v]

		if value.size() == 4:
			return [float(value[0]), float(value[1]), float(value[2]), float(value[3])]

	push_warning("[LuaUiFactory] padding inválido: %s" % str(value))
	return [0.0, 0.0, 0.0, 0.0]


## Opções do Lua: lista de textos ou de { value, label, disabled } -> [{ value, label, disabled }]
static func parse_options(raw: Variant) -> Array:
	var out: Array = []
	if not raw is Array:
		return out
	for item in raw:
		if item is Dictionary:
			var value: Variant = item.get("value", item.get("label", ""))
			out.append({"value": value, "label": str(item.get("label", value)), "disabled": bool(item.get("disabled", false))})
		else:
			out.append({"value": item, "label": str(item), "disabled": false})
	return out


static func same_value(a: Variant, b: Variant) -> bool:
	return str(a) == str(b)


static func parse_style_classes(value) -> Array[StringName]:
	var out: Array[StringName] = []
	if value is String:
		for part in value.split(" ", false):
			out.append(StringName(part))
	elif value is Array:
		for v in value:
			out.append(StringName(str(v)))
	return out


static func coerce_value(current_value, new_value):
	if (current_value is Vector2 and new_value is Array and new_value.size() >= 2):
		return Vector2(float(new_value[0]), float(new_value[1]))

	if current_value is Color:
		return parse_color(new_value)

	if current_value is bool:
		return bool(new_value)

	if current_value is int:
		return int(new_value)

	if current_value is float:
		return float(new_value)

	return new_value
#endregion
