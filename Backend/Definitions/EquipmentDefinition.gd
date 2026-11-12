class_name EquipmentDefinition extends ContentDefinition

@export var display_name: StringName
@export var description: String
@export var tier: int
@export var nature_id: StringName
@export var cost: float
@export var socket_slots: int
@export var kind: StringName
@export var addon_ids: Array[StringName] = []
@export var max_stack: int
@export var icon: Texture2D

var on_equip: Callable
var on_unequip: Callable
var on_run_start: Callable
var on_collect: Callable
var on_spawn: Callable
var on_run_end: Callable

# Gauntlet
@export var max_hand_deck_size: int
@export var max_active_deck_size: int

func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	tier = int(entry.get("tier", 1))
	nature_id = str(entry.get("nature_id", id))
	cost = float(entry.get("cost", 0.0))
	socket_slots = int(entry.get("socket_slots", 0))
	kind = StringName(Loot.KIND_PREFIX+entry.get("kind", "gauntlet"))
	addon_ids.append_array(entry.get("addon_ids", []))
	max_hand_deck_size = int(entry.get("max_hand_deck_size", 5))
	max_active_deck_size = int(entry.get("max_active_deck_size", 10))
	max_stack = 1#int(entry.get("max_stack", 1)) # TBD: all equipments are non-stackable
	if entry.get("icon_path"): #TODO: fallback icon
		icon = load(entry.get("icon_path")) as Texture2D


func connect_callables(hooks: LuaTable) -> void:
	on_run_start = LuaHelper.make_callable(hooks.rawget("onRunStart"))
	on_run_end = LuaHelper.make_callable(hooks.rawget("onRunEnd"))
	on_equip = LuaHelper.make_callable(hooks.rawget("onEquip"))
	on_unequip = LuaHelper.make_callable(hooks.rawget("onUnequip"))
	on_collect = LuaHelper.make_callable(hooks.rawget("onCollect"))
	on_spawn = LuaHelper.make_callable(hooks.rawget("onSpawn"))
