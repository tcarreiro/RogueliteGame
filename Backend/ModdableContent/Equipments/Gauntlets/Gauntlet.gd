class_name Gauntlet extends Equipment

var datashard: Datashard
var max_active_deck_size: int

func _init() -> void:
	super._init()
	type = EQUIPMENT_TYPE.GAUNTLET


#region Effects
func get_all_effects_from_gauntlet() -> Array[RunEffect]:
	return effects.values()


func get_all_effects_ids_from_gauntlet() -> Array[StringName]:
	return effects.keys()


func add_effect(effect_id: StringName) -> void:
	pass

#endregion
