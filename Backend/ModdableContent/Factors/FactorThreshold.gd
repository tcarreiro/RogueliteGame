class_name FactorThreshold extends Resource

enum FactorThresholdDirection {
	UP,
	DOWN,
	BOTH
}

@export var level: int
@export var infinite: bool = true # doesn't use charges
@export var charges: int = 1
@export var direction: FactorThresholdDirection = FactorThresholdDirection.UP
var on_reached: Callable

func _init(_level, _infinite, _charges, _direction, callback):
	level = int(_level)
	infinite = bool(_infinite)
	charges = int(_charges)
	direction = Utils.parse_string_into_enum(FactorThresholdDirection, _direction, "FactorThreshold") as FactorThresholdDirection
	on_reached = LuaHelper.make_callable(callback)
