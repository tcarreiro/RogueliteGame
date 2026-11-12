class_name ContentUiBridge extends RefCounted
## The base game is a mod like any other, so what is allowed here is allowed to every mod.
##
## It is a facade over the ONE UI runtime (LuaUi + ComponentRegistry), so content never gets a second UI
## and only reaches what register() lists. Left out on purpose: UI.goToScene and UI.quit.
##
## From a content script:
##
##   UI.defineComponent("LootPanel", { props = { title = "string" }, render = function(p) ... end })
##   UI.mount("InventoryModal", { store = "chest_1", title = "Chest", windowed = true })
##   local button = UI.getComponent("Button", { label = "Take all", on_pressed = function() ... end })
##   UI.mount("Modal", { ref = "loot", children = { button } })
##   UI.callMethod("inventory_modal:chest_1", "close")
##
## UI.defineComponent never replaces a component that already exists: it reports who owns the name and
## returns false (the first definition always wins), so a mod cannot override a game component or another
## mod's. `render` runs in the content state, so inside it use UI.getComponent(...) to build the tree.
##
## Callbacks written in content run in the content state and are called by the UI (they cross states as
## Callables). Every function validates what a script hands it and reports a bad call with the mod id,
## instead of letting the UI runtime fail in the middle of a frame.

const UI_NAMESPACE := "UI"

static var _owners: Dictionary[StringName, StringName] = {}


## Adds the `UI` global to a mod's content state. `mod_id` is only used to say who made a bad call.
static func register(state_name: StringName, mod_id: StringName) -> void:
	var define_component := func(component: Variant = null, definition: Variant = null) -> bool:
		return _define_component(mod_id, component, definition)
	var mount := func(component: Variant = null, props: Variant = null) -> Variant:
		return _mount(mod_id, component, props)
	var get_component := func(component: Variant = null, props: Variant = null) -> Variant:
		return _to_element(mod_id, "getComponent", component, props)
	var call_method := func(ref: Variant = null, method: Variant = null, args: Variant = null) -> Variant:
		return _call_method(mod_id, ref, method, args)
	var store := func(store_name: Variant = null) -> Variant:
		return _store(mod_id, store_name)
	var bind := func(deps: Variant = null, source: Variant = null) -> Variant:
		return LuaUi._lua_bind(deps, source)

	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"defineComponent", define_component)
	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"mount", mount)
	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"getComponent", get_component)
	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"callMethod", call_method)
	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"store", store)
	LuaBridgeRegistry.lua_register(state_name, UI_NAMESPACE, &"bind", bind)


#region API
## UI.defineComponent(name, definition) -> true when defined, false when refused (and why is logged).
static func _define_component(mod_id: StringName, component: Variant, definition: Variant) -> bool:
	if not _is_text(component) or str(component) == "":
		_report(mod_id, "defineComponent", "expected a component name.")
		return false
	var component_name := str(component)
	if component_name in ComponentRegistry.get_names():
		var definer: StringName = _owners.get(StringName(component_name), &"")
		var by := "mod '%s'" % definer if definer != &"" else "the game UI"
		_report(mod_id, "defineComponent", "component '%s' already exists (defined by %s), not replaced." % [component_name, by])
		return false
	if not (definition is LuaTable or definition is Dictionary):
		_report(mod_id, "defineComponent", "the definition of '%s' must be a table." % component_name)
		return false
	var definition_dict := LuaHelper.as_dict(definition)
	var render: Variant = definition_dict.get("render")
	if not (render is LuaFunction or render is Callable):
		_report(mod_id, "defineComponent", "'%s' needs a `render` function." % component_name)
		return false
	if not ComponentRegistry.register_lua(component_name, definition_dict):
		return false
	_owners[StringName(component_name)] = mod_id
	return true


## UI.mount(name, props) or UI.mount(element). Returns the element's ref ("" when it has none).
static func _mount(mod_id: StringName, component: Variant, props: Variant) -> Variant:
	var element := _to_element(mod_id, "mount", component, props)
	if element == null:
		return null
	LuaUi._lua_mount(element)
	return element.ref


## A registered component name plus props becomes an element; an element made by UI.getComponent passes through.
static func _to_element(mod_id: StringName, function_name: String, component: Variant, props: Variant) -> UIElement:
	if component is UIElement:
		return component
	if not _is_text(component):
		_report(mod_id, function_name, "expected a component name or an element, got %s." % type_string(typeof(component)))
		return null
	var component_name := str(component)
	if not component_name in ComponentRegistry.get_names():
		_report(mod_id, function_name, "unknown component '%s'." % component_name)
		return null
	if props != null and not (props is LuaTable or props is Dictionary):
		_report(mod_id, function_name, "props of '%s' must be a table." % component_name)
		return null
	return ComponentRegistry.make_element(component_name, LuaHelper.as_dict(props))


static func _call_method(mod_id: StringName, ref: Variant, method: Variant, args: Variant) -> Variant:
	if not _is_text(ref) or not _is_text(method):
		_report(mod_id, "callMethod", "expected a ref and a method name.")
		return null
	if ComponentRegistry.get_ref(str(ref)) == null:
		_report(mod_id, "callMethod", "no mounted component with ref '%s'." % ref)
		return null
	return LuaUi._lua_call_method(ref, method, args)


static func _store(mod_id: StringName, store_name: Variant) -> Variant:
	if not _is_text(store_name):
		_report(mod_id, "store", "expected a store name.")
		return null
	if LuaUi.get_store(str(store_name)) == null:
		_report(mod_id, "store", "store '%s' is not exposed to the UI." % store_name)
		return null
	return LuaUi._lua_store(store_name)
#endregion


static func _is_text(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


static func _report(mod_id: StringName, function_name: String, message: String) -> void:
	GameLogger.error("[ContentUi:%s] UI.%s: %s" % [mod_id, function_name, message])
