## Run test screen
extends Control

const LCSS_FILES := [
	"res://addons/lua-modder/UI/Styles/layout.lcss",
	"res://Tests/RunLcss/run_screen.lcss",
]
const LUA_FILE := [
	"res://Tests/RunLcss/Lua/confirm_dialog.lua",
	"res://Tests/RunLcss/Lua/run_screen.lua",
]

static var _assets_loaded := false

var _bridge: UiBridge
var _screen: LuaComponent

func _ready() -> void:
	LuaUi.set_root(self)
	_bridge = UiBridge.new()
	_bridge.attach()
	if not _assets_loaded:
		for file in LCSS_FILES:
			LuaUi.load_lcss(file)
		for file in LUA_FILE:
			if not LuaUi.load_file(file):
				GameLogger.error("[RunLuaTest] - Couldn't load lua file '%s'"%[file])
				return
		_assets_loaded = true
	_screen = ComponentRegistry.instantiate(ComponentRegistry.make_element("RunScreen", {})) as LuaComponent
	add_child(_screen)


func _exit_tree() -> void:
	_bridge.detach()
