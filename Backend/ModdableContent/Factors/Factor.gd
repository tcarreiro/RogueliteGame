class_name Factor extends RefCounted

signal overflow(factor: Factor)
signal level_changed(factor: Factor, level: int)
signal threshold_reached(factor: Factor, threshold: FactorThreshold)

var id: StringName
var display_name: StringName
var max_level: int
var current_level: int = 0
var thresholds: Array[FactorThreshold] = []
var on_overflow: Callable

var _triggered_thresholds: Array[int] = []

func _init(definition: FactorDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	max_level = definition.max_level
	current_level = definition.default_level
	thresholds = definition.thresholds
	on_overflow = definition.on_overflow


func increase_level(amount: int) -> void:
	set_level(current_level + amount)


func decrease_level(amount: int) -> void:
	set_level(current_level - amount)


func set_level(level: int) -> void:
	var initial_level = current_level
	current_level = max(min(level, max_level), 0)
	level_changed.emit(self, current_level - initial_level)
	_check_thresholds(initial_level, current_level)
	if current_level >= max_level:
		overflow.emit.call_deferred(self)


func _check_thresholds(from_level: int, to_level:int) -> void:
	if to_level <= from_level:
		return # TBD: only when increasing?
	for threshold in thresholds:
		if threshold.level <= from_level or threshold.level > to_level:
			continue
		if not threshold.repeatable and _triggered_thresholds.has(threshold.level):
			continue
		_triggered_thresholds.append(threshold.level)
		threshold_reached.emit.call_deferred(self, threshold)
		if threshold.on_reached.is_valid():
			threshold.on_reached.call_deferred(self)
