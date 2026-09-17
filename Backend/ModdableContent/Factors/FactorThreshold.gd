class_name FactorThreshold extends Resource

@export var level: int
@export var repeatable: bool = false # everytime it crosses the threshold or only the first time?
var on_reached: Callable
