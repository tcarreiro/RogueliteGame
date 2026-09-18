class_name RunManager extends Node

signal run_started(config: RunConfig)
signal run_ended(success: bool)

var run_state: RunState

var event_manager: EventManager
var factor_manager: FactorManager

func _ready() -> void:
	# Initializing event manager
	event_manager = EventManager.new()
	_register_events()
	
	factor_manager = FactorManager.new()
	_register_factors()


func _register_factors() -> void:
	for id in FactorRegistry.get_all_ids():
		var factor = FactorRegistry.create_factor(id)
		factor_manager.register_factor(factor)


func _register_events() -> void:
	for id in EventRegistry.get_all_ids():
		var event := EventRegistry.create_event(id)
		var definition := EventRegistry.get_definition(id)
		event_manager.register_event(event, definition.throttle)


func _build_run_config() -> RunConfig:
	# TODO: RunEffects should influence RunConfig
	var config := RunConfig.new()
	config.run_id = "run_%d" % Time.get_unix_time_from_system()
	config.datashard_id = "datashard_%d" % Time.get_unix_time_from_system()
	return config


func start_run() -> void:
	var config := _build_run_config()
	run_state = RunState.new(config)
	run_started.emit(config)
	# TODO: to be removed
	factor_manager.mock("factor_resonance")

func end_run(success: bool) -> void:
	run_state.factor_levels = _snapshot_factor_levels()
	run_state.end(success)
	run_ended.emit(success)


func _process(delta: float) -> void:
	if not is_run_active():
		return
	run_state.elapsed_time += delta
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
