class_name FactorManager extends Resource

signal overflow(factor: Factor)
signal factor_blocked(factor: Factor)
signal factor_block_added(factor: Factor)
signal level_changed(factor: Factor)
signal threshold_reached(factor: Factor, threshold: FactorThreshold)

var _factors: Dictionary[StringName, Factor] = {}

func register_factor(factor: Factor) -> void:
	if not factor:
		GameLogger.error("Factor not found.")
		return
	_factors[factor.id] = factor
	factor.created()
	factor.overflow.connect(overflow.emit)
	factor.factor_blocked.connect(factor_blocked.emit)
	factor.factor_block_added.connect(factor_block_added.emit)
	factor.level_changed.connect(level_changed.emit)
	factor.threshold_reached.connect(threshold_reached.emit)


func get_factor(factor_id: StringName) -> Factor:
	return _factors.get(factor_id)


func get_all_factor_ids() -> Array[StringName]:
	return _factors.keys()
