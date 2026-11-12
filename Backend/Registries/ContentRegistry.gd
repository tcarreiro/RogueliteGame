class_name ContentRegistry extends Node

var type_name: StringName = &""
var requires_script: bool = false

var _definitions: Dictionary[StringName, ContentDefinition] = {}

#region Override
func _make_definition(_entry: Dictionary) -> ContentDefinition:
	push_error("[ContentRegistry] '%s' does not implement _make_definition" % type_name)
	return null
#endregion


#region Loading
# Should be called when changing active mods
func clear() -> void:
	_definitions.clear()


func load_entries(mod_id:StringName, mod_path: String, entries: Array, state: LuaState)-> void:
	for entry in entries:
		if not entry is Dictionary:
			GameLogger.error("[%s] entry that is not an object at '%s'."%[type_name, mod_id])
			continue
		var definition := _build_definition(entry, mod_id, mod_path, state)
		if definition != null:
			register(definition)


func _build_definition(entry: Dictionary, mod_id:StringName, mod_path: String, state: LuaState) -> ContentDefinition:
	if not entry.has("id"):
		GameLogger.error("[%s] entry with no 'id' at '%s'." % [type_name, mod_id])
		return null
	
	var id := StringName(entry["id"])
	if _definitions.has(id):
		GameLogger.warn("[%s] '%s' already defined." % [type_name, id])
		return null
	
	if requires_script and not entry.has("script_path"):
		GameLogger.error("[%s] '%s' has no 'script_path' at '%s'." % [type_name, id, mod_id])
		return null
	
	var hooks := _load_hooks(entry, id, mod_path, state)
	if hooks == null:
		return null
	
	if entry.has("icon_path"):
		var icon_path := mod_path.path_join(str(entry["icon_path"]))
		if not FileAccess.file_exists(icon_path):
			GameLogger.warn("[%s] icon not found for '%s' at '%s'." % [type_name, id, icon_path])
			return null
		entry["icon_path"] = icon_path
	
	var definition := _make_definition(entry)
	if definition == null:
		return null
	definition.connect_callables(hooks)
	return definition


func _load_hooks(entry: Dictionary, id: StringName, mod_path: String, state: LuaState) -> LuaTable:
	var env: Variant = state.do_string("return setmetatable({}, {__index = _G})")
	if not env is LuaTable:
		GameLogger.error("[%s] could not create a script environment for '%s': %s" % [type_name, id, env])
		return null

	if not entry.has("script_path"):
		return env

	var script_path := mod_path.path_join(str(entry["script_path"]))
	if not FileAccess.file_exists(script_path):
		GameLogger.warn("[%s] script not found for '%s' at '%s'." % [type_name, id, script_path])
		return null

	var result: Variant = state.do_file(script_path, LuaState.LOAD_MODE_ANY, env)
	if result is LuaError:
		GameLogger.error("[%s] error loading '%s': %s" % [type_name, script_path, result])
		return null
	return env
#endregion


#region Registry
func register(definition: ContentDefinition) -> void:
	if _definitions.has(definition.id):
		GameLogger.error("%s %s already registered." % [type_name.capitalize(), definition.id])
		return
	_definitions[definition.id] = definition
	GameLogger.debug("%s %s registered." % [type_name.capitalize(), definition.id])


func get_definition(id: StringName) -> ContentDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[ContentDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()
#endregion
