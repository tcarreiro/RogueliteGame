class_name FactorDefinition extends Resource

@export var id: StringName
@export var display_name: String
@export var max_level: int = 100
@export var default_level: int = 0
@export var thresholds: Array[FactorThreshold] = []
@export var on_creation: Callable
@export var on_overflow: Callable


func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	max_level = int(entry.get("max_level", 100))
	default_level = int(entry.get("default_level", 0))


func connect_callables(state: LuaState) -> void:
	on_creation = LuaHelper.make_callable(state.globals["onCreation"])
	on_overflow = LuaHelper.make_callable(state.globals["onOverflow"])
