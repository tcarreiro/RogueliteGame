class_name GameState extends Resource

@export var total_runs: int = 0
@export var successful_runs: int = 0
@export var total_play_time: float = 0.0

#@export var deck_collection: DeckData
#@export var active_deck: DeckData

#@export var essences: Dictionary = {
	#Enums.Nature.CORE: 0,
	#Enums.Nature.BOND: 0,
	#Enums.Nature.IMPULSE: 0,
	#Enums.Nature.VEIL: 0,
#}


#@export var active_datashard: DatashardDefinition
@export var unlocked_datashards: Array[StringName] = []

@export var upgrades: Dictionary = {}

#@export var persistent_inventory: InventoryData
# TBD: create "active_inventory" if decide to allow players to bring itens to run

@export var loaded_maps: Dictionary = {}  # String (scene_id) -> RoomManager | scene_id is the resource path

func _init() -> void:
	# New Game
	_setup_initial_datashard()
	#_setup_initial_deck()
	#_setup_initial_inventory()
	# TODO: LOAD GAME


func _setup_initial_datashard() -> void:
	# TODO
	unlocked_datashards.append("datashard_low_resonance")
	#equip_datashard(DatashardDatabase.get_datashard("datashard_low_resonance"))
	#equip_datashard(DatashardDatabase.get_random_datashard())


func choose_datashard(_datashard_name: String) -> void:
	#var datashard = DatashardDatabase.get_datashard(datashard_name)
	#if datashard:
		#equip_datashard(datashard)
	pass


#func equip_datashard(datashard: DatashardData) -> void:
	#EventBus.datashard_equipped.emit()
	#active_datashard = datashard
#
#
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
#
#
#func _setup_initial_inventory() -> void:
	#persistent_inventory = InventoryData.new("PlayerPersistentInventory", 10)
	#GameManager.set_persistent_inventory.emit(persistent_inventory)


func pause() -> void:
	Engine.time_scale = 0


func resume() -> void:
	Engine.time_scale = 1
