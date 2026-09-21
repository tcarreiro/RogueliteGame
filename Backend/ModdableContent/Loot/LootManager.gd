class_name LootManager extends RefCounted

signal loot_changed(loot_manager: LootManager)

# What the player has "in his bag"
var name: StringName

var _equipments: Dictionary[StringName, Array] = {} # Array[Equipment]
var _consumables: Dictionary[StringName, Array] = {} # Array[Consumable]
var _currency: Dictionary[StringName, Array] = {} # Array[Currency]
var _addon: Dictionary[StringName, Array] = {} # Array[Addon]
var _datashards: Dictionary[StringName, Array] = {} # Array[Datashard]

var _list_map: Dictionary = {
	Equipment: _equipments,
	Consumable: _consumables,
	Currency: _currency,
	Addon: _addon,
	Datashard: _datashards,
}

func _init(_n: StringName) -> void:
	name = _n


func _on_collect(loot:Loot, dict:Dictionary[StringName, Array]) -> void:
	if not dict.has(loot.id):
		dict[loot.id] = []
	dict[loot.id].append(loot)


func _on_remove(loot:Loot, dict:Dictionary[StringName, Array]) -> void:
	if not dict.has(loot.id):
		return
		
	var list: Array = dict[loot.id]
	var uuid: UUID = loot.get("uuid")
	# TO TEST: isn't list.erase(loot) enough?
	if uuid == null:
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


func get_collection_of_same_type_as(loot: Loot) -> Dictionary:
	return _list_map.get(loot.get_script(), {})


func collect(loot: Loot) -> void:
	var dict: Dictionary = get_collection_of_same_type_as(loot)
	if dict.is_empty():
		return
	_on_collect(loot, dict)
	loot_changed.emit(self)
	loot.collect()


func remove(loot: Loot):
	var loot_id = loot.id
	var dict: Dictionary = get_collection_of_same_type_as(loot)
	if dict.is_empty():
		return
	_on_remove(loot, dict)
	loot_changed.emit(self)
	if dict[loot_id].is_empty():
		dict.erase(loot_id)
