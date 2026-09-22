class_name DeckManager extends Resource

# Run deck handler

signal card_drawn(card: Card)
signal card_discarded(card: Card)

@export var draw_pile: CardPile
@export var hand: CardPile
@export var discard_pile: CardPile
@export var etheral_played_pile: CardPile
@export var permanent_played_pile: CardPile

func setup_run_decks(deck: CardPile, hand_limit) -> void:
	GameLogger.debug("Run deck initialized with %s cards and hand size %s."%[deck.get_deck_size(), str(hand_limit)])
	draw_pile = CardPile.new("DrawPile", [])
	hand = CardPile.new("Hand", [], hand_limit)
	discard_pile = CardPile.new("DiscardPile", [])
	etheral_played_pile = CardPile.new("EtherealPlayedPile", [])
	permanent_played_pile = CardPile.new("PermanentPlayedPile", [])
	draw_pile.shuffle()


func draw(count: int = 1) -> Array[Card]:
	var drawn: Array[Card] = []
	for i in range(count):
		var card := draw_pile.pop_front()
		if not card:
			continue
		hand.add_card(card)
		drawn.append(card)
		card_drawn.emit(card)
	return drawn


func discard(count: int = 1, handle_etheral: bool = false) -> Array[Card]:
	var discarded: Array[Card] = []
	for i in range(count):
		var card = hand.pop_front()
		if not card:
			break
		if handle_etheral and card.is_ethereal():
			etheral_played_pile.add_card(card)
		else:
			if card.is_permanent():
				permanent_played_pile.add_card(card)
			else:
				discard_pile.add_card(card)
		discarded.append(card)
		card_discarded.emit(card)
	return discarded
