class_name EffectDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var trigger_event: Effect.TriggerEvent 
@export var event_category: Effect.EventCategory
@export var trigger_filter: StringName
@export var effect_category: Effect.EffectCategory
@export var stacks: int
@export var duration: float
@export var unique: bool

var on_trigger: Callable

func _init(entry: Dictionary) -> void:
	id = StringName(entry.get("id", "effect"))
	display_name = StringName(entry.get("display_name", "NEW_EFFECT"))
	trigger_event = Utils.parse_string_into_enum(
		Effect.TriggerEvent, entry.get("trigger_event", "TE_IMMEDIATE"), "[Effect] - trigger_event") as Effect.TriggerEvent
	event_category = Utils.parse_string_into_enum(
		Effect.EventCategory, entry.get("event_category", "EC_NONE"), "[Effect] - event_category") as Effect.EventCategory
	trigger_filter = StringName(entry.get("trigger_filter", ""))
	effect_category = Utils.parse_string_into_enum(
		Effect.EffectCategory, entry.get("effect_category", ""), "[Effect] - effect_category") as Effect.EffectCategory
	stacks = int(entry.get("stacks", -1))
	duration = float(entry.get("duration", NAN))
	unique = bool(entry.get("unique", false))
	description = entry.get(
		"description", "-".join([
			Effect.EffectCategory.keys()[effect_category], Effect.TriggerEvent.keys()[trigger_event], Effect.EventCategory.keys()[event_category], trigger_filter, str(stacks), str(duration)
		]))


func connect_callables(state: LuaState) -> void:
	on_trigger = LuaHelper.make_callable(state.globals["onTrigger"])
