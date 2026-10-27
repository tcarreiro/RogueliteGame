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

@export var uuid: UUID = UUID.new_uuid()
@export var display_name: StringName
@export var description: String
@export var trigger_event: TriggerEvent 
@export var event_category: EventCategory
@export var trigger_filter: StringName
@export var effect_category: EffectCategory
@export var stacks: int = -1 # -1 means infinite
@export var duration: float = NAN # NAN means doesn't expire
@export var unique: bool = false

@export var on_trigger: Callable


func _init(entry: Dictionary) -> void:
	display_name = StringName(entry.get("display_name", "NEW_EFFECT"))
	trigger_event = Utils.parse_string_into_enum(
		TriggerEvent, entry.get("trigger_event", "TE_IMMEDIATE"), "[Effect] - trigger_event") as TriggerEvent
	event_category = Utils.parse_string_into_enum(
		EventCategory, entry.get("event_category", "EC_NONE"), "[Effect] - event_category") as EventCategory
	trigger_filter = StringName(entry.get("trigger_filter", ""))
	effect_category = Utils.parse_string_into_enum(
		EffectCategory, entry.get("effect_category", ""), "[Effect] - effect_category") as EffectCategory
	stacks = int(entry.get("stacks", -1))
	duration = float(entry.get("duration", NAN))
	unique = bool(entry.get("unique", false))
	description = entry.get(
		"description", "-".join([
			EffectCategory.keys()[effect_category], TriggerEvent.keys()[trigger_event], EventCategory.keys()[event_category], trigger_filter, str(stacks), str(duration)
		]))
	on_trigger = LuaHelper.make_callable(entry.get("on_trigger"))
	
	var parent = entry.get("parent_loot")
	if parent is Enchantable:
		parent.add_effect(self)


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


func fire(params: Dictionary = {}) -> void:
	if not on_trigger.is_valid() or not can_fire():
		return
	on_trigger.call(params)
	if stacks > 0:
		stacks -= 1
