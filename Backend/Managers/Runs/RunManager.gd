class_name RunManager extends Node

signal run_started(config: RunConfig)
signal run_ended(success: bool)
signal run_ticked(run_state: RunState)

var run_state: RunState

var event_manager: EventManager
var factor_manager: FactorManager
var equipment_manager: EquipmentManager
var run_loot_manager: LootManager

func _setup_managers() -> void:
	event_manager = EventManager.new()
	_register_events()
	
	factor_manager = FactorManager.new()
	_register_factors()
	
	equipment_manager = EquipmentManager.new()
	_connect_signals()
	_set_run_equipment()
	equipment_manager.connect_all_loot_run_signals() # TODO: will eventually go to _connect_signals()
	
	# TBD: Run inventory always starts empty?
	run_loot_manager = LootManager.new("run_loot")


func _set_run_equipment() -> void:
	# TODO: equipment will come from caller once HUB is done
	var gauntlet = EquipmentRegistry.create_equipment("gauntlet_bronze")
	gauntlet.add_effect("effect_addon_echo")
	equipment_manager.equip(0, gauntlet)


func _connect_signals() -> void:
	# TODO: signals
	equipment_manager.on_equip.connect(
		func(equipment: Equipment, _slot_id: int): GameLogger.info("Equipment %s equipped"%equipment.id))
	equipment_manager.on_unequip.connect(
		func(equipment: Equipment, _slot_id: int): GameLogger.info("Equipment %s unequipped"%equipment.id)) # TBD: ??


func _register_factors() -> void:
	for id in FactorRegistry.get_all_ids():
		var factor = FactorRegistry.create_factor(id) as Factor
		factor_manager.register_factor(factor)


func _register_events() -> void:
	for id in EventRegistry.get_all_ids():
		var event = EventRegistry.create_event(id) as Event
		event_manager.register_event(event, event.throttle)


func _build_run_config() -> RunConfig:
	# TODO: RunEffects should influence RunConfig
	var config := RunConfig.new()
	config.run_id = "run_%d" % Time.get_unix_time_from_system()
	config.datashard_id = "datashard_%d" % Time.get_unix_time_from_system()
	return config


func _apply_run_effects() -> void:
	for effect: RunEffect in equipment_manager.get_all_effects():
		effect.connect_run_start()


func start_run() -> void:
	_setup_managers()
	_apply_run_effects()
	var config := _build_run_config()
	run_state = RunState.new(config)
	run_started.emit(config)


func end_run(success: bool) -> void:
	run_state.factor_levels = _snapshot_factor_levels()
	run_state.end(success)
	run_ended.emit(success)


func _process(delta: float) -> void:
	if not is_run_active():
		return
	run_state.elapsed_time += delta
	run_ticked.emit(run_state)
	event_manager.process(delta)


func is_in_run() -> bool:
	return run_state != null


func is_run_active() -> bool:
	return is_in_run() and run_state.active


func _snapshot_factor_levels() -> Dictionary[StringName, int]:
	var snapshot: Dictionary[StringName, int] = {}
	for id in factor_manager.get_all_factor_ids():
		snapshot[id] = factor_manager.get_factor(id).current_level
	return snapshot
