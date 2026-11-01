class_name MainMenu extends Control
## Projeto consumidor de teste: carrega os .lua e o .lcss da pasta, mantém as settings
## reativas e troca de tela destruindo os componentes antigos e criando os novos.

# TODO: Move to Autoload with all LCSS and Lua files
const LCSS_FILES := [
	"res://addons/lua-modder/UI/Styles/layout.lcss",
	"res://Frontend/Screens/LCSS/Styles/global.lcss"
]
const LUA_FILES := [
	"res://Frontend/Screens/LCSS/confirm_dialog.lua",
	"res://Frontend/Screens/LCSS/main_menu.lua",
	"res://Frontend/Screens/LCSS/settings.lua",
]

@export_file("*.tscn") var play_scene: String = ""

# TODO: Move to Autoload
var settings := ReactiveDictionary.new({
	"resolution_options": [
		"1280x720", "1920x1080", "2560x1440"
	],
	"resolution": "1920x1080",
	"vsync": true,
	"volume": 80,
	"quality_options": [
		{ value = 1, label = "LOW" }, { value = 2, label = "MEDIUM" }, { value = 3, label = "HIGH" }
	],
	"quality": 1,
})

static var _assets_loaded := false

var _screen: LuaComponent

func _ready() -> void:
	LuaUi.set_root(self)
	LuaUi.expose_store("settings", settings)
	if not _assets_loaded:
		for file in LCSS_FILES:
			LuaUi.load_lcss(file)
		for file in LUA_FILES:
			if not LuaUi.load_file(file):
				GameLogger.error("[MainMenu] - Couldn't load lua file '%s'"%[file])
				return
		_assets_loaded = true
		settings.reactive_changed.connect(_on_settings_changed)
	show_screen("MainMenu")


func show_screen(component_name: String) -> void:
	if is_instance_valid(_screen):
		_screen.dispose()
		_screen = null
	LuaUi.release_drafts()
	var el := ComponentRegistry.make_element(component_name, {"on_navigate": Callable(self, "_on_navigate")})
	_screen = ComponentRegistry.instantiate(el) as LuaComponent
	add_child(_screen)


func _on_navigate(target: Variant) -> void:
	# TODO: Add transition
	# TODO: Move "show_screen" to a helper and expose to Lua
	match str(target):
		"main_menu": show_screen("MainMenu")
		"settings": show_screen("Settings")
		"play": _play()
		"quit": get_tree().quit()
		_: push_warning("[Screens] Screen not found: '%s'" % target)


func _play() -> void:
	# TODO: Save slots first
	if play_scene == "":
		push_warning("[Screens] No Play Scene defined.")
		return
	get_tree().change_scene_to_file(play_scene)


# TODO: move to Autoload
func _on_settings_changed(_reactive: Reactive) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.get_at("vsync", false) else DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(settings.get_at("volume")) / 100.0, 0.0, 1.0)))
	var parts := str(settings.get_at("resolution")).split("x")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		var resolution := str(settings.get_at("resolution")).split("x")
		if resolution.size() == 2:
			var target_size := Vector2i(
				resolution[0].to_int(),
				resolution[1].to_int()
			)
			get_tree().root.content_scale_size = target_size
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_size(target_size)
			await get_tree().process_frame
