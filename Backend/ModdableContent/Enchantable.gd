class_name Enchantable extends RefCounted

signal on_effect_added(equipment: Equipment, run_effect: RunEffect)
signal on_effect_removed(equipment: Equipment, run_effect: RunEffect)

var id: String
var effects: Dictionary[StringName, RunEffect] = {}

func _compute_max_effects_allowed() -> int:
	return 0


func get_total_effects_on_equipment() -> int:
	return get_all_effects_from_equipment().size()


func get_all_effects_from_equipment() -> Array[RunEffect]:
	return effects.values()


func add_effect(effect_id: StringName) -> void:
	if _compute_max_effects_allowed() - get_total_effects_on_equipment() <= 0:
		push_warning(
			"[Enchantable] could't add effect %s to enchantable %s, because there is no slot available."%[effect_id, id])
		return
	var effect = RunEffectRegistry.create_run_effect(effect_id)
	if effects.has(effect_id) and effect.unique:
		return
	on_effect_added.emit(self, effect)
	effect.trigger_on_equip()
	effects[effect_id] = effect


func remove_effect(effect_id: StringName) -> void:
	if not effects.has(effect_id):
		push_warning(
			"[Enchantable] could't remove effect %s not found in equip %s."%[effect_id, id])
		return
	var effect: RunEffect = effects.get(effect_id)
	on_effect_removed.emit(self, effect)
	effect.trigger_on_unequip()
	effects.erase(effect_id)
