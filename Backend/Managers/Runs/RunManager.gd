class_name RunManager extends Node

signal run_started()
signal run_ended(success: bool)
signal run_ticked(run_state: RunState)

var run_state: RunState
var last_run: RunState

var _speed_multiplier: int = 1
var _max_speed_multiplier: int = 10

func start_run() -> void:
	run_state = RunState.new()
	run_state.setup_managers()
	run_started.emit()


func end_run(success: bool) -> void:
	run_state.end(success)
	run_ended.emit(success)
	last_run = run_state.duplicate()
	run_state = null


func _process(delta: float) -> void:
	if not is_run_active():
		return
	run_state.elapsed_time += delta
	run_ticked.emit(run_state)
	run_state.event_manager.process(delta, _speed_multiplier)
	run_state.effects_manager.process_effects(delta, _speed_multiplier)


func is_in_run() -> bool:
	return run_state != null


func is_run_active() -> bool:
	return is_in_run() and run_state.active


func pause_run() -> void:
	if not run_state: return
	run_state.active = false


func resume_run() -> void:
	if not run_state: return
	run_state.active = true


func set_speed_multiplier(_mult: int) -> void:
	if not run_state: return
	if _mult <= 0:
		pause_run()
		return
	_speed_multiplier = mini(_mult, _max_speed_multiplier)
	if not is_run_active():
		resume_run()
