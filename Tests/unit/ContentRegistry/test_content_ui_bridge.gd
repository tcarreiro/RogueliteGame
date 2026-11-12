extends GutTest
## ContentUiBridge: the `UI` global that content scripts get, over the real UI runtime.

var _state: LuaState
var _root: Control
var _seq := 0


func before_each() -> void:
	_seq += 1
	var mod_id := StringName("ui_test_%d_%d" % [Time.get_ticks_usec(), _seq])
	_state = ContentBridge.new().get_or_create_mod_state(mod_id, &"ui")
	_root = add_child_autofree(Control.new())
	LuaUi.set_root(_root)


func after_each() -> void:
	LuaUi.set_root(null)


func _run(code: String) -> Variant:
	return _state.do_string(code)


func _unique(prefix: String) -> String:
	_seq += 1
	return "%s_%d_%d" % [prefix, Time.get_ticks_usec(), _seq]

#region Surface
func test_content_state_gets_exactly_the_allowed_ui_functions() -> void:
	var names = _run("local n = {} for k in pairs(UI) do n[#n + 1] = k end table.sort(n) return table.concat(n, ',')")
	assert_eq(names, "bind,callMethod,defineComponent,getComponent,mount,store")


func test_scene_and_quit_functions_are_not_reachable_from_content() -> void:
	assert_true(_run("return UI.goToScene == nil and UI.quit == nil"))


func test_dangerous_ui_functions_are_not_reachable_from_content() -> void:
	assert_true(_run("return UI.goToScene == nil and UI.quit == nil and UI.defineComponent == nil"))


func test_every_mod_state_gets_its_own_ui_table() -> void:
	var other: LuaState = ContentBridge.new().get_or_create_mod_state(&"ui_test_other_%d" % Time.get_ticks_usec(), &"ui")
	assert_ne(other, _state)
	assert_true(other.do_string("return UI ~= nil and UI.mount ~= nil"))
#endregion


#region Elements
func test_get_component_returns_an_element() -> void:
	var element = _run("return UI.getComponent('Label', { text = 'hi' })")
	assert_true(element is UIElement)
	assert_eq((element as UIElement).component_name, "Label")
	assert_eq(_root.get_child_count(), 0, "getComponent only describes, it does not mount")


func test_elements_compose_into_children() -> void:
	var element: UIElement = _run("""
		return UI.getComponent('Div', { children = {
			UI.getComponent('Label', { text = 'a' }),
			UI.getComponent('Label', { text = 'b' }),
		} })
	""")
	assert_eq(element.slots["default"].size(), 2)


func test_callbacks_written_in_content_run_in_the_content_state() -> void:
	_run("calls = 0")
	var element: UIElement = _run("""
		return UI.getComponent('Button', { label = 'x', on_pressed = function() calls = calls + 1; return 'from content' end })
	""")
	var handler: Callable = element.handlers["on_pressed"]
	assert_true(handler.is_valid())
	assert_eq(handler.call(), "from content")
	assert_eq(_run("return calls"), 1)
#endregion


#region Mounting
func test_mount_adds_the_component_to_the_ui_root() -> void:
	_run("UI.mount('Label', { text = 'hi' })")
	assert_eq(_root.get_child_count(), 1)


func test_mount_accepts_an_element_made_by_get_component() -> void:
	_run("UI.mount(UI.getComponent('Label', { text = 'hi' }))")
	assert_eq(_root.get_child_count(), 1)


func test_mount_returns_the_ref_of_the_element() -> void:
	assert_eq(_run("return UI.mount('Label', { ref = 'my_label', text = 'hi' })"), "my_label")


func test_invalid_calls_are_ignored_and_the_script_keeps_running() -> void:
	var survived = _run("""
		UI.mount()
		UI.mount(123)
		UI.mount('NoSuchComponent')
		UI.mount('Label', 5)
		UI.getComponent('NoSuchComponent')
		UI.callMethod('no_such_ref', 'close')
		UI.callMethod(nil, nil)
		UI.store('no_such_store')
		return 'alive'
	""")
	assert_eq(survived, "alive")
	assert_eq(_root.get_child_count(), 0)
#endregion


