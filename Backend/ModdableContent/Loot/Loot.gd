class_name Loot extends RefCounted

signal collected(loot: Loot, amount: int)
signal spawned(loot: Loot, amount: int)

var id: StringName
var display_name: StringName
var description: String
var stackable: bool

var on_run_start: Callable
var on_collect: Callable
var on_spawn: Callable
var on_run_end: Callable

func connect_run_start() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_started, _on_run_started, ConnectFlags.CONNECT_ONE_SHOT)


func connect_run_end() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_ended, _on_run_ended, ConnectFlags.CONNECT_ONE_SHOT)


func _on_run_started(config: RunConfig) -> void:
	if on_run_start.is_valid():
		on_run_start.call(config)


func _on_run_ended(success: bool) -> void:
	if on_run_end.is_valid():
		on_run_end.call(success)


func spawn(amount: int) -> void:
	spawned.emit(self, amount)
	if on_spawn.is_valid():
		on_spawn.call(self, amount)


func collect(amount: int) -> void:
	collected.emit(self, amount)
	if on_collect.is_valid():
		on_collect.call(self, amount)
