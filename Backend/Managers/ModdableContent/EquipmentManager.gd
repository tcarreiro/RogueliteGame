class_name EquipmentManager extends Resource

signal on_equip(equipment: Equipment)
signal on_unequip(equipment: Equipment)

class SlotAddress:
	extends Resource
	var amount: int = 0
	var list:Array[Equipment] = []

var _equipments: Dictionary[Equipment.EquipmentType, SlotAddress] = {}

func _init() -> void:
	add_slot(Equipment.EquipmentType.GAUNTLET) # TBD: only equipment allowed for now


func connect_all_loot_run_signals() -> void:
	for loot in get_all_loot():
		loot.connect_run_start()
		loot.connect_run_end()
		GameLogger.debug("%s had its run signals connected."%[loot.id])


func add_slot(equipment_type: Equipment.EquipmentType) -> void:
	if not _equipments.has(equipment_type):
		_equipments[equipment_type] = SlotAddress.new()
	_equipments[equipment_type].amount += 1


func remove_slot(equipment_type: Equipment.EquipmentType) -> void:
	# TBD: if can be used while in run, need to check for "unequip", or remove open slots first
	if not _equipments.has(equipment_type):
		return
	_equipments[equipment_type].amount -= 1
	if _equipments[equipment_type].amount <= 0:
		_equipments.erase(equipment_type)


func get_all_loot() -> Array[Loot]:
	var all_loot :Array[Loot] = []
	for slot: SlotAddress in _equipments.values():
		for equipment: Equipment in slot.list:
			if equipment == null:
				continue
			all_loot.append(equipment)
			if (equipment is Gauntlet):
				if equipment.datashard != null:
					all_loot.append(equipment.datashard)
			for addon in equipment.get_all_addons():
				if addon != null:
					all_loot.append(addon)
	return all_loot


func get_all_effects() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = []
	for list: Array[Equipment] in _equipments.values().map(func(sa: SlotAddress): return sa.list):
		for equipment: Equipment in list:
			for effect in equipment.get_all_effects_from_equipment():
				if all_effects.has(effect) and effect.unique:
					continue
				all_effects.append(effect)
	return all_effects


func _get_number_of_type_equipped(equipment_type: Equipment.EquipmentType) -> int:
	if not _equipments.has(equipment_type):
		return 0
	return _equipments[equipment_type].list.size()


func _get_number_of_slots_by_type(equipment_type: Equipment.EquipmentType) -> int:
	if not _equipments.has(equipment_type):
		return 0
	return _equipments[equipment_type].amount


func equip(equipment: Equipment) -> void:
	if not _equipments.has(equipment.type):
		GameLogger.error(
			"[%s] There's no slot available for this equipment type"%[Equipment.EquipmentType.keys()[equipment.type]])
		return
	if _get_number_of_slots_by_type(equipment.type) <= _get_number_of_type_equipped(equipment.type):
		GameLogger.error(
			"[%s] could't equip equipment, because there is no slot available."%[Equipment.EquipmentType.keys()[equipment.type]])
		return
	on_equip.emit(equipment)
	_equipments[equipment.type].list.append(equipment)


func unequip(equipment: Equipment) -> void:
	on_unequip.emit(equipment)
	_equipments[equipment.type].list.erase(equipment)


func get_equipped_gauntlet() -> Gauntlet:
	if not _equipments.has(Equipment.EquipmentType.GAUNTLET):
		return null
	var eq_list := _equipments[Equipment.EquipmentType.GAUNTLET].list
	if eq_list.size() == 0:
		return null
	return eq_list.get(0)
