extends GutTest

const MOD_DIR := "user://test_content_registry"
const MOD_ID := &"test_mod"


class TestDefinition extends ContentDefinition:
	var on_equip: Callable
	var on_run_start: Callable
	var icon_path: String

	func _init(entry: Dictionary = {}) -> void:
		id = StringName(entry.get("id", ""))
		icon_path = entry.get("icon_path", "")

	func connect_callables(hooks: LuaTable) -> void:
		on_equip = LuaHelper.make_callable(hooks.rawget("onEquip"))
		on_run_start = LuaHelper.make_callable(hooks.rawget("onRunStart"))


class TestRegistry extends ContentRegistry:
	func _init() -> void:
		type_name = &"test"

	func _make_definition(entry: Dictionary) -> ContentDefinition:
		return TestDefinition.new(entry)


var _registry: TestRegistry
var _state: LuaState


func before_each() -> void:
	_registry = autofree(TestRegistry.new())
	_state = LuaState.new()
	_state.open_libraries(LuaState.LUA_BASE)
	DirAccess.make_dir_recursive_absolute(MOD_DIR)


func after_each() -> void:
	_remove_dir(MOD_DIR)


func _write(relative_path: String, text: String) -> void:
	var path := MOD_DIR.path_join(relative_path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove_dir(path: String) -> void:
	for sub in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(sub))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _load(entries: Array) -> void:
	_registry.load_entries(MOD_ID, MOD_DIR, entries, _state)


func _def(id: StringName) -> TestDefinition:
	return _registry.get_definition(id) as TestDefinition


#region Registering
func test_registers_entry_without_script() -> void:
	_load([{"id": "a"}])
	assert_not_null(_def(&"a"))
	assert_eq(_registry.get_all_ids(), [&"a"] as Array[StringName])


func test_keeps_file_order() -> void:
	_load([{"id": "c"}, {"id": "a"}, {"id": "b"}])
	assert_eq(_registry.get_all_ids(), [&"c", &"a", &"b"] as Array[StringName])


func test_rejects_entry_without_id() -> void:
	_load([{"display_name": "no id"}])
	assert_eq(_registry.get_all_ids().size(), 0)


func test_rejects_duplicate_id_and_keeps_the_first() -> void:
	_write("a1.lua", "function onEquip() end")
	_write("a2.lua", "function onRunStart() end")
	_load([{"id": "a", "script_path": "a1.lua"}, {"id": "a", "script_path": "a2.lua"}])
	assert_eq(_registry.get_all_ids().size(), 1)
	assert_true(_def(&"a").on_equip.is_valid(), "the first definition is the one kept")
	assert_false(_def(&"a").on_run_start.is_valid())


func test_ignores_entries_that_are_not_objects() -> void:
	_load(["oops", 3, {"id": "ok"}])
	assert_eq(_registry.get_all_ids(), [&"ok"] as Array[StringName])


func test_clear_forgets_everything() -> void:
	_load([{"id": "a"}])
	_registry.clear()
	assert_eq(_registry.get_all_ids().size(), 0)
	assert_null(_registry.get_definition(&"a"))
#endregion


#region Scripts
func test_requires_script_rejects_entry_without_script_path() -> void:
	_registry.requires_script = true
	_load([{"id": "a"}])
	assert_eq(_registry.get_all_ids().size(), 0)


func test_optional_script_is_accepted_by_default() -> void:
	_load([{"id": "a"}])
	assert_not_null(_def(&"a"))


func test_rejects_entry_whose_script_file_is_missing() -> void:
	_load([{"id": "a", "script_path": "nope.lua"}])
	assert_eq(_registry.get_all_ids().size(), 0)


func test_rejects_entry_whose_script_has_an_error() -> void:
	_write("bad.lua", "this is not lua")
	_load([{"id": "bad", "script_path": "bad.lua"}, {"id": "ok"}])
	assert_eq(_registry.get_all_ids(), [&"ok"] as Array[StringName], "one bad script must not stop the others")


func test_hooks_are_read_from_the_script() -> void:
	_write("a.lua", "function onEquip() return 'a' end")
	_load([{"id": "a", "script_path": "a.lua"}])
	var definition := _def(&"a")
	assert_true(definition.on_equip.is_valid())
	assert_false(definition.on_run_start.is_valid(), "a hook the script does not define stays unset")
	assert_eq(definition.on_equip.call(), "a")


func test_script_functions_do_not_leak_into_the_shared_globals() -> void:
	_write("a.lua", "function onEquip() end")
	_load([{"id": "a", "script_path": "a.lua"}])
	assert_null(_state.globals["onEquip"])


func test_hooks_do_not_leak_between_entries_of_the_same_state() -> void:
	## The original bug: both scripts ran in the same Lua globals, so an entry that did not define a hook
	## inherited the one from whichever script had defined it last.
	_write("a.lua", "function onEquip() return 'a' end")
	_write("b.lua", "function onRunStart() return 'b' end")
	_load([{"id": "a", "script_path": "a.lua"}, {"id": "b", "script_path": "b.lua"}, {"id": "c"}])
	assert_false(_def(&"b").on_equip.is_valid(), "b must not inherit a's onEquip")
	assert_false(_def(&"a").on_run_start.is_valid())
	assert_false(_def(&"c").on_equip.is_valid(), "an entry with no script has no hooks at all")
	assert_false(_def(&"c").on_run_start.is_valid())


func test_same_function_name_in_two_scripts_keeps_each_own_behaviour() -> void:
	_write("a.lua", "function onEquip() return 'a' end")
	_write("b.lua", "function onEquip() return 'b' end")
	_load([{"id": "a", "script_path": "a.lua"}, {"id": "b", "script_path": "b.lua"}])
	assert_eq(_def(&"a").on_equip.call(), "a")
	assert_eq(_def(&"b").on_equip.call(), "b")


func test_scripts_still_reach_the_shared_globals() -> void:
	_state.globals["Shared"] = "from the host"
	_write("a.lua", "function onEquip() return Shared end")
	_load([{"id": "a", "script_path": "a.lua"}])
	assert_eq(_def(&"a").on_equip.call(), "from the host")
#endregion


#region Icons
func test_icon_path_is_resolved_against_the_mod_folder() -> void:
	_write("icons/a.png", "x")
	_load([{"id": "a", "icon_path": "icons/a.png"}])
	assert_eq(_def(&"a").icon_path, MOD_DIR.path_join("icons/a.png"))


func test_rejects_entry_whose_icon_is_missing() -> void:
	_load([{"id": "a", "icon_path": "icons/missing.png"}])
	assert_eq(_registry.get_all_ids().size(), 0)
#endregion
