class_name FactorManager extends Resource

signal overflow(factor: Factor)
signal level_changed(factor: Factor)
signal threshold_reached(factor: Factor, threshold: FactorThreshold)

var _factors: Dictionary[StringName, Factor] = {}

func register_factor(factor: Factor) -> void:
	if not factor:
		GameLogger.error("Factor not found.")
		return
	_factors[factor.id] = factor
	factor.created()
	factor.overflow.connect(_on_overflow)
	factor.overflow.connect(overflow.emit)
	factor.level_changed.connect(level_changed.emit)
	factor.threshold_reached.connect(threshold_reached.emit)


func get_factor(factor_id: StringName) -> Factor:
	return _factors.get(factor_id)


func get_all_factor_ids() -> Array[StringName]:
	return _factors.keys()


func _on_overflow(factor: Factor) -> void:
	if factor.on_overflow.is_valid():
		factor.on_overflow.call(null, factor.id)  # TODO: player
	GameLogger.debug("%s overflow" % [factor.id])
