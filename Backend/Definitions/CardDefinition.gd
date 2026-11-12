class_name CardDefinition extends ContentDefinition

enum CardFlag {
	ETHEREAL, 
	PERMANENT, 
	RETURN_TO_DECK, 
	UNBLOCKABLE,
}

@export var display_name: StringName
@export var description: String
@export var max_stack: int
@export var tier: int = 1
@export var nature_id: StringName
@export var cost: int = 0
@export var max_copies_in_active_deck: int = 3
@export var flags: Array[StringName] = []
@export var icon: Texture2D

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
	max_stack = int(entry.get("max_stack", 0))
	tier = int(entry.get("tier", 1))
	nature_id = str(entry.get("nature_id", id))
	cost = int(entry.get("cost", 1))
	max_copies_in_active_deck = int(entry.get("max_copies_in_active_deck", 3))
	flags.append_array(entry.get("flags", []))
	if entry.get("icon_path"): #TODO: fallback icon
		icon = load(entry.get("icon_path")) as Texture2D


func connect_callables(hooks: LuaTable) -> void:
	on_run_start = LuaHelper.make_callable(hooks.rawget("onRunStart"))
	on_run_end = LuaHelper.make_callable(hooks.rawget("onRunEnd"))
	on_collect = LuaHelper.make_callable(hooks.rawget("onCollect"))
	on_spawn = LuaHelper.make_callable(hooks.rawget("onSpawn"))
	on_drawn = LuaHelper.make_callable(hooks.rawget("onDrawn"))
	on_played = LuaHelper.make_callable(hooks.rawget("onPlayed"))
	on_discarded = LuaHelper.make_callable(hooks.rawget("onDiscarded"))
	on_destroyed = LuaHelper.make_callable(hooks.rawget("onDestroyed"))
	on_blocked = LuaHelper.make_callable(hooks.rawget("onBlocked"))
	
