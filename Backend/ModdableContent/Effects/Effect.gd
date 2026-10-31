class_name Effect extends Resource

enum EffectCategory {
	BUFF,
	DEBUFF
}

enum TriggerEvent {
	TE_IMMEDIATE,
	TE_RUN_EVENT,
	TE_CARD_EVENT,
	TE_FACTOR_EVENT,
	TE_PLAYER_EVENT,
	TE_LOOT_EVENT,
}

enum EventCategory {
	EC_NONE,
	EC_RE_START_RUN, # RE -> Run Event
	EC_RE_END_RUN,
	EC_RE_TRIGGERED,
	EC_RE_RESOLVED,
	EC_RE_BLOCKED,
	EC_CE_DRAWN, # CE -> Card Event
	EC_CE_PLAYED,
	EC_CE_DISCARDED,
	EC_FE_OVERFLOW, # FE -> Factor Event
	EC_FE_LEVEL_CHANGED,
	EC_FE_THRESHOLD_REACHED,
	EC_PE_SPOTTED, # PE -> Player Event
	EC_PE_DEATH,
	EC_PE_HIT,
	EC_LE_COLLECTED # LE -> Loot Event
}

@export var uuid: UUID = UUID.new_uuid()
@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var trigger_event: TriggerEvent 
@export var event_category: EventCategory
@export var trigger_filter: StringName
@export var effect_category: EffectCategory
@export var stacks: int = -1 # -1 means infinite
@export var duration: float = NAN # NAN means doesn't expire
@export var unique: bool = false

var on_trigger: Callable

var _original_stacks: int = -1

func _init(definition: EffectDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	trigger_event = definition.trigger_event
	event_category = definition.event_category
	trigger_filter = definition.trigger_filter
	effect_category = definition.effect_category
	stacks = definition.stacks
	_original_stacks = stacks
	duration = definition.duration
	unique = definition.unique

	on_trigger = definition.on_trigger


func matches(filter: StringName, _event_category: EventCategory = EventCategory.EC_NONE) -> bool:
	if trigger_filter != &"" and trigger_filter != filter:
		return false
	if event_category != EventCategory.EC_NONE and event_category != _event_category:
		return false
	return true


func has_time_remaining() -> bool:
	return is_nan(duration) or duration > 0.0


func can_fire() -> bool:
	return stacks != 0


func reset_stacks() -> void:
	stacks = _original_stacks


func fire(params: Dictionary = {}) -> void:
	if not on_trigger.is_valid() or not can_fire():
		return
	on_trigger.call(params)
	if stacks > 0:
		stacks -= 1
