class_name Addon extends Enchantable

var uuid: UUID = UUID.new_uuid()
var display_name: StringName
var description: String
var tier: int = 1
var nature_id: StringName
var suits: Array[Equipment.EQUIPMENT_TYPE] = []


func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)
