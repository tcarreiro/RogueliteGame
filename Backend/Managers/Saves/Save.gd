class_name Save extends Resource

@export var save_id: int
@export var created_at: String
@export var last_played: String
@export var last_save: String

# Progressão
@export var total_runs: int = 0
@export var successful_runs: int = 0
@export var total_play_time: float = 0.0

# Coleção
#@export var deck_collection_ids: Array[String] = []
#@export var active_deck_ids: Array[String] = []
#@export var unlocked_datashard_ids: Array[String] = []
#@export var upgrades: Dictionary = {}

var separator:String = "%|%"

func save_data() -> void:
	last_save = Time.get_datetime_string_from_system(false, true)
	total_runs = _get_game_state().total_runs
	successful_runs = _get_game_state().successful_runs
	total_play_time = _get_game_state().total_play_time
	#deck_collection_ids = _serialize_cards(_get_game_state().deck_collection.cards)
	#active_deck_ids = _serialize_cards(_get_game_state().active_deck.cards)
	#unlocked_datashard_ids = _get_game_state().unlocked_datashards
	#upgrades = _get_game_state().upgrades


func load_into_game() -> void:
	GameManager.new_game()
	_get_game_state().total_runs = total_runs
	_get_game_state().successful_runs = successful_runs
	_get_game_state().total_play_time = total_play_time
	#_get_game_state().essences = essences
	#_get_game_state().deck_collection.cards = _deserialize_cards(deck_collection_ids)
	#_get_game_state().active_deck.cards = _deserialize_cards(active_deck_ids)
	#_get_game_state().unlocked_datashards = unlocked_datashard_ids
	#_get_game_state().upgrades = upgrades


func _get_game_state() -> GameState:
	return GameManager.game_state


#func _serialize_cards(cards: Array) -> Array[String]:
	#var ids: Array[String] = []
	#for card in cards:
		#if card is CardData:
			#ids.append("%s%s%s"%[card.id, separator, card.uid])
	#return ids
#
#
#func _deserialize_cards(ids: Array[String]) -> Array[CardData]:
	#var cards: Array[CardData] = []
	#for id in ids:
		#var card_id = id.split(separator)[0]
		#var card_uid = id.split(separator)[1]
		#var card := CardDatabase.get_card(card_id)
		#card.uid = card_uid
		#if card:
			#cards.append(card)
	#return cards
