class_name RunState extends Resource

@export var id: UUID = UUID.new_uuid()
@export var run_seed: int = 0
@export var elapsed_time: float = 0.0
@export var success: bool = false
@export var active: bool = true
#@export var artifact_room_id: String = ""
#@export var artifact_anchor_id: String = ""
#@export var artifact_collected: bool = false
@export var event_manager: EventManager
@export var factor_manager: FactorManager
#@export var equipment_manager: EquipmentManager
@export var equipment_container: ItemContainer
@export var item_container: ItemContainer = ItemContainer.new()
@export var run_loot_manager: LootManager
@export var run_deck_manager: DeckManager
@export var effects_manager: EffectManager

var _datashard: Datashard
var _gauntlet: Gauntlet


func _init(_seed: int = 0) -> void:
	run_seed = _seed
	if _seed == 0:
		run_seed = randi()
	seed(run_seed)


func setup_managers() -> void:
	_gauntlet = GameManager.get_equipped_gauntlet()
	_datashard = _gauntlet.datashard
	_setup_event_manager()
	_setup_factor_manager()
	_setup_equipment_manager()
	_setup_loot_manager()
	_setup_deck_manager()
	_setup_effects_manager()


func _setup_effects_manager() -> void:
	effects_manager = EffectManager.new()
	_datashard.connect_run_start()
	_gauntlet.connect_run_start()
	for addon in _gauntlet.get_all_addons():
		addon.connect_run_start()
		addon.connect_run_end()
	_gauntlet.connect_run_end()
	_datashard.connect_run_end()


func _setup_event_manager() -> void:
	event_manager = EventManager.new()
	for event_id in EventRegistry.get_all_ids():
		var event = EventRegistry.create_event(event_id) as Event
		event_manager.register_event(event, event.throttle)


func _setup_factor_manager() -> void:
	factor_manager = FactorManager.new()
	for factor_id in FactorRegistry.get_all_ids():
		var factor = FactorRegistry.create_factor(factor_id) as Factor
		factor_manager.register_factor(factor)


func _setup_equipment_manager() -> void:
	#equipment_manager = EquipmentManager.new()
	#equipment_manager.on_equip.connect(
		#func(equipment: Equipment): GameLogger.info("Equipment %s equipped"%equipment.id))
	#equipment_manager.on_unequip.connect(
		#func(equipment: Equipment): GameLogger.info("Equipment %s unequipped"%equipment.id)) # TBD: ??
	var tag_query := TagQuery.create([&"kind.equipment"])
	equipment_container = ItemContainer.new(tag_query)
	_set_run_equipment()
	#equipment_manager.connect_all_loot_run_signals() 


func _set_run_equipment() -> void:
	equipment_container.add(_gauntlet)
	_gauntlet.connect_run_start()
	_gauntlet.connect_run_end()
	#equipment_manager.equip(_gauntlet)


func _setup_loot_manager() -> void:
	# TBD: Run inventory always starts empty?
	run_loot_manager = LootManager.new("run_loot")


func _setup_deck_manager() -> void:
	run_deck_manager = DeckManager.new()
	run_deck_manager.setup_run_decks(GameManager.get_active_card_pile(), _gauntlet.max_hand_deck_size)


func end(_success: bool) -> void:
	active = false
	success = _success


#func _snapshot_factor_levels() -> Dictionary[StringName, int]:
	#var snapshot: Dictionary[StringName, int] = {}
	#for id in factor_manager.get_all_factor_ids():
		#snapshot[id] = factor_manager.get_factor(id).current_level
	#return snapshot
