class_name Datashard extends Enchantable

signal obtained(datashard:Datashard)
signal equipped(datashard:Datashard)
signal unequipped(datashard:Datashard)

const KIND_DATASHARD := StringName(KIND_PREFIX+"datashard")

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int = 1
@export var nature_id: StringName

var on_obtained: Callable
var on_equip: Callable
var on_unequip: Callable

var _equipped_at: Gauntlet = null

func _init(definition: DatashardDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	max_stack = definition.max_stack
	on_obtained = definition.on_obtained
	on_run_start = definition.on_run_start
	on_collect = definition.on_collect
	on_spawn = definition.on_spawn
	on_run_end = definition.on_run_end
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip


func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)


func obtain()-> void:
	obtained.emit(self)
	if on_obtained.is_valid():
		on_obtained.call(self)


func equip(gauntlet: Gauntlet)-> void:
	equipped.emit(self)
	if _equipped_at and _equipped_at != gauntlet:
		unequip()
	_equipped_at = gauntlet
	if on_equip.is_valid():
		on_equip.call(self)


func unequip()-> void:
	unequipped.emit(self)
	if _equipped_at:
		_equipped_at.unequip_datashard()
	_equipped_at = null
	if on_unequip.is_valid():
		on_unequip.call(self)


func get_gauntlet_equipped() -> Gauntlet:
	return _equipped_at
