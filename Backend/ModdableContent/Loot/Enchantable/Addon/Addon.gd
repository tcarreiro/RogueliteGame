class_name Addon extends Enchantable

signal equipped(equipment: Equipment, addon: Addon)
signal unequipped(equipment: Equipment, addon: Addon)

var uuid: UUID = UUID.new_uuid()
var tier: int = 1
var nature_id: StringName
var suits: Array[Equipment.EquipmentType] = []
var is_equipped: bool = false

var on_equip: Callable
var on_unequip: Callable

func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)


func equip_at(equipment: Equipment)-> void:
	is_equipped = true
	equipped.emit(equipment, self)
	if on_equip.is_valid():
		on_equip.call(equipment, self)


func unequip_from(equipment: Equipment)-> void:
	is_equipped = false
	unequipped.emit(equipment, self)
	if on_unequip.is_valid():
		on_unequip.call(equipment, self)
