class_name Datashard extends Enchantable

signal obtained(datashard:Datashard)
signal equipped(datashard:Datashard)
signal unequipped(datashard:Datashard)

var tier: int = 1
var nature_id: StringName

var on_obtained: Callable
var on_equip: Callable
var on_unequip: Callable

func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)


func obtain(equipment: Equipment)-> void:
	obtained.emit(equipment, self)
	if on_obtained.is_valid():
		on_obtained.call(equipment, self)


func equip_at(equipment: Equipment)-> void:
	equipped.emit(equipment, self)
	if on_equip.is_valid():
		on_equip.call(equipment, self)


func unequip_from(equipment: Equipment)-> void:
	unequipped.emit(equipment, self)
	if on_unequip.is_valid():
		on_unequip.call(equipment, self)
