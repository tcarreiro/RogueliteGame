class_name Datashard extends Enchantable

#signal obtained(datashard:Datashard)
#signal equipped(datashard:Datashard)

var tier: int = 1
var nature_id: StringName

func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)
