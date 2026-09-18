class_name FactorDefinition extends Resource

@export var id: StringName
@export var display_name: String
@export var max_level: int = 100
@export var default_level: int = 0
@export var thresholds: Array[FactorThreshold] = []
@export var on_overflow: Callable
