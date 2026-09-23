class_name EquipmentDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var tier: int
@export var nature_id: StringName
@export var cost: float
@export var socket_slots: int
@export var type: Equipment.EquipmentType
@export var addon_ids: Array[StringName] = []
@export var stackable: bool

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
	type = Utils.parse_string_into_enum(
		Equipment.EquipmentType, str(entry.get("type", "GAUNTLET")), "[EquipmentDefinition - type]") as Equipment.EquipmentType
	addon_ids.append_array(entry.get("addon_ids", []))
	max_hand_deck_size = int(entry.get("max_hand_deck_size", 5))
	max_active_deck_size = int(entry.get("max_active_deck_size", 10))


func connect_callables(state: LuaState) -> void:
	on_run_start = LuaHelper.make_callable(state.globals["onRunStart"])
	on_run_end = LuaHelper.make_callable(state.globals["onRunEnd"])
	on_equip = LuaHelper.make_callable(state.globals["onEquip"])
	on_unequip = LuaHelper.make_callable(state.globals["onUnequip"])
	on_collect = LuaHelper.make_callable(state.globals["onCollect"])
	on_spawn = LuaHelper.make_callable(state.globals["onSpawn"])
