class_name Datashard extends Enchantable

signal obtained(datashard:Datashard)
signal equipped(datashard:Datashard)
signal unequipped(datashard:Datashard)

var tier: int = 1
var nature_id: StringName

var on_obtained: Callable
var on_run_started: Callable
var on_equip: Callable
var on_unequip: Callable

func _init(definition: DatashardDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	on_obtained = definition.on_obtained
	on_run_started = definition.on_run_started
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip


func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)


func obtain(datashard: Datashard)-> void:
	obtained.emit(datashard, self)
	if on_obtained.is_valid():
		on_obtained.call(datashard, self)


func trigger_run_started(datashard: Datashard)-> void:
	obtained.emit(datashard, self)
	if on_obtained.is_valid():
		on_obtained.call(datashard, self)


func equip_at(datashard: Datashard)-> void:
	equipped.emit(datashard, self)
	if on_equip.is_valid():
		on_equip.call(datashard, self)


func unequip_from(datashard: Datashard)-> void:
	unequipped.emit(datashard, self)
	if on_unequip.is_valid():
		on_unequip.call(datashard, self)
