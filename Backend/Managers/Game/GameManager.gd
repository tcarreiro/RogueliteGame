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
	EffectRegistry.load_from_mods(active_mod_ids)
	DatashardRegistry.load_from_mods(active_mod_ids)
	AddonRegistry.load_from_mods(active_mod_ids)
	EquipmentRegistry.load_from_mods(active_mod_ids)
	CardRegistry.load_from_mods(active_mod_ids)

#endregion


#region Run
func _setup_run_manager() -> void:
	run_manager = RunManager.new()
	add_child(run_manager)
	run_manager.run_started.connect(on_run_started)
	run_manager.run_ended.connect(on_run_ended)
	# TODO: set


func on_run_started() -> void:
	GameLogger.info("Run started.")


func on_run_ended(success: bool) -> void:
	content_bridge.lua_clear_pending_actions()
	GameLogger.info("Run ended with result %s"%str(success))
#endregion


#region Façade, Getters and Setters
func get_run_state() -> RunState:
	return run_manager.run_state


func get_factor_manager() -> FactorManager:
	return get_run_state().factor_manager


func get_event_manager() -> EventManager:
	return get_run_state().event_manager


func get_equipment_manager() -> EquipmentManager:
	return get_run_state().equipment_manager


func get_factor(factor_id: StringName) -> Factor:
	return get_factor_manager().get_factor(factor_id)


func get_event(event_id: StringName) -> Event:
	return get_event_manager().get_event(event_id)


func equip_datashard(datashard_id) -> void:
	game_state.choose_datashard(datashard_id)


func equip_gauntlet(gauntlet: Gauntlet) -> void:
	game_state.choose_gauntlet(gauntlet)


func get_equipped_gauntlet() -> Gauntlet:
	return game_state.get_equipped_gauntlet()


func get_active_datashard() -> Datashard:
	return game_state.get_active_datashard()


func get_unlocked_datashards() -> Array[Datashard]:
	return game_state.unlocked_datashards.values()


func get_available_gauntlets() -> Array[Gauntlet]:
	return game_state.get_available_gauntlets()


func get_active_effects() -> Array[Effect]:
	return game_state.get_active_effects()


func get_permanent_deck() -> Array[Card]:
	return game_state.get_permanent_deck()


func get_active_deck() -> Array[Card]:
	return game_state.get_active_deck()


func activate_card(card: Card) -> bool:
	return game_state.activate_card(card)


func deactivate_card(card: Card) -> bool:
	return game_state.deactivate_card(card)


func get_active_card_pile() -> CardPile:
	return game_state.get_active_card_pile()

#endregion
