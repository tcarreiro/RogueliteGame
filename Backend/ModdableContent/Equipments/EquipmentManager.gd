class_name EquipmentManager extends RefCounted

signal on_equip(equipment: Equipment, slot_id: int)
signal on_unequip(equipment: Equipment, slot_id: int)

class EquippedObject:
	extends Resource
	var slot_id: int
	var equipment:Equipment
	
	func _init(_slot_id: int, _equipment: Equipment) -> void:
		slot_id = _slot_id
		equipment = _equipment

var _equipments: Dictionary[StringName, EquippedObject] = {}
var _slots: Dictionary[int, Equipment.EQUIPMENT_TYPE] = {}

func _init() -> void:
	add_slot(Equipment.EQUIPMENT_TYPE.GAUNTLET) # TBD: only equipment allowed for now


func add_slot(equipment_type: Equipment.EQUIPMENT_TYPE) -> void:
	_slots[_slots.size()] = equipment_type


func remove_slot(slot_id: int) -> void:
	# TBD: if can be used while in run, need to check for "unequip", or remove open slots first
	_slots.erase(slot_id)
	var new_array: Array[Equipment.EQUIPMENT_TYPE] = []
	for slot in _slots.values():
		new_array.append(slot)
		
	_slots = {}
	for slot in new_array:
		add_slot(slot)


func get_equipment_by_slot(slot_id:int) -> Equipment:
	var index = _equipments.values().find(func(eo: EquippedObject): return eo.slot_id == slot_id)
	if index == -1:
		return null
	return _equipments.values()[index].equipment


func get_equipment(equipment_id: StringName) -> Equipment:
	return _equipments.get(equipment_id).equipment


func get_all_equipment_ids() -> Array[StringName]:
	return _equipments.keys()


func get_all_effects() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = []
	for equipment: Equipment in _equipments.values().map(func(eq):return eq.equipment):
		for effect in equipment.get_all_effects_from_equipment():
			if all_effects.has(effect) and effect.unique:
				continue
			all_effects.append(effect)
	return all_effects


func _get_number_of_equipment_type_equipped(equipment_type: Equipment.EQUIPMENT_TYPE) -> int:
	return _equipments.values().map(func(eq: EquippedObject): if equipment_type == eq.equipment.type: return eq).size()


func _get_number_of_slots_by_equipment_type(equipment_type: Equipment.EQUIPMENT_TYPE) -> int:
	return _slots.values().filter(func(type: Equipment.EQUIPMENT_TYPE): return type == equipment_type).size()


func _is_slot_occupied(slot_id: int) -> bool:
	var index = _equipments.values().find(func(eo: EquippedObject): return eo.slot_id == slot_id)
	if index == -1:
		return false
	return _equipments.values()[index] != null


func equip(slot_id: int, equipment: Equipment, force_swap:bool = true) -> void:
	if _get_number_of_slots_by_equipment_type(equipment.type) - _get_number_of_equipment_type_equipped(equipment.type) <= 0:
		GameLogger.error(
			"[%s] could't equip equipment, because there is no slot available."%[Equipment.EQUIPMENT_TYPE.keys()[equipment.type]])
		return
	if _is_slot_occupied(slot_id):
		if not force_swap:
			GameLogger.error(
				"[%s] could't equip equipment, because the slot is already in use."%[Equipment.EQUIPMENT_TYPE.keys()[equipment.type]])
			return
		unequip(slot_id)
	on_equip.emit(equipment, slot_id)
	_equipments[equipment.get_unique_id()] = EquippedObject.new(slot_id, equipment)


func unequip(slot_id: int) -> void:
	if not _is_slot_occupied(slot_id):
		return
	var equipment := get_equipment_by_slot(slot_id)
	if not equipment:
		return
	on_unequip.emit(equipment, slot_id)
	_equipments[equipment.get_unique_id()] = EquippedObject.new(slot_id, null)
