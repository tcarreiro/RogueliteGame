class_name ModManager extends RefCounted

signal mods_discoreved(mods: Array[ModMetadata])
signal active_mods_changed(active_mod_ids: Array[StringName])

const BUILTIN_MODS_PATH := "res://mods/"
const USERS_MODS_PATH := "user://data/user/mods/"

const MOD_METADATA_FILENAME := "manifest.json"

var _discovered: Dictionary[StringName, ModMetadata] = {}
var _active_ids: Array[StringName] = []

func discover_mods() -> void:
	_discovered.clear()
	_scan_folder(BUILTIN_MODS_PATH)
	_scan_folder(USERS_MODS_PATH)
	mods_discoreved.emit(_discovered.values())


func _scan_folder(base_path: String) -> void:
	var dir := DirAccess.open(base_path)
	if not dir:
		return
	dir.list_dir_begin()
	var folder_name := dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			_try_load_metadata(base_path.path_join(folder_name))
		folder_name = dir.get_next()
	dir.list_dir_end()


func _try_load_metadata(mod_folder:String) -> void:
	var metadata_path := mod_folder.path_join(MOD_METADATA_FILENAME)
	if not FileAccess.file_exists(metadata_path):
		GameLogger.error("%s file missing."%MOD_METADATA_FILENAME)
		return
	
	var metadata := _parse_metadata(metadata_path)
	if not metadata:
		GameLogger.error("Not valid mod metadata found.")
		return
	metadata.folder_path = mod_folder
	_discovered[metadata.id] = metadata


func _parse_metadata(path: String) -> ModMetadata:
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if not file or json.parse(file.get_as_text()) != OK:
		return null
	
	var data: Dictionary = json.data
	var metadata := ModMetadata.new()
	
	metadata.id = StringName(data.get("id", ""))
	if metadata.id == "":
		GameLogger.error("Invalid mod ID.")
		return null
	
	metadata.display_name = StringName(data.get("display_name", metadata.id))
	metadata.version = data.get("version", "1.0.0")
	metadata.author = data.get("author", "")
	metadata.description = data.get("description", "")
	metadata.is_base_mod = path.contains(BUILTIN_MODS_PATH)
	metadata.load_order = data.get("load_order", 0)
	
	var deps: Array = data.get("dependencies", [])
	metadata.dependencies.assign(deps.map(func(d): return StringName(d)))
	
	return metadata


func get_discovered_mods() -> Array[ModMetadata]:
	return _discovered.values()


func get_metadata(id: StringName) -> ModMetadata:
	return _discovered.get(id)


func set_active_mods(requested_ids: Array[StringName] = []) -> void:
	_active_ids = _resolve_load_order(requested_ids)
	active_mods_changed.emit(_active_ids)


func get_active_mods() -> Array[StringName]:
	return _active_ids.duplicate()


func _resolve_load_order(requested_ids: Array[StringName]) -> Array[StringName]:
	var to_load: Dictionary[StringName, bool] = {}
	
	# Mod base mandatory. FUTURE: DLCs?
	for metadata in get_discovered_mods():
		if metadata.is_base_mod:
			to_load[metadata.id] = true
	
	for id in requested_ids:
		_mark_with_dependencies(id, to_load)
	
	var result: Array[StringName] = to_load.keys()
	result.sort_custom(func(a,b):
		var order_a = _discovered[a].load_order if _discovered.has(a) else 0
		var order_b = _discovered[b].load_order if _discovered.has(b) else 0
		return order_a < order_b
	)
	return result


func _mark_with_dependencies(id: StringName, to_load: Dictionary) ->  void:
	if to_load.has(id) or not _discovered.has(id):
		return
	to_load[id] = true
	for dep_id in _discovered[id].dependencies:
		_mark_with_dependencies(dep_id, to_load)
