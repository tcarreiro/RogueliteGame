#GameManager
extends Node

const ALLOW_SAVE_ON_RUN = false

var mod_manager: ModManager
var run_manager: RunManager
var content_bridge: ContentBridge
var game_state: GameState

func _ready() -> void:
	content_bridge = ContentBridge.new()
	_setup_mods()
	_setup_run_manager()
	new_game() # TODO: Will eventually be moved to listen to a button on main menu screen


func new_game() -> void:
	game_state = GameState.new()
	equip_datashard("initial_datashard")


func load_game() -> void:
	SaveManager.current_save.load_into_game()


#region Mods
func _setup_mods():
	# create instance
	mod_manager = ModManager.new()
	
	# connect signals
	mod_manager.mods_discoreved.connect(
		func(mods:Array[ModMetadata]): for mod in mods: GameLogger.debug("%s found"%mod.id)) # TODO: show list
	mod_manager.active_mods_changed.connect(_on_active_mods_changed)
	
	# start activities
	mod_manager.discover_mods()
	mod_manager.set_active_mods()
	# TODO: eventually, mod_manager.set_active_mods(_load_player_mod_selection()) from some list


func _on_active_mods_changed(active_mod_ids: Array[StringName]) -> void:
	FactorRegistry.load_from_mods(active_mod_ids)
	EventRegistry.load_from_mods(active_mod_ids)
	RunEffectRegistry.load_from_mods(active_mod_ids)
	EquipmentRegistry.load_from_mods(active_mod_ids)
	DatashardRegistry.load_from_mods(active_mod_ids)

#endregion


#region Run
func _setup_run_manager() -> void:
	run_manager = RunManager.new()
	add_child(run_manager)
	run_manager.run_started.connect(on_run_started)
	run_manager.run_ended.connect(on_run_ended)


func on_run_started(config: RunConfig) -> void:
	GameLogger.info("Run %s started."%config.run_id)


func on_run_ended(success: bool) -> void:
	content_bridge.lua_clear_pending_actions()
	GameLogger.info("Run ended with result %s"%str(success))
#endregion


#region Façade, Getters and Setters
func get_run_state() -> RunState:
	return run_manager.run_state


func get_factor(factor_id: StringName) -> Factor:
	return run_manager.factor_manager.get_factor(factor_id)


func get_event(event_id: StringName) -> Event:
	return run_manager.event_manager.get_event(event_id)


func equip_datashard(datashard_id) -> void:
	game_state.choose_datashard(datashard_id)


func get_equipped_gauntlet() -> Gauntlet:
	return game_state.get_equipped_gauntlet()


func get_active_datashard() -> Datashard:
	return game_state.get_active_datashard()

#endregion
