class_name FactorManager extends RefCounted

var _factors: Dictionary[StringName, Factor] = {}

func register_factor(factor: Factor) -> void:
	if not factor:
		push_warning("Factor not found.")
		return
	_factors[factor.id] = factor
	factor.overflow.connect(_on_overflow)


func get_factor(factor_id: StringName) -> Factor:
	return _factors.get(factor_id)


func get_all_factor_ids() -> Array[StringName]:
	return _factors.keys()


func mock(factor_id: StringName) -> void:
	# TODO: remove once factor event is registered
	print("%s level = 100 from mock"%factor_id)
	GameManager.get_factor(factor_id).increase_level(100)


func _on_overflow(factor: Factor) -> void:
	# TODO: how do I get the correct LuaState?
	var state := LuaBridgeRegistry.get_lua_state("mod_core")
	LuaHelper.call_by_name(state, "onOverflow", [null, factor.id])
	print("%s overflow"%[factor.id])
