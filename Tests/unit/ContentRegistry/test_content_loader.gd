extends GutTest
## ContentLoader: one content.json per mod, entries routed to the registry that owns their `type`.

const ROOT := "user://test_content_loader"


class StubModManager extends ModManager:
	var folders: Dictionary = {}

	func get_metadata(id: StringName) -> ModMetadata:
		if not folders.has(id):
			return null
		var metadata := ModMetadata.new()
		metadata.id = id
		metadata.folder_path = folders[id]
		return metadata


class ProbeDefinition extends ContentDefinition:
	var color: String

	func _init(entry: Dictionary = {}) -> void:
		id = StringName(entry.get("id", ""))
		color = str(entry.get("color", ""))


class AlphaRegistry extends ContentRegistry:
	func _init() -> void:
		type_name = &"alpha"

	func _make_definition(entry: Dictionary) -> ContentDefinition:
		return ProbeDefinition.new(entry)


class BetaRegistry extends ContentRegistry:
	func _init() -> void:
		type_name = &"beta"

	func _make_definition(entry: Dictionary) -> ContentDefinition:
		return ProbeDefinition.new(entry)


var _mods: StubModManager
var _alpha: AlphaRegistry
var _beta: BetaRegistry
var _loader: ContentLoader
var _bridge: ContentBridge
var _seq := 0


func before_each() -> void:
	_mods = autofree(StubModManager.new())
	_alpha = autofree(AlphaRegistry.new())
	_beta = autofree(BetaRegistry.new())
	_bridge = ContentBridge.new()
	var registries: Array[ContentRegistry] = [_alpha, _beta]
	_loader = ContentLoader.new(_mods, _bridge, registries)
	DirAccess.make_dir_recursive_absolute(ROOT)


func after_each() -> void:
	_remove_dir(ROOT)


func _remove_dir(path: String) -> void:
	for sub in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(sub))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


## Creates a mod folder with the given content.json text and returns its id (unique per call, since Lua
## states are registered globally by mod id).
func _make_mod(content_json: String = "") -> StringName:
	_seq += 1
	var id := StringName("loader_mod_%d_%d" % [Time.get_ticks_usec(), _seq])
	var folder := ROOT.path_join(str(id))
	DirAccess.make_dir_recursive_absolute(folder)
	if content_json != "":
		var file := FileAccess.open(folder.path_join(ContentLoader.CONTENT_FILE), FileAccess.WRITE)
		file.store_string(content_json)
		file.close()
	_mods.folders[id] = folder
	return id


func _ids(registry: ContentRegistry) -> Array:
	return registry.get_all_ids()


func test_routes_entries_to_the_registry_that_owns_their_type() -> void:
	var mod := _make_mod('[{"type":"alpha","id":"a1"},{"type":"beta","id":"b1"},{"type":"alpha","id":"a2"}]')
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1", &"a2"], "file order is kept inside each type")
	assert_eq(_ids(_beta), [&"b1"])


func test_same_id_may_exist_in_different_types() -> void:
	var mod := _make_mod('[{"type":"alpha","id":"x"},{"type":"beta","id":"x"}]')
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"x"])
	assert_eq(_ids(_beta), [&"x"])


func test_unknown_type_is_skipped_and_the_rest_still_loads() -> void:
	var mod := _make_mod('[{"type":"alpha","id":"a1"},{"type":"typo","id":"t1"},{"type":"beta","id":"b1"}]')
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1"])
	assert_eq(_ids(_beta), [&"b1"])


func test_entry_without_type_is_skipped() -> void:
	var mod := _make_mod('[{"id":"orphan"},{"type":"alpha","id":"a1"}]')
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1"])


func test_entry_that_is_not_an_object_is_skipped() -> void:
	var mod := _make_mod('["oops", 7, {"type":"alpha","id":"a1"}]')
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1"])


func test_mod_without_content_file_is_ignored() -> void:
	var mod := _make_mod()
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha).size(), 0)


func test_unknown_mod_is_ignored() -> void:
	_loader.load_mods([&"does_not_exist"])
	assert_eq(_ids(_alpha).size(), 0)


func test_invalid_json_loads_nothing_and_does_not_crash() -> void:
	var mod := _make_mod("{ not json")
	_loader.load_mods([mod])
	assert_engine_error("error != Error::OK")  # JSON.parse_string reports the syntax error itself
	assert_eq(_ids(_alpha).size(), 0)


func test_content_of_several_mods_is_merged_in_load_order() -> void:
	var first := _make_mod('[{"type":"alpha","id":"a1"}]')
	var second := _make_mod('[{"type":"alpha","id":"a2"}]')
	_loader.load_mods([first, second])
	assert_eq(_ids(_alpha), [&"a1", &"a2"])


func test_loading_again_replaces_instead_of_duplicating() -> void:
	var mod := _make_mod('[{"type":"alpha","id":"a1"}]')
	_loader.load_mods([mod])
	_loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1"])


func test_extra_fields_reach_the_definition() -> void:
	var mod := _make_mod('[{"type":"alpha","id":"a1","color":"red"}]')
	_loader.load_mods([mod])
	assert_eq((_alpha.get_definition(&"a1") as ProbeDefinition).color, "red")


func test_second_registry_for_the_same_type_is_ignored() -> void:
	var dup: AlphaRegistry = autofree(AlphaRegistry.new())
	var registries: Array[ContentRegistry] = [_alpha, dup]
	var loader := ContentLoader.new(_mods, _bridge, registries)
	var mod := _make_mod('[{"type":"alpha","id":"a1"}]')
	loader.load_mods([mod])
	assert_eq(_ids(_alpha), [&"a1"])
	assert_eq(_ids(dup).size(), 0)
