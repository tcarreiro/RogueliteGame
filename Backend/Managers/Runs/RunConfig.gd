class_name RunConfig extends Resource

@export_category("Identity")
@export var run_id: String = ""
@export var run_seed: int = 0

@export_category("Datashard")
@export var datashard_id: StringName

#@export_category("Loadout")
#@export var active_cards: DeckData
#@export var equipment: Array[Resource] = [] # TODO
#@export var hand_size: int = 5


func _init() -> void:
	if run_seed == 0:
		run_seed = randi()
	
	#if DatashardDatabase.all_datashards.values().is_empty():
		#GameLogger.error("RunConfig: At least 1 registered Datashard needed.")
	#datashard = DatashardDatabase.all_datashards.values()[0]
