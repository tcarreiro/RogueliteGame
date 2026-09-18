class_name FactorManager extends RefCounted

var _factors: Dictionary[StringName, Factor] = {}

func register_factor(factor: Factor) -> void:
	if not factor:
		push_warning("Factor not found.")
		return
	_factors[factor.id] = factor


func get_factor(factor_id: StringName) -> Factor:
	return _factors.get(factor_id)


func get_all_factor_ids() -> Array[StringName]:
	return _factors.keys()
