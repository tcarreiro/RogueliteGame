class_name GameState extends Resource

@export var total_runs: int = 0
@export var successful_runs: int = 0
@export var total_play_time: float = 0.0

# TBD: create "active_loot" if decide to allow players to bring itens to run
@export var persistent_loot: LootManager
#@export var deck_collection: DeckData
#@export var active_deck: DeckData

#@export var essences: Dictionary = {
	#Enums.Nature.CORE: 0,
	#Enums.Nature.BOND: 0,
	#Enums.Nature.IMPULSE: 0,
	#Enums.Nature.VEIL: 0,
#}

@export var active_datashard_id: StringName = ""
@export var unlocked_datashards: Dictionary[StringName, Datashard] = {}
@export var active_equipments: Dictionary[StringName, Equipment] = {}

#@export var upgrades: Dictionary = {}
#@export var loaded_maps: Dictionary = {}  # String (scene_id) -> RoomManager | scene_id is the resource path

func _init() -> void:
	# New Game
	_setup_initial_inventory()
	_setup_initial_equipment()
	_setup_initial_datashard()
	#_setup_initial_deck()
	# TODO: LOAD GAME


func _setup_initial_inventory() -> void:
	persistent_loot = LootManager.new("persistent_loot")
	var gauntlet = EquipmentRegistry.create_equipment("gauntlet_bronze") as Gauntlet
	persistent_loot.collect(gauntlet)


func _setup_initial_datashard() -> void:
	var shard = DatashardRegistry.create_datashard("initial_datashard") as Datashard
	unlocked_datashards[shard.id] = shard


func _setup_initial_equipment() -> void:
	#var gauntlet = EquipmentRegistry.create_equipment("gauntlet_bronze") as Gauntlet
	#active_equipments[gauntlet.id] = gauntlet
	pass


func choose_datashard(_datashard_name: String) -> void:
	var gauntlet := get_equipped_gauntlet()
	if not gauntlet:
		return
	if unlocked_datashards.has(_datashard_name):
		active_datashard_id = _datashard_name
		gauntlet.equip_datashard(get_active_datashard())


func get_equipped_gauntlet() -> Gauntlet:
	var index = active_equipments.values().find_custom(func(eq: Equipment): return eq.type == Equipment.EquipmentType.GAUNTLET)
	if index == -1:
		return null
	return active_equipments.values().get(index)


func get_active_datashard() -> Datashard:
	if active_datashard_id == "":
		return null
	return unlocked_datashards.get(active_datashard_id)


func get_available_gauntlets() -> Array[Gauntlet]:
	return persistent_loot.get_available_gauntlets()


func choose_gauntlet(gauntlet: Gauntlet) -> void:
	if get_available_gauntlets().find_custom(func(g: Gauntlet): return g.uuid == gauntlet.uuid) == -1:
		GameLogger.error("[GameState] you don't own this gauntlet.")
		return
	active_equipments[gauntlet.id] = gauntlet


func get_active_run_effects() -> Array[RunEffect]:
	var all_effects: Array[RunEffect] = []
	for a_eq: Equipment in active_equipments.values():
		all_effects.append_array(a_eq.get_all_effects())
		if a_eq is Gauntlet and a_eq.datashard:
			all_effects.append_array(a_eq.datashard.get_all_effects())
		for addon: Addon in a_eq.addons.values():
			all_effects.append_array(addon.get_all_effects())
	return all_effects


#func _setup_initial_deck() -> void:
	#var cards: Array[CardData] = []
	#var treasure_hunter := CardDatabase.get_card("card_treasure_hunter")
	#var essence_seeker := CardDatabase.get_card("card_essence_seeker")
	#var evasion := CardDatabase.get_card("card_evasion")
	#var resonance_ward := CardDatabase.get_card("card_resonance_ward")
	#
	#if resonance_ward:
		#cards.append(CardDatabase.create_card("card_resonance_ward"))
		#cards.append(CardDatabase.create_card("card_resonance_ward"))
	#if treasure_hunter:
		#cards.append(CardDatabase.create_card("card_treasure_hunter"))
	#if essence_seeker:
		#cards.append(CardDatabase.create_card("card_essence_seeker"))
		#cards.append(CardDatabase.create_card("card_essence_seeker"))
	#if evasion:
		#cards.append(CardDatabase.create_card("card_evasion"))
	#
	## TODO: Handles decks max size
	#deck_collection = DeckData.new("PlayerPermanentDeck", cards, 40)
	#active_deck = DeckData.new("PlayerActiveDeck", [], 10, true)


func pause() -> void:
	Engine.time_scale = 0


func resume() -> void:
	Engine.time_scale = 1
