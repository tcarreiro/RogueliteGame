class_name EffectDefinition extends Resource

#enum EffectTrigger {
	#IMMEDIATE,
	#ON_RUN_EVENT,
	#ON_PLAYER_EVENT,
	#ON_LOOT_EVENT
#}

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var unique: bool = false
@export var category: Effect.EffectCategory

#@export var trigger: EffectTrigger
@export var duration: float = INF
@export var stacks: int = -1

var on_run_event: Callable
var on_player_event: Callable
var on_loot_event: Callable


func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	unique = bool(entry.get("unique", false))
	category = Utils.parse_string_into_enum(
		Effect.EffectCategory, str(entry.get("category", "BUFF")), "[CardEffectDefinition - category]") as Effect.EffectCategory
	duration = float(entry.get("duration", INF))
	stacks = int(entry.get("stacks", -1))


func connect_callables(state: LuaState) -> void:
	on_run_event = LuaHelper.make_callable(state.globals["onRunEvent"])
	on_player_event = LuaHelper.make_callable(state.globals["onPlayerEvent"])
	on_loot_event = LuaHelper.make_callable(state.globals["onLootEvent"])
