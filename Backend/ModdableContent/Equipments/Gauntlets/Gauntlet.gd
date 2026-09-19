class_name Gauntlet extends Equipment

var datashard: Datashard
var max_hand_deck_size: int
var max_active_deck_size: int

func _init(definition: EquipmentDefinition) -> void:
	super._init(definition)
	type = EQUIPMENT_TYPE.GAUNTLET
	max_hand_deck_size = definition.max_hand_deck_size
	max_active_deck_size = definition.max_active_deck_size
