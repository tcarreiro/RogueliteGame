class_name Equipment extends Enchantable

signal equipped(equipment: Equipment)
signal unequipped(equipment: Equipment)

const KIND_EQUIPMENT := StringName(KIND_PREFIX+"equipment")

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int
@export var nature_id: StringName
@export var cost: float
@export var kind: StringName
@export var sockets: ItemContainer

var on_equip: Callable
var on_unequip: Callable

func _init(definition: EquipmentDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	cost = definition.cost
	kind = definition.kind
	max_stack = definition.max_stack
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip
	on_run_start = definition.on_run_start
	on_run_end = definition.on_run_end
	on_collect = definition.on_collect
	on_spawn = definition.on_spawn
	
	var tag_query := TagQuery.create([Addon.KIND_ADDON])
	sockets = ItemContainer.new(tag_query, definition.socket_slots)
	for addon_id in definition.addon_ids:
		equip_addon(AddonRegistry.create_addon(addon_id))


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
		GameLogger.error("[%s] could't equip addon, because there is no slot available."%[kind])
		return
	if sockets.contains(addon) or addon.is_equipped:
		GameLogger.error("[%s] this addon is already equipped."%[kind])
		return
	if addon.suits.query_tags([kind]) != TagQuery.TagResult.OK:
		GameLogger.error("[%s] this addon is not suitable to this equipment."%[kind])
		return
	addon.equip_at(self)
	sockets.add(addon)


func unequip_addon(addon: Addon) -> void:
	if not sockets.contains(addon):
		GameLogger.error("[%s] this addon is not equipped on this Equipment."%[kind])
		return
	addon.unequip_from(self)
	sockets.remove(addon)


func get_socket_slots() -> int:
	return sockets.get_capacity()


func get_available_slots() -> int:
	return sockets.get_free_slots()


func get_all_addons() -> Array[Loot]:
	return sockets.get_all_loot()


func get_all_addons_ids() -> Array[StringName]:
	return get_all_addons().map(func(addon:Addon): return addon.id)


func get_all_effects_from_addons() -> Array[Effect]:
	var all_effects: Array[Effect] = []
	for addon: Addon in get_all_addons():
		for effect: Effect in addon.effects.values():
			if all_effects.has(effect) and effect.unique:
				continue
			all_effects.append(effect)
	return all_effects


func get_all_effects_ids_from_addons() -> Array[StringName]:
	var all_ids: Array[StringName] = []
	for addon: Addon in get_all_addons():
		for effect: Effect in addon.effects.values():
			all_ids.append(effect.id)
	return all_ids


func get_all_effects_from_equipment() -> Array[Effect]:
	var all_effects: Array[Effect] = get_all_effects_from_addons()
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
