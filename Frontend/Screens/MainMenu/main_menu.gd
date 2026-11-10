class_name MainMenu extends Control

var _screen: LuaComponent

func _ready() -> void:
	LuaUi.set_root(self)
	LuaUi.release_drafts()
	_screen = ComponentRegistry.instantiate(ComponentRegistry.make_element("MainMenu", {})) as LuaComponent
	add_child(_screen)
