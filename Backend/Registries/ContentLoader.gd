class_name ContentLoader extends RefCounted

const CONTENT_FILE := "content.json"

var _mod_manager: ModManager
var _content_bridge: ContentBridge
var _registries: Dictionary[StringName, ContentRegistry] = {}

func _init(mod_manager: ModManager, content_bridge: ContentBridge, registries: Array[ContentRegistry]) -> void:
	_mod_manager = mod_manager
	_content_bridge = content_bridge
	for registry in registries:
		if registry.type_name == &"":
			GameLogger.error("[ContentLoader] registry '%s' has no type_name." % registry.name)
		elif _registries.has(registry.type_name):
			GameLogger.error("[ContentLoader] type '%s' is already handled by another registry." % registry.type_name)
		else:
			_registries[registry.type_name] = registry


func load_mods(active_mods: Array[StringName]) -> void:
	for registry in _registries.values():
		registry.clear()
	for mod_id in active_mods:
		_load_mod(mod_id)


func _load_mod(mod_id: StringName) -> void:
	var metadata := _mod_manager.get_metadata(mod_id)
	if not metadata:
		return

	var content_path := metadata.folder_path.path_join(CONTENT_FILE)
	if not FileAccess.file_exists(content_path):
		GameLogger.debug("[ContentLoader] mod '%s' has no %s." % [mod_id, CONTENT_FILE])
		return

	var by_type := _group_by_type(Utils.read_json_array(content_path), mod_id)
	for type_name in by_type:
		var state := _content_bridge.get_or_create_mod_state(mod_id, type_name)
		_registries[type_name].load_entries(mod_id, metadata.folder_path, by_type[type_name], state)


func _group_by_type(entries: Array, mod_id: StringName) -> Dictionary[StringName, Array]:
	var by_type: Dictionary[StringName, Array] = {}
	for index in entries.size():
		var entry: Variant = entries[index]
		if not entry is Dictionary:
			GameLogger.error("[ContentLoader] '%s': entry #%d is not an object." % [mod_id, index])
			continue

		var label := str(entry.get("id", "#%d" % index))
		var type_name := StringName(str(entry.get("type", "")))
		if type_name == &"":
			GameLogger.error("[ContentLoader] '%s': entry '%s' has no 'type'." % [mod_id, label])
		elif not _registries.has(type_name):
			GameLogger.error("[ContentLoader] '%s': entry '%s' has unknown type '%s' (known: %s)." % [
					mod_id, label, type_name, ", ".join(_registries.keys())])
		else:
			if not by_type.has(type_name):
				by_type[type_name] = []
			by_type[type_name].append(entry)
	return by_type
