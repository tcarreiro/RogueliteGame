class_name GameState extends Resource

@export var total_runs: int = 0
@export var successful_runs: int = 0
@export var total_play_time: float = 0.0

# TBD: create "active_loot" if decide to allow players to bring itens to run
@export var persistent_inventory: ItemContainer
@export var card_collection: CardPile
@export var active_cards: CardPile
#@export var deck_collection: DeckData
#@export var active_deck: DeckData

#@export var essences: Dictionary = {
	#Enums.Nature.CORE: 0,
	#Enums.Nature.BOND: 0,
	#Enums.Nature.IMPULSE: 0,
	#Enums.Nature.VEIL: 0,
#}

@export var active_datashard_id: StringName = ""
@export var active_equipments: Dictionary[StringName, Equipment] = {}

#@export var upgrades: Dictionary = {}
#@export var loaded_maps: Dictionary = {}  # String (scene_id) -> RoomManager | scene_id is the resource path

func _init() -> void:
	# New Game
	_setup_initial_inventory()
	_setup_initial_equipment()
	_setup_initial_datashard()
	_setup_initial_deck()
	# TODO: LOAD GAME


func _setup_initial_inventory() -> void:
	var tag_query := TagQuery.create([], [], [&"kind.cards"])
	persistent_inventory = ItemContainer.new(tag_query)
	var gauntlet = EquipmentRegistry.create_equipment("gauntlet_bronze") as Gauntlet
	var iron_gauntlet = EquipmentRegistry.create_equipment("gauntlet_iron") as Gauntlet
	persistent_inventory.add(gauntlet)
	persistent_inventory.add(iron_gauntlet)


func _setup_initial_datashard() -> void:
	var shard = DatashardRegistry.create_datashard("initial_datashard") as Datashard
	persistent_inventory.add(shard)


func _setup_initial_equipment() -> void:
	var gauntlet := persistent_inventory.find_by_id("gauntlet_bronze")[0] as Gauntlet
	choose_gauntlet(gauntlet)


func get_unlocked_datashards() -> Array[Loot]:
	return persistent_inventory.get_all_with_tag(&"kind.datashard")


func choose_datashard(_datashard_id: String) -> void:
	var gauntlet := get_equipped_gauntlet()
	if not gauntlet:
		return
	var found_datashard_index := get_unlocked_datashards().find_custom(func(ds: Datashard): return ds.id == _datashard_id)
	if found_datashard_index > -1:
		active_datashard_id = _datashard_id
		gauntlet.equip_datashard(get_active_datashard())


func get_equipped_gauntlet() -> Gauntlet:
	var index = active_equipments.values().find_custom(func(eq: Equipment): return eq.type == Equipment.EquipmentType.GAUNTLET)
	if index == -1:
		return null
	return active_equipments.values().get(index)


func get_active_datashard() -> Datashard:
	if active_datashard_id == "":
		return null
	var active_datashard_index := get_unlocked_datashards().find_custom(func(ds: Datashard): return ds.id == active_datashard_id)
	return get_unlocked_datashards().get(active_datashard_index)


func get_available_gauntlets() -> Array[Loot]:
	return persistent_inventory.get_all_with_tag(&"kind.gauntlet")


func choose_gauntlet(gauntlet: Gauntlet) -> void:
	if get_equipped_gauntlet() and get_equipped_gauntlet().id == gauntlet.id:
		return
	if get_available_gauntlets().find_custom(func(g: Gauntlet): return g.uuid == gauntlet.uuid) == -1:
		GameLogger.error("[GameState] you don't own this gauntlet.")
		return
	GameLogger.info("[GameState] '%s' equipped."%[gauntlet.display_name])
	active_equipments.clear()
	active_equipments[gauntlet.id] = gauntlet


func get_active_effects() -> Array[Effect]:
	var all_effects: Array[Effect] = []
	for a_eq: Equipment in active_equipments.values():
		all_effects.append_array(a_eq.get_all_effects())
		if a_eq is Gauntlet and a_eq.datashard:
			all_effects.append_array(a_eq.datashard.get_all_effects())
		for addon: Addon in a_eq.addons.values():
			all_effects.append_array(addon.get_all_effects())
	return all_effects


func get_permanent_deck() -> Array[Card]:
	return card_collection.get_cards()


func get_active_deck() -> Array[Card]:
	return active_cards.get_cards()


func activate_card(card: Card) -> bool:
	if not card_collection.get_all_cards_uuid().has(card.uuid):
		return false
	return active_cards.add_card(card)


func deactivate_card(card: Card) -> bool:
	if not active_cards.get_all_cards_uuid().has(card.uuid):
		return false
	return active_cards.remove_card(card)


func get_active_card_pile() -> CardPile:
	return active_cards


func _setup_initial_deck() -> void:
	var _cards: Array[Card] = []
	_cards.append(CardRegistry.create_card("card_evasion"))
	_cards.append(CardRegistry.create_card("card_evasion"))
	_cards.append(CardRegistry.create_card("card_evasion"))
	card_collection = CardPile.new("PermanentDeck", _cards)
	active_cards = CardPile.new("ActiveDeck", [])
	#func _init(_deck_id:StringName, _cards: Array[Card], _max_deck_size: int = 0, _max_card_copies_validation: bool = false) -> void:
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
