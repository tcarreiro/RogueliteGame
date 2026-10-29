class_name Gauntlet extends Equipment

signal datashard_equipped(gauntlet: Gauntlet, datashard: Datashard)

const KIND_GAUNTLET := StringName(KIND_PREFIX+"gauntlet")

var datashard: Datashard
var max_hand_deck_size: int
var max_active_deck_size: int

func _init(definition: EquipmentDefinition) -> void:
	super._init(definition)
	max_hand_deck_size = definition.max_hand_deck_size
	max_active_deck_size = definition.max_active_deck_size


func equip_datashard(_datashard: Datashard) -> void:
	if datashard != null and datashard.id == _datashard.id:
		return
	if datashard != null:
		datashard.unequip()
	datashard = _datashard
	datashard.equip()
	GameLogger.info("[Gauntlet] '%s' equipped."%[datashard.display_name])
	datashard_equipped.emit(self, datashard)
