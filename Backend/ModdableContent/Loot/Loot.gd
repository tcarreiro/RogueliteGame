class_name Loot extends Resource

signal collected(loot: Loot)
signal spawned(loot: Loot)

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var stackable: bool

var on_run_start: Callable
var on_collect: Callable
var on_spawn: Callable
var on_run_end: Callable

func connect_run_start() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_started, _on_run_started, ConnectFlags.CONNECT_ONE_SHOT)


func connect_run_end() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_ended, _on_run_ended, ConnectFlags.CONNECT_ONE_SHOT)


func _on_run_started() -> void:
	if on_run_start.is_valid():
		on_run_start.call(self)


func _on_run_ended(success: bool) -> void:
	if on_run_end.is_valid():
		on_run_end.call(success)


func spawn() -> void:
	spawned.emit(self)
	if on_spawn.is_valid():
		on_spawn.call(self)


func collect() -> void:
	collected.emit(self)
	if on_collect.is_valid():
		on_collect.call(self)
