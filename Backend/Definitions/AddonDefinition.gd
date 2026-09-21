class_name AddonDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var tier: int = 1
@export var nature_id: StringName
@export var suits: Array[StringName] = []
@export var effect_ids: Array[StringName] = []
@export var stackable: bool

var on_run_start: Callable
var on_collect: Callable
var on_spawn: Callable
var on_run_end: Callable
var on_effect_added: Callable
var on_effect_removed: Callable
var on_equip: Callable
var on_unequip: Callable

func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	tier = int(entry.get("tier", 1))
	nature_id = str(entry.get("nature_id", id))
	effect_ids.append_array(entry.get("effect_ids", []))
	suits.append_array(entry.get("suits", []))
	stackable = bool(entry.get("stackable", true))


func connect_callables(state: LuaState) -> void:
	on_run_start = LuaHelper.make_callable(state.globals["onRunStart"])
	on_run_end = LuaHelper.make_callable(state.globals["onRunEnd"])
	on_equip = LuaHelper.make_callable(state.globals["onEquip"])
	on_unequip = LuaHelper.make_callable(state.globals["onUnequip"])
	on_collect = LuaHelper.make_callable(state.globals["onCollect"])
	on_spawn = LuaHelper.make_callable(state.globals["onSpawn"])
	on_effect_added = LuaHelper.make_callable(state.globals["onAddEffect"])
	on_effect_removed = LuaHelper.make_callable(state.globals["onRemoveEffect"])
