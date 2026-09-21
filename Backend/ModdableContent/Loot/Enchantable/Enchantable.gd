class_name Enchantable extends Loot

signal effect_added(equipment: Equipment, run_effect: RunEffect)
signal effect_removed(equipment: Equipment, run_effect: RunEffect)

@export var effects: Dictionary[StringName, RunEffect] = {}

var on_effect_added: Callable
var on_effect_removed: Callable

func _compute_max_effects_allowed() -> int:
	return 0


func get_total_effects() -> int:
	return get_all_effects().size()


func get_all_effects() -> Array[RunEffect]:
	return effects.values()


func add_effect(effect_id: StringName) -> void:
	if _compute_max_effects_allowed() - get_total_effects() <= 0:
		GameLogger.warn(
			"[Enchantable] could't add effect %s to enchantable %s, because there is no slot available."%[effect_id, id])
		return
	var effect = RunEffectRegistry.create_run_effect(effect_id)
	if effects.has(effect_id) and effect.unique:
		return
	effect_added.emit(self, effect)
	if on_effect_added.is_valid():
		on_effect_added.call(effect_id)
	effect.equip()
	effects[effect_id] = effect


func remove_effect(effect_id: StringName) -> void:
	if not effects.has(effect_id):
		GameLogger.warn(
			"[Enchantable] could't remove effect %s not found in equip %s."%[effect_id, id])
		return
	var effect: RunEffect = effects.get(effect_id)
	effect_removed.emit(self, effect)
	if on_effect_removed.is_valid():
		on_effect_removed.call(effect_id)
	effect.unequip()
	effects.erase(effect_id)
