extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if GameManager.run_manager.is_run_active():
			GameManager.run_manager.end_run(true)
		else:
			GameManager.run_manager.start_run()
