class_name Factor extends RefCounted

signal overflow(factor: Factor)
signal level_changed(factor: Factor, level: int)
signal threshold_reached(factor: Factor, threshold: FactorThreshold)

var id: StringName
var display_name: StringName
var max_level: int
var current_level: int = 0
var thresholds: Array[FactorThreshold] = []
var on_creation: Callable
var on_overflow: Callable

func _init(definition: FactorDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	max_level = definition.max_level
	current_level = definition.default_level
	on_creation = definition.on_creation
	on_overflow = definition.on_overflow


func created():
	if on_creation.is_valid():
		on_creation.call(null, id)


func add_threshold(threshold: FactorThreshold) -> void:
	thresholds.append(threshold)


func set_max_level(new_max_level: int) -> void:
	max_level = max(new_max_level, 0)
	if current_level > max_level:
		set_level(max_level, false)


func increase_level(amount: int) -> void:
	set_level(current_level + amount)


func decrease_level(amount: int) -> void:
	set_level(current_level - amount)


func set_level(level: int, check_thresholds: bool = true) -> void:
	var initial_level = current_level
	current_level = max(min(level, max_level), 0)
	level_changed.emit(self, current_level - initial_level)
	if check_thresholds:
		_check_thresholds(initial_level, current_level)
	if current_level >= max_level:
		overflow.emit.call_deferred(self)


func _check_thresholds(from_level: int, to_level:int) -> void:
	for threshold in thresholds:
		if threshold.level <= from_level or threshold.level > to_level:
			continue
		if not threshold.infinite and threshold.charges <= 0:
			continue
		if to_level > from_level and threshold.direction == FactorThreshold.FactorThresholdDirection.DOWN:
			continue
		if to_level < from_level and threshold.direction == FactorThreshold.FactorThresholdDirection.UP:
			continue
		if not threshold.infinite:
			threshold.charges -= 1
		threshold_reached.emit.call_deferred(self, threshold)
		if threshold.on_reached.is_valid():
			threshold.on_reached.call_deferred(self)
