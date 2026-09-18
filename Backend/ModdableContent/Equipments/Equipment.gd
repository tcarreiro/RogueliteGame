class_name Equipment extends RefCounted

signal on_equip_addon(equipment: Equipment, addon: Addon)
signal on_unequip_addon(equipment: Equipment, addon: Addon)
signal on_effect_added(equipment: Equipment, run_effect: RunEffect)
signal on_effect_removed(equipment: Equipment, run_effect: RunEffect)

enum EQUIPMENT_TYPE {
	GAUNTLET
}

var id: StringName
var uuid: StringName
var display_name: StringName
var description: String
var tier: int
var nature_id: StringName
var cost: float
var socket_slots: int
var addons: Dictionary[int, Addon] = {} # slot_id
var effects: Dictionary[StringName, RunEffect] = {}
var type: EQUIPMENT_TYPE


func _init() -> void:
	for i in range(socket_slots):
		addons[i] = null


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
		for effect: RunEffect in addon.effects:
			if all_effects.has(effect) and effect.unique:
				continue
			all_effects.append(effect)
	return all_effects


func get_all_effects_ids_from_addons() -> Array[StringName]:
	return effects.keys()


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


func get_total_effects_on_equipment() -> int:
	return get_all_effects_from_equipment().size()


func get_all_effects_from_equipment() -> Array[RunEffect]:
	return effects.values()


func get_all_effects_ids_from_equipment() -> Array[StringName]:
	return effects.keys()


func add_effect(effect_id: StringName) -> void:
	if _compute_max_effects_allowed() - get_total_effects_on_equipment() <= 0:
		push_warning(
			"[%s] could't add effect %s to equip %s, because there is no slot available."%[EQUIPMENT_TYPE.keys()[type], effect_id, id])
		return
	var effect = RunEffectRegistry.get_run_effects(effect_id)
	if effects.has(effect_id) and effect.unique:
		return
	on_effect_added.emit(self, effect)
	effects[effect_id] = effect


func remove_effect(effect_id: StringName) -> void:
	if not effects.has(effect_id):
		push_warning(
			"[%s] could't remove effect %s not found in equip %s."%[EQUIPMENT_TYPE.keys()[type], effect_id, id])
		return
	on_effect_removed.emit(self, effects.get(effect_id))
	effects.erase(effect_id)
#endregion
