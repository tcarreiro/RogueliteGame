class_name Card extends Enchantable

signal drawn(card: Card)
signal played(card: Card)
signal discarded(card: Card)
signal destroyed(card: Card)

enum CardFlag {
	ETHEREAL, 
	PERMANENT, 
	RETURN_TO_DECK, 
	UNBLOCKABLE,
}

const KIND_CARD := StringName(KIND_PREFIX+"card")

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int = 1
@export var nature_id: StringName
@export var cost: int = 0
@export var max_copies_in_active_deck: int = 3
@export var flags: Array[CardFlag] = []

var on_drawn: Callable
var on_played: Callable
var on_discarded: Callable
var on_destroyed: Callable
var on_blocked: Callable

func _init(definition: CardDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	tier = definition.tier
	nature_id = definition.nature_id
	cost = definition.cost
	max_copies_in_active_deck = definition.max_copies_in_active_deck
	for card_flag in definition.flags:
		flags.append(
			Utils.parse_string_into_enum(CardFlag, card_flag, "[Card] - flags") as CardFlag)
	max_stack = definition.max_stack
	on_drawn = definition.on_drawn
	on_played = definition.on_played
	on_discarded = definition.on_discarded
	on_destroyed = definition.on_destroyed
	on_blocked = definition.on_blocked


func draw() -> void:
	drawn.emit(self)
	if not on_drawn.is_valid():
		return
	on_drawn.call(id)


func play() -> void:
	played.emit(self)
	if not on_played.is_valid():
		return
	on_played.call(id)


func discard() -> void:
	discarded.emit(self)
	if not on_discarded.is_valid():
		return
	on_discarded.call(id)


func destroy() -> void:
	destroyed.emit(self)
	if not on_destroyed.is_valid():
		return
	on_destroyed.call(id)


#region Flags
func is_ethereal() -> bool:
	return flags.has(CardFlag.ETHEREAL)


func is_permanent() -> bool:
	return flags.has(CardFlag.PERMANENT)


func returns_to_deck() -> bool:
	return flags.has(CardFlag.RETURN_TO_DECK)


func is_unblockable() -> bool:
	return flags.has(CardFlag.UNBLOCKABLE)
#endregion
