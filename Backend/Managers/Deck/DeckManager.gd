class_name DeckManager extends Resource

# Run deck handler
signal card_played(card: Card)
signal card_drawn(card: Card)
signal card_discarded(card: Card)

@export var draw_pile: CardPile
@export var hand_pile: CardPile
@export var discard_pile: CardPile
@export var played_pile: Array[UUID]
@export var etheral_played_pile: Array[UUID]
@export var permanent_played_pile: Array[UUID]

func setup_run_decks(deck: CardPile, hand_limit) -> void:
	GameLogger.debug("Run deck initialized with %s cards and hand size %s."%[deck.get_deck_size(), str(hand_limit)])
	draw_pile = CardPile.new("DrawPile", deck.get_cards())
	hand_pile = CardPile.new("Hand", [], hand_limit)
	discard_pile = CardPile.new("DiscardPile", [])
	played_pile = []
	etheral_played_pile = []
	permanent_played_pile = []
	draw_pile.shuffle()


func _is_card_in_pile(card_uuid: UUID, pile: CardPile) -> bool:
	return pile.get_cards().find_custom(func(c:Card): return c.uuid == card_uuid) != -1


func play(card_uuid: UUID) -> Card:
	if not _is_card_in_pile(card_uuid, hand_pile):
		return null
	var card: Card = hand_pile.get_card_by_uuid(card_uuid)
	hand_pile.remove_card(card)
	card_played.emit(card)
	discard_pile.add_card(card)
	played_pile.append(card.uuid)
	if card.is_ethereal():
		etheral_played_pile.append(card.uuid)
	if card.is_permanent():
		permanent_played_pile.append(card.uuid)
	card.play()
	return card


func draw(count: int = 1) -> Array[Card]:
	var drawn: Array[Card] = []
	for i in range(count):
		var card := draw_pile.pop_front()
		if not card:
			continue
		hand_pile.add_card(card)
		drawn.append(card)
		card_drawn.emit(card)
		card.draw()
	return drawn


func discard(count: int = 1, handle_etheral: bool = false) -> Array[Card]:
	var discarded: Array[Card] = []
	for i in range(count):
		var card = hand_pile.pop_front()
		if not card:
			break
		if handle_etheral and card.is_ethereal():
			etheral_played_pile.append(card.uuid)
		if card.is_permanent():
			permanent_played_pile.append(card.uuid)
		discard_pile.add_card(card)
		discarded.append(card)
		card_discarded.emit(card)
		card.discard()
	return discarded


func get_played_cards_effects() -> Array[Effect]:
	var all_effects := []
	for card_uuid:UUID in played_pile:
		var card: Card = discard_pile.get_card_by_uuid(card_uuid)
		if not card:
			continue
		all_effects.append_array(card.effects.values())
	return all_effects
