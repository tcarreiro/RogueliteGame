class_name LootManager extends Resource

signal loot_changed(loot_manager: LootManager)
signal collected(loot: Loot)

# What the player has "in his bag"
var name: StringName

var _equipments: Dictionary[StringName, Array] = {} # Array[Equipment]
var _consumables: Dictionary[StringName, Array] = {} # Array[Consumable]
var _currency: Dictionary[StringName, Array] = {} # Array[Currency]
var _addon: Dictionary[StringName, Array] = {} # Array[Addon]
var _datashards: Dictionary[StringName, Array] = {} # Array[Datashard]

func _init(_n: StringName) -> void:
	name = _n


func _on_collect(loot:Loot, dict:Dictionary[StringName, Array]) -> void:
	if not dict.has(loot.id):
		dict[loot.id] = []
	dict[loot.id].append(loot)
	collected.emit(self)


func _on_remove(loot:Loot, dict:Dictionary[StringName, Array]) -> void:
	if not dict.has(loot.id):
		return
		
	var list: Array = dict[loot.id]
	var uuid: UUID = loot.get("uuid")
	# TO TEST: isn't list.erase(loot) enough?
	if uuid == null:
		collected.emit(self)
		list.pop_front()
		return
	
	var existing_loot := _get_by_uuid(uuid, list)
	if existing_loot != null:
		list.erase(existing_loot)


func _get_by_uuid(uuid: UUID, list: Array) -> Loot:
	var index = list.find_custom(func(l): return l.uuid == uuid)
	if index == -1:
		return null
	return list[index]


func get_collection_of_same_type_as(loot: Loot):
	if loot is Equipment:
		return _equipments
	if loot is Consumable:
		return _consumables
	if loot is Currency:
		return _currency
	if loot is Addon:
		return _addon
	if loot is Datashard:
		return _datashards
	return null


func collect(loot: Loot) -> void:
	var dict = get_collection_of_same_type_as(loot)
	if dict == null:
		return
	dict = dict as Dictionary
	_on_collect(loot, dict)
	loot_changed.emit(self)
	loot.collect()


func remove(loot: Loot):
	var loot_id = loot.id
	var dict = get_collection_of_same_type_as(loot)
	if dict == null:
		return
	dict = dict as Dictionary
	_on_remove(loot, dict)
	loot_changed.emit(self)
	if dict[loot_id].is_empty():
		dict.erase(loot_id)


func get_available_gauntlets() -> Array[Gauntlet]:
	var gauntlets: Array[Gauntlet] = []
	for equipment_list in _equipments.values():
		for equipment in equipment_list:
			if equipment is Gauntlet:
				gauntlets.append(equipment)

	return gauntlets
