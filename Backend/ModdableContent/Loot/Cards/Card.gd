class_name Card extends Loot

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

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int = 1
@export var nature_id: StringName
@export var cost: int = 0
@export var max_copies_in_active_deck: int = 3
@export var flags: Array[CardFlag] = []
#@export var effects: Array[CardEffect] = [] # TODO: CardEffect

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
	#for effect_id in definition.effect_ids:
		#add_effect(effect_id)
	stackable = definition.stackable
	on_drawn = definition.on_drawn
	on_played = definition.on_played
	on_discarded = definition.on_discarded
	on_destroyed = definition.on_destroyed
	on_blocked = definition.on_blocked


func draw() -> void:
	drawn.emit(self)
	if on_drawn.is_valid():
		on_drawn.call()


func play() -> void:
	played.emit(self)
	if on_played.is_valid():
		on_played.call()


func discard() -> void:
	discarded.emit(self)
	if on_discarded.is_valid():
		on_discarded.call()


func destroy() -> void:
	destroyed.emit(self)
	if on_destroyed.is_valid():
		on_destroyed.call()


#region Flags
func is_ethereal() -> bool:
	return flags.has(CardFlag.ETHEREAL)


func is_permanent() -> bool:
	return flags.has(CardFlag.PERMANENT)


func returns_to_deck() -> bool:
	return flags.has(CardFlag.RETURN_TO_DECK)


func is_unblockable() -> bool:
	return flags.has(CardFlag.PERMANENT)
#endregion

#func get_effects_by_trigger(trigger: Enums.EventTrigger) -> Array[CardEffect]:
	#var result: Array[CardEffect] = []
	#for effect in effects:
		#if effect.trigger == trigger:
			#result.append(effect)
	#return result
#
#
#func reset_charges() -> void:
	#for effect in effects:
		#effect.reset_charges()
#
#
