extends Node

const LCSS_FILES := [
	"res://addons/lua-modder/UI/Styles/layout.lcss",
	"res://Frontend/Screens/LCSS/Styles/global.lcss",
	"res://Frontend/Screens/LCSS/Styles/inventory.lcss",
]

const LUA_FILES := [
	"res://Frontend/Screens/LCSS/confirm_dialog.lua",
	"res://Frontend/Screens/LCSS/main_menu.lua",
	"res://Frontend/Screens/LCSS/settings.lua",
	"res://Frontend/Screens/LCSS/pause_menu.lua",
	"res://Frontend/Screens/LCSS/inventory_modal.lua",
	"res://Frontend/Screens/LCSS/__tests__/game_screen.lua",
]

static var _base_assets_loaded := false

static var scenes := {
	"main_menu": preload("res://Frontend/Screens/MainMenu/MainMenu.tscn"),
	"game_scene": preload("res://Frontend/Screens/Game/Game.tscn"),
}

var graphics_settings := ReactiveDictionary.new({
	"resolution_options": [
		"1280x720", "1920x1080", "2560x1440"
	],
	"resolution": "1920x1080",
	"vsync": true,
	"shadow_quality_options": [
		{value = 0, label = "LOWEST"}, {value = 1, label = "LOW"}, { value = 2, label = "MEDIUM"}, { value = 3, label = "HIGH"}, { value = 4, label = "ULTRA"}
	],
	"shadow_quality": 2,
	"ssao_quality_options": [
		{value = 0, label = "LOWEST"}, {value = 1, label = "LOW"}, { value = 2, label = "MEDIUM"}, { value = 3, label = "HIGH"}, { value = 4, label = "ULTRA"}
	],
	"ssao_quality": 3,
	"ssil_quality_options": [
		{value = 0, label = "LOWEST"}, {value = 1, label = "LOW"}, { value = 2, label = "MEDIUM"}, { value = 3, label = "HIGH"}, { value = 4, label = "ULTRA"}
	],
	"ssil_quality": 3,
	"anti_aliasing_options": [
		{value = 0, label = "OFF"}, {value = 1, label = "2x"}, { value = 2, label = "4x"}, { value = 3, label = "8x"}
	],
	"anti_aliasing": 3,
})

var audio_settings := ReactiveDictionary.new({
	"volume": 100,
})

var controls_settings := ReactiveDictionary.new({
	"toggle_inventory": "ui_inventory",
	"close_modal": "ui_cancel",
	"toggle_context_menu": "ui_cancel",
})

func _ready() -> void:
	# Expose stores
	LuaUi.expose_store("graphics", graphics_settings)
	LuaUi.expose_store("audio", audio_settings)
	LuaUi.expose_store("controls", controls_settings)
	LuaUi.expose_store("local_store", ReactiveDictionary.new({}))
	
	# load base mod
	_load_base_assets()
	
	# Connect stores reactivity
	_on_graphics_settings_changed(graphics_settings)
	_on_audio_settings_changed(audio_settings)
	_on_controls_settings_changed(controls_settings)
	graphics_settings.reactive_changed.connect(_on_graphics_settings_changed)
	audio_settings.reactive_changed.connect(_on_audio_settings_changed)
	controls_settings.reactive_changed.connect(_on_controls_settings_changed)


func _load_base_assets() -> void:
	if not _base_assets_loaded:
		for file in LCSS_FILES:
			LuaUi.load_lcss(file)
		for file in LUA_FILES:
			if not LuaUi.load_file(file):
				GameLogger.error("[Configuration] - Couldn't load lua file '%s'"%[file])
				return
		_base_assets_loaded = true


func _on_graphics_settings_changed(_reactive: Reactive) -> void:
	# Vsync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if graphics_settings.get_at("vsync", false) else DisplayServer.VSYNC_DISABLED)
	
	# Resolution
	var parts := str(graphics_settings.get_at("resolution")).split("x")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		var resolution := str(graphics_settings.get_at("resolution")).split("x")
		if resolution.size() == 2:
			var target_size := Vector2i(
				resolution[0].to_int(),
				resolution[1].to_int()
			)
			get_tree().root.content_scale_size = target_size
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_size(target_size)
			await get_tree().process_frame
	
	# Shadow
	_on_shadow_quality_change(graphics_settings)
	_on_ssao_quality_change(graphics_settings)
	_on_ssil_quality_change(graphics_settings)
	_on_anti_aliasing_change(graphics_settings)


func _on_shadow_quality_change(_reactive: Reactive)-> void:
	var shadow_quality = _reactive.get_at("shadow_quality")
	var shadow_quality_options = _reactive.get_at("shadow_quality_options")
	if shadow_quality == null or shadow_quality_options == null:
		return
	for options in shadow_quality_options:
		if shadow_quality == options.value:
			ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", shadow_quality + 1)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", shadow_quality + 1)


func _on_ssao_quality_change(_reactive: Reactive)-> void:
	var ssao_quality = _reactive.get_at("ssao_quality")
	var ssao_quality_options = _reactive.get_at("ssao_quality_options") as Array
	if ssao_quality == null or ssao_quality_options == null:
		return
	for options in ssao_quality_options:
		if ssao_quality == options.value:
			ProjectSettings.set_setting("rendering/environment/ssao/quality", ssao_quality)
			ProjectSettings.set_setting("rendering/environment/ssao/half_size", ssao_quality==ssao_quality_options.size())


func _on_ssil_quality_change(_reactive: Reactive)-> void:
	var ssil_quality = _reactive.get_at("ssil_quality")
	var ssil_quality_options = _reactive.get_at("ssil_quality_options")
	if ssil_quality == null or ssil_quality_options == null:
		return
	for options in ssil_quality_options:
		if ssil_quality == options.value:
			ProjectSettings.set_setting("rendering/environment/ssil/quality", ssil_quality)
			ProjectSettings.set_setting("rendering/environment/ssil/half_size", ssil_quality==ssil_quality_options.size())


func _on_anti_aliasing_change(_reactive: Reactive)-> void:
	var anti_aliasing = _reactive.get_at("anti_aliasing")
	var anti_aliasing_options = _reactive.get_at("anti_aliasing_options")
	if anti_aliasing == null or anti_aliasing_options == null:
		return
	for options in anti_aliasing_options:
		if anti_aliasing == options.value:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", anti_aliasing)


func _on_audio_settings_changed(_reactive: Reactive) -> void:
	# Audio
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(audio_settings.get_at("volume")) / 100.0, 0.0, 1.0)))


func _on_controls_settings_changed(_reactive: Reactive) -> void:
	# Controls
	pass


func goto_scene(scene_name:StringName) -> void:
	if not scenes.has(scene_name):
		GameLogger.error("'%s' scene not found."%scene_name)
		return
	get_tree().change_scene_to_packed(scenes[scene_name])
