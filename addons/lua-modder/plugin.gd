@tool
extends EditorPlugin

const AUTOLOAD_COMPONENT_REGISTRY_NAME := "ComponentRegistry"
const AUTOLOAD_COMPONENT_REGISTRY_PATH := "res://addons/lua-modder/UI/Registries/component_registry.gd"

const AUTOLOAD_LUA_UI_NAME := "LuaUi"
const AUTOLOAD_LUA_UI_PATH := "res://addons/lua-modder/UI/LuaUi.gd"

const AUTOLOAD_LUA_BRIDGE_NAME := "LuaBridgeRegistry"
const AUTOLOAD_LUA_BRIDGE_PATH := "res://addons/lua-modder/LuaBridgeRegistry.gd"

func _enter_tree() -> void:
	if not _check_dependencies():
		return

	add_autoload_singleton(AUTOLOAD_COMPONENT_REGISTRY_NAME, AUTOLOAD_COMPONENT_REGISTRY_PATH)
	add_autoload_singleton(AUTOLOAD_LUA_UI_NAME, AUTOLOAD_LUA_UI_PATH)
	add_autoload_singleton(AUTOLOAD_LUA_BRIDGE_NAME, AUTOLOAD_LUA_BRIDGE_PATH)


func _exit_tree() -> void:
	if ClassDB.class_exists("LuaState"):
		remove_autoload_singleton(AUTOLOAD_COMPONENT_REGISTRY_NAME)
		remove_autoload_singleton(AUTOLOAD_LUA_UI_NAME)
		remove_autoload_singleton(AUTOLOAD_LUA_BRIDGE_NAME)


func _check_dependencies() -> bool:
	if not ClassDB.class_exists("LuaState"):
		push_error(
			"[Lua UI Builder] Dependência ausente: o addon 'lua-gdextension' "
			+ "precisa estar instalado e ativado antes deste addon. "
			+ "Veja: https://github.com/gilzoide/lua-gdextension"
		)
		return false
	return true
