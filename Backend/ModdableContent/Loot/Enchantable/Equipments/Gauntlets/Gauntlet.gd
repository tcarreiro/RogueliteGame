class_name Gauntlet extends Equipment

signal datashard_equipped(gauntlet: Gauntlet, datashard: Datashard)

const KIND_GAUNTLET := StringName(KIND_PREFIX+"gauntlet")

var datashard_slot: ItemContainer
var max_hand_deck_size: int
var max_active_deck_size: int

func _init(definition: EquipmentDefinition) -> void:
	super._init(definition)
	var tag_query := TagQuery.create([Datashard.KIND_DATASHARD])
	datashard_slot = ItemContainer.new(tag_query, 1)
	max_hand_deck_size = definition.max_hand_deck_size
	max_active_deck_size = definition.max_active_deck_size


func equip_datashard(_datashard: Datashard) -> void:
	if datashard_slot != null and datashard_slot.find_by_id(_datashard.id):
		return
	unequip_datashard()
	datashard_slot.add(_datashard)
	_datashard.equip(self)
	GameLogger.info("[Gauntlet] '%s' equipped."%[_datashard.display_name])
	datashard_equipped.emit(self, _datashard)


func unequip_datashard() -> void:
	if datashard_slot == null:
		return
	var equipped_datashard := get_equipped_datashard()
	if not equipped_datashard:
		return
	datashard_slot.remove_by_id(equipped_datashard.id)


func get_equipped_datashard() -> Datashard:
	var datashards = datashard_slot.get_all_with_tag(Datashard.KIND_DATASHARD)
	if datashards.is_empty():
		return null
	return datashards[0] as Datashard
