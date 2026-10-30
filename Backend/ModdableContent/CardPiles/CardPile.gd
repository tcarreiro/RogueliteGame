class_name CardPile extends Resource

######
## ANY ORGANIZED COLLECTION OF CARDS THAT CAN BE MANIPULATED
## THAT INCLUDES HAND, DRAW_PILE, DISCARD_PILE, PERMANENT_DECK, ACTIVE_DECK
######

signal deck_updated(deck: CardPile)

@export var id: StringName
@export var cards: Dictionary[UUID, Card] = {}
@export var max_deck_size: int = 0 # 0 means no limit
@export var max_card_copies_validation: bool = false


func _init(_deck_id:StringName, _cards: Array[Card], _max_deck_size: int = 0, _max_card_copies_validation: bool = false) -> void:
	id = _deck_id
	max_card_copies_validation = _max_card_copies_validation
	max_deck_size = _max_deck_size
	copy_cards(_cards)
	shuffle()
	GameLogger.info("[CardPile] %s initialized with %s cards and hand size %s."%[id, cards.size(), str(_max_deck_size)])


func copy_cards(_cards: Array[Card]) -> void:
	cards = {}
	for card in _cards:
		add_card(card)


func shuffle() -> void:
	var keys := cards.keys()
	keys.shuffle()

	var shuffled: Dictionary[UUID, Card] = {}
	for key in keys:
		shuffled[key] = cards[key]

	cards = shuffled
	deck_updated.emit(self)


func get_effects() -> Array[Effect]:
	var effects := []
	for card: Card in get_cards():
		effects.append_array(card.effects.values())
	return effects


func get_cards() -> Array[Card]:
	return cards.values()


func get_card_by_uuid(card_uuid: UUID) -> Card:
	var found: Array[Card] = get_cards().filter(func(c:Card): return c.uuid == card_uuid)
	if found.is_empty():
		return null
	return found[0]


func get_all_cards_uuid() -> Array[UUID]:
	return cards.keys()


func get_deck_size() -> int:
	return cards.size()


func contains_card(_card:Card) -> bool:
	for card: Card in cards.values():
		if card.uuid == _card.uuid and card.id == _card.id:
			return true
	return false


func pop_front() -> Card:
	if cards.is_empty():
		return null
	
	var card_uuid = cards.keys()[0]
	var card := cards[card_uuid]
	cards.erase(card_uuid)
	return card


func add_card(card: Card) -> bool:
	if not card:
		GameLogger.error(
			"[CardPile] Card not found.")
		return false
	if max_deck_size > 0 and get_deck_size() >= max_deck_size:
		GameLogger.error(
			"[CardPile] couldn't add card %s to deck %s, because there is no slot available."%[card.id, id])
		return false
	deck_updated.emit(self)
	#card.equip()
	cards[card.uuid] = card
	return true


func remove_card(card: Card) -> bool:
	if not cards.has(card.uuid):
		GameLogger.warn(
			"[CardPile] couldn't remove card %s not found in deck %s."%[card.uuid, id])
		return false
	deck_updated.emit(self)
	#card.unequip()
	cards.erase(card.uuid)
	return true
