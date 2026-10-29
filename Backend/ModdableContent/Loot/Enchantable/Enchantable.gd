class_name Enchantable extends Loot

signal effect_updated(equipment: Equipment)

const KIND_ENCHANTABLE := StringName(KIND_PREFIX+"enchantable")

@export var effects: Dictionary[UUID, Effect] = {}

func _compute_max_effects_allowed() -> int:
	return 0


func get_total_effects() -> int:
	return get_all_effects().size()


func get_all_effects() -> Array[Effect]:
	return effects.values()


func add_effect(effect: Effect) -> void:
	if _compute_max_effects_allowed() - get_total_effects() <= 0:
		GameLogger.error(
			"[Enchantable] could't add effect to enchantable %s, because there is no slot available."%[id])
		return
	if not effect:
		return
	effects[effect.uuid] = effect
	effect_updated.emit(self)


func remove_effect(effect: Effect) -> void:
	if not effects.has(effect.uuid):
		GameLogger.warn(
			"[Enchantable] could't remove effect. Not found in equip %s."%[id])
		return
	effects.erase(effect.uuid)
	effect_updated.emit(self)
