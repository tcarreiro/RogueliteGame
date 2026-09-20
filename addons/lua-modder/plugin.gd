@tool
extends EditorPlugin

const AUTOLOAD_LUA_BRIDGE_NAME := "LuaBridgeRegistry"
const AUTOLOAD_LUA_BRIDGE_PATH := "res://addons/lua-modder/lua_bridge_registry.gd"

func _enter_tree() -> void:
	if not _check_dependencies():
		return
	if not ProjectSettings.has_setting("autoload/%s"%AUTOLOAD_LUA_BRIDGE_NAME):
		add_autoload_singleton(AUTOLOAD_LUA_BRIDGE_NAME, AUTOLOAD_LUA_BRIDGE_PATH)


func _exit_tree() -> void:
	if ProjectSettings.has_setting("autoload/%s"%AUTOLOAD_LUA_BRIDGE_NAME):
		remove_autoload_singleton(AUTOLOAD_LUA_BRIDGE_NAME)


func _check_dependencies() -> bool:
	if not ClassDB.class_exists("LuaState"):
		push_error(
			"[Lua UI Builder] Dependência ausente: o addon 'lua-gdextension' "
			+ "precisa estar instalado e ativado antes deste addon. "
			+ "Veja: https://github.com/gilzoide/lua-gdextension"
		)
		return false
	if not ProjectSettings.get_setting("autoload/GdssRuntime"):
		push_error(
			"[GDSS] Dependência ausente: o addon 'gdss' "
			+ "precisa estar instalado e ativado antes deste addon. "
			+ "Veja: https://github.com/cruglet/gdss"
		)
		return false
	return true
