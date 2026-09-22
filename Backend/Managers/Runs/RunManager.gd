class_name RunManager extends Node

signal run_started()
signal run_ended(success: bool)
signal run_ticked(run_state: RunState)

var run_state: RunState

func start_run() -> void:
	run_state = RunState.new()
	run_state.setup_managers()
	run_started.emit()


func end_run(success: bool) -> void:
	run_state.end(success)
	run_ended.emit(success)


func _process(delta: float) -> void:
	if not is_run_active():
		return
	run_state.elapsed_time += delta
	run_ticked.emit(run_state)
	run_state.event_manager.process(delta)


func is_in_run() -> bool:
	return run_state != null


func is_run_active() -> bool:
	return is_in_run() and run_state.active
