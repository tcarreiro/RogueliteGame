class_name Factor extends RefCounted

signal overflow(factor: Factor)
signal factor_blocked(factor: Factor)
signal factor_block_added(factor: Factor)
signal level_changed(factor: Factor)
signal threshold_reached(factor: Factor, threshold: FactorThreshold)

var id: StringName
var display_name: StringName
var max_level: int
var current_level: int = 0
var blocks: int = 0
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
		on_creation.call(null, id) # TODO: player


func add_threshold(threshold: FactorThreshold) -> void:
	thresholds.append(threshold)


func increase_max_level(amount: int) -> void:
	set_max_level(max_level + amount)


func add_block(amount: int) -> void:
	blocks += amount
	factor_block_added.emit(self)


func set_max_level(new_max_level: int) -> void:
	max_level = max(new_max_level, 0)
	level_changed.emit(self)
	if current_level > max_level:
		set_level(max_level, false)


func increase_level(amount: int) -> void:
	if blocks >= amount:
		factor_blocked.emit(self)
		blocks -= amount
		return
	var remaining_levels = amount - blocks
	blocks = 0
	factor_blocked.emit(self)
	set_level(current_level + remaining_levels)


func set_level(level: int, check_thresholds: bool = true) -> void:
	var initial_level = current_level
	current_level = max(min(level, max_level), 0)
	level_changed.emit(self)
	if check_thresholds:
		_check_thresholds(initial_level, current_level)
	if current_level >= max_level:
		_on_overflow()


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


func _on_overflow() -> void:
	if on_overflow.is_valid():
		on_overflow.call(null, id)  # TODO: player
	GameLogger.debug("%s overflow" % [id])
	overflow.emit.call_deferred(self)
