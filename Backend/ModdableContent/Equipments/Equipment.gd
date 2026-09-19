class_name Equipment extends Enchantable

signal on_equip_addon(equipment: Equipment, addon: Addon)
signal on_unequip_addon(equipment: Equipment, addon: Addon)

enum EQUIPMENT_TYPE {
	GAUNTLET
}

var uuid: UUID = UUID.new_uuid()
var display_name: StringName
var description: String
var tier: int
var nature_id: StringName
var cost: float
var socket_slots: int
var addons: Dictionary[int, Addon] = {} # slot_id
var type: EQUIPMENT_TYPE


func _init(definition: EquipmentDefinition) -> void:
	for i in range(socket_slots):
		addons[i] = null
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


#region Addons
func equip_addon(slot_id: int, addon: Addon, force_swap:bool = true) -> void:
	if get_available_slots() <= 0:
		push_warning("[%s] could't equip addon, because there is no slot available."%[EQUIPMENT_TYPE.keys()[type]])
		return
	if addons.has(slot_id) and addons.get(slot_id) != null:
		if not force_swap:
			push_warning("[%s] could't equip addon, because the slot is already in use."%[EQUIPMENT_TYPE.keys()[type]])
			return
		unequip_addon(slot_id)
	on_equip_addon.emit(self, addon)
	addons[slot_id] = addon


func unequip_addon(slot_id: int) -> void:
	if not addons.has(slot_id) or addons.get(slot_id) == null:
		return
	on_unequip_addon.emit(self, addons[slot_id])
	addons[slot_id] = null


func get_socket_slots() -> int:
	return socket_slots


func get_available_slots() -> int:
	return socket_slots - addons.size()


func get_all_addons() -> Array[RunEffect]:
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


func get_all_effects() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = get_all_effects_from_addons()
	for effect in get_all_effects_from_equipment():
		if all_effects.has(effect) and effect.unique:
			continue
		all_effects.append(effect)
	return all_effects
#endregion


#region Effects
func _compute_max_effects_allowed() -> int:
	return max((tier - 1), 0)
#endregion
