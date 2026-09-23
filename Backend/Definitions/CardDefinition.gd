class_name CardDefinition extends Resource

enum CardFlag {
	ETHEREAL, 
	PERMANENT, 
	RETURN_TO_DECK, 
	UNBLOCKABLE,
}

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var stackable: bool
@export var tier: int = 1
@export var nature_id: StringName
@export var cost: int = 0
@export var max_copies_in_active_deck: int = 3
@export var flags: Array[StringName] = []
@export var effect_ids: Array[StringName] = []

var on_run_start: Callable
var on_run_end: Callable
var on_collect: Callable
var on_spawn: Callable
var on_drawn: Callable
var on_played: Callable
var on_discarded: Callable
var on_destroyed: Callable
var on_blocked: Callable

func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	stackable = bool(entry.get("stackable", true))
	tier = int(entry.get("tier", 1))
	nature_id = str(entry.get("nature_id", id))
	cost = int(entry.get("cost", 1))
	effect_ids.append_array(entry.get("effect_ids", []))
	max_copies_in_active_deck = int(entry.get("max_copies_in_active_deck", 1))
	flags.append_array(entry.get("flags", []))


func connect_callables(state: LuaState) -> void:
	on_run_start = LuaHelper.make_callable(state.globals["onRunStart"])
	on_run_end = LuaHelper.make_callable(state.globals["onRunEnd"])
	on_collect = LuaHelper.make_callable(state.globals["onCollect"])
	on_spawn = LuaHelper.make_callable(state.globals["onSpawn"])
	on_drawn = LuaHelper.make_callable(state.globals["onDrawn"])
	on_played = LuaHelper.make_callable(state.globals["onPlayed"])
	on_discarded = LuaHelper.make_callable(state.globals["onDiscarded"])
	on_destroyed = LuaHelper.make_callable(state.globals["onDestroyed"])
	on_blocked = LuaHelper.make_callable(state.globals["onBlocked"])
