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
	EC_RE_START_RUN,
	EC_RE_END_RUN,
	EC_RE_TRIGGERED,
	EC_RE_RESOLVED,
	EC_RE_BLOCKED,
	EC_CE_DRAWN,
	EC_CE_PLAYED,
	EC_CE_DISCARDED,
	EC_FE_OVERFLOW,
	EC_FE_LEVEL_CHANGED,
	EC_FE_THRESHOLD_REACHED,
	EC_PE_SPOTTED,
	EC_PE_DEATH,
	EC_PE_HIT,
	EC_LE_COLLECTED
}

#enum RunEvent {
	#START, 
	#END, 
	#EVENT_TRIGGERED,
	#EVENT_RESOLVED,
	#EVENT_BLOCKED,
#}
#
#enum CardEvent {
	#CARD_DRAWN,
	#CARD_PLAYED,
	#CARD_DISCARDED
#}
#
#enum FactorEvent {
	#OVERFLOW,
	#LEVEL_CHANGED,
	#MAX_LEVEL_CHANGED,
	#THRESHOLD_REACHED,
#}
#
#enum PlayerEvent {
	#PLAYER_HIT,
	#PLAYER_DEATH,
	#PLAYER_SPOTTED,
#}
#
#enum LootEvent {
	#LOOT_COLLECTED
#}

#@export var id: StringName
#@export var uuid: UUID = UUID.new_uuid()
#@export var display_name: StringName
#@export var description: String
#@export var unique: bool = false
#@export var category: EffectCategory
#@export var duration: float = NAN # NAN means it doesn't have a timer
#@export var stacks: int = -1 # negative means it doesn't consume stacks

#var on_run_event: Callable
#var on_card_event: Callable
#var on_factor_event: Callable
#var on_player_event: Callable
#var on_loot_event: Callable

@export var uuid: UUID = UUID.new_uuid()
@export var description: String
@export var trigger_event: TriggerEvent 
@export var event_category: EventCategory
@export var trigger_filter: StringName
@export var effect_category: EffectCategory
@export var stacks: int = -1 # -1 means infinite
@export var duration: float = NAN # NAN means doesn't expire

@export var on_trigger: Callable


func _init(entry: Dictionary) -> void:
	trigger_event = Utils.parse_string_into_enum(
		TriggerEvent, entry.get("trigger_event", "TE_IMMEDIATE"), "[Effect] - trigger_event") as TriggerEvent
	event_category = Utils.parse_string_into_enum(
		EventCategory, entry.get("event_category", "EC_NONE"), "[Effect] - event_category") as EventCategory
	trigger_filter = StringName(entry.get("trigger_filter", ""))
	effect_category = Utils.parse_string_into_enum(
		EffectCategory, entry.get("effect_category", ""), "[Effect] - effect_category") as EffectCategory
	stacks = int(entry.get("stacks", -1))
	duration = float(entry.get("duration", NAN))
	description = entry.get(
		"description", "-".join([
			EffectCategory.keys()[effect_category], TriggerEvent.keys()[trigger_event], EventCategory.keys()[event_category], trigger_filter, stacks, duration
		]))
	on_trigger = LuaHelper.make_callable(entry.get("on_trigger"))
	
	var parent : Enchantable = entry.get("parent_loot")
	if parent is Enchantable:
		parent.add_effect(self)


func matches(filter: StringName, _event_category: EventCategory = EventCategory.EC_NONE) -> bool:
	if trigger_filter != &"" and trigger_filter != filter:
		return false
	if event_category != EventCategory.EC_NONE and event_category != _event_category:
		return false
	return true


func has_time_remaining() -> bool:
	return is_nan(duration) and duration > 0.0

func can_fire() -> bool:
	return stacks != 0


func fire(params: Dictionary = {}) -> void:
	if not on_trigger.is_valid() or not can_fire():
		return
	on_trigger.call(params)
	if stacks > 0:
		stacks -= 1
