class_name Equipment extends Enchantable

signal equipped(equipment: Equipment)
signal unequipped(equipment: Equipment)

enum EquipmentType {
	GAUNTLET
}

var uuid: UUID = UUID.new_uuid()
var tier: int
var nature_id: StringName
var cost: float
var socket_slots: int
var addons: Dictionary[UUID, Addon] = {}
var type: EquipmentType

var on_equip: Callable
var on_unequip: Callable

func _init(definition: EquipmentDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	cost = definition.cost
	socket_slots = definition.socket_slots
	type = definition.type
	#addons = definition.addons # Fill from definition
	#effects = definition.effects # Fill from definition


func get_unique_id() -> StringName:
	return StringName("%s|%s"%[id, uuid])


#region Equipment
func equip() -> void:
	equipped.emit(self)
	if on_equip.is_valid():
		on_equip.call(id)


func unequip() -> void:
	unequipped.emit(self)
	if on_unequip.is_valid():
		on_unequip.call(id)
#endregion


#region Addons
func equip_addon(addon: Addon) -> void:
	if get_available_slots() <= 0:
		GameLogger.error("[%s] could't equip addon, because there is no slot available."%[EquipmentType.keys()[type]])
		return
	if addons.has(addon.uuid) or addon.is_equipped:
		GameLogger.error("[%s] this addon is already equipped."%[EquipmentType.keys()[type]])
		return
	if not addon.suits.has(type):
		GameLogger.error("[%s] this addon is not suitable to this equipment."%[EquipmentType.keys()[type]])
		return
	addon.equip_at(self)
	addons[addon.uuid] = addon


func unequip_addon(addon: Addon) -> void:
	if not addons.has(addon.uuid):
		GameLogger.error("[%s] this addon is not equipped on this Equipment."%[EquipmentType.keys()[type]])
		return
	addon.unequip_from(self)
	addons.erase(addon.uuid)


func get_socket_slots() -> int:
	return socket_slots


func get_available_slots() -> int:
	return socket_slots - addons.size()


func get_all_addons() -> Array[Addon]:
	return addons.values()


func get_all_addons_ids() -> Array[StringName]:
	return get_all_addons().map(func(addon:Addon): return addon.id)


func get_all_effects_from_addons() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = []
	for addon: Addon in addons.values():
		for effect: RunEffect in addon.effects.values():
			if all_effects.has(effect) and effect.unique:
				continue
			all_effects.append(effect)
	return all_effects


func get_all_effects_ids_from_addons() -> Array[StringName]:
	var all_ids: Array[StringName] = []
	for addon: Addon in addons.values():
		for effect: RunEffect in addon.effects.values():
			all_ids.append(effect.id)
	return all_ids


func get_all_effects_from_equipment() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = get_all_effects_from_addons()
	for effect in get_all_effects():
		if all_effects.has(effect) and effect.unique:
			continue
		all_effects.append(effect)
	return all_effects
#endregion


#region Effects
func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)
#endregion
