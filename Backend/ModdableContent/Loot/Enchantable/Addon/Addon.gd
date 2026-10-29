class_name Addon extends Enchantable
# Can only be equipped on Equipments with available socket slots

signal equipped(equipment: Equipment, addon: Addon)
signal unequipped(equipment: Equipment, addon: Addon)

const KIND_ADDON := StringName(KIND_PREFIX+"addon")

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int = 1
@export var nature_id: StringName
@export var suits: TagQuery
@export var is_equipped: bool = false

var on_equip: Callable
var on_unequip: Callable


func _init(definition: AddonDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	suits = TagQuery.create(definition.suits)
	max_stack = definition.max_stack
	on_run_start = definition.on_run_start
	on_collect = definition.on_collect
	on_spawn = definition.on_spawn
	on_run_end = definition.on_run_end
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip


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