#region Defining components
func test_content_can_define_and_mount_a_component() -> void:
	var component := _unique("ModBox")
	_run("renders = 0")
	var defined = _run("""
		return UI.defineComponent('%s', {
			props = { title = 'string' },
			render = function(p) renders = renders + 1; return UI.getComponent('Label', { text = p.title }) end,
		})
	""" % component)
	assert_true(defined)
	assert_true(component in ComponentRegistry.get_names())
	_run("UI.mount('%s', { title = 'hi' })" % component)
	assert_eq(_root.get_child_count(), 1)
	assert_eq(_run("return renders"), 1, "the render function ran in the content state")


func test_a_game_component_cannot_be_redefined_from_content() -> void:
	var count_before := ComponentRegistry.get_names().size()
	var defined = _run("return UI.defineComponent('Button', { render = function() return UI.getComponent('Div') end })")
	assert_false(defined)
	assert_eq(ComponentRegistry.get_names().size(), count_before)
	_run("UI.mount('Button', { label = 'still the original' })")
	assert_eq(_root.get_child_count(), 1, "Button still works")


func test_a_component_defined_by_one_mod_is_not_replaced_by_another() -> void:
	var component := _unique("Shared")
	var other: LuaState = ContentBridge.new().get_or_create_mod_state(StringName(_unique("ui_other")), &"ui")
	_run("first = 0")
	other.do_string("second = 0")
	assert_true(_run("return UI.defineComponent('%s', { render = function() first = first + 1; return UI.getComponent('Div') end })" % component))
	assert_false(other.do_string("return UI.defineComponent('%s', { render = function() second = second + 1; return UI.getComponent('Div') end })" % component))
	_run("UI.mount('%s')" % component)
	assert_eq(_run("return first"), 1, "the first definition is the one in use")
	assert_eq(other.do_string("return second"), 0, "the second never ran")


func test_any_mod_can_mount_a_component_another_mod_defined() -> void:
	var component := _unique("Public")
	var other: LuaState = ContentBridge.new().get_or_create_mod_state(StringName(_unique("ui_other")), &"ui")
	_run("UI.defineComponent('%s', { render = function() return UI.getComponent('Div') end })" % component)
	other.do_string("UI.mount('%s')" % component)
	assert_eq(_root.get_child_count(), 1)


func test_invalid_definitions_are_refused_and_the_script_keeps_running() -> void:
	var no_render := _unique("NoRender")
	var bad_render := _unique("BadRender")
	var all_refused = _run("""
		local a = UI.defineComponent(nil, { render = function() end })
		local b = UI.defineComponent('', { render = function() end })
		local c = UI.defineComponent('%s', 5)
		local d = UI.defineComponent('%s', {})
		local e = UI.defineComponent('%s', { render = 'not a function' })
		return not (a or b or c or d or e)
	""" % [_unique("NotATable"), no_render, bad_render])
	assert_true(all_refused)
	assert_false(no_render in ComponentRegistry.get_names())
	assert_false(bad_render in ComponentRegistry.get_names())
#endregion


#region Stores
func test_store_and_bind_work_for_exposed_stores() -> void:
	LuaUi.expose_store("ui_test_store", ReactiveDictionary.new({"count": 3}), true)
	var binding = _run("return UI.bind(UI.store('ui_test_store'), 'count')")
	assert_true(binding is LuaBinding)
	assert_eq((binding as LuaBinding).evaluate(), 3)


func test_bind_accepts_a_function_written_in_content() -> void:
	LuaUi.expose_store("ui_test_store2", ReactiveDictionary.new({"count": 4}), true)
	var binding = _run("""
		local s = UI.store('ui_test_store2')
		return UI.bind(s, function() return s.count end)
	""")
	assert_true(binding is LuaBinding)
#endregion


#region The goal: a content script opens a container's modal
func test_content_script_opens_and_closes_a_container_modal() -> void:
	var chest := ItemContainer.new(null, 12)
	chest.add(MockTestUtils.create_loot(&"herb", 10))
	var bridge := ItemContainerBridge.new(chest, "chest_ui_test", 12)
	bridge.attach()

	_run("UI.mount('InventoryModal', { ref = 'chest_ui_test_modal', store = 'chest_ui_test', title = 'Chest', windowed = true })")
	assert_eq(_root.get_child_count(), 1, "the modal is mounted")

	_run("UI.callMethod('inventory_modal:chest_ui_test', 'close')")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_root.get_child_count(), 0, "the script closed it through its ref")
	bridge.detach()
#endregion
