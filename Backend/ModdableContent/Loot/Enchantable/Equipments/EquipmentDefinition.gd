class_name EquipmentDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var tier: int
@export var nature_id: StringName
@export var cost: float
@export var socket_slots: int
@export var type: Equipment.EquipmentType
var addons: Dictionary[int, Addon] = {} # slot_id
@export var effect_ids: Array[StringName] = []

# Gauntlet
@export var max_hand_deck_size: int
@export var max_active_deck_size: int

var on_equip: Callable
var on_unequip: Callable


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
	#var addons: Dictionary[int, Addon] = {} # slot_id
	effect_ids.append_array(entry.get("effect_ids", []))
	max_hand_deck_size = int(entry.get("max_hand_deck_size", 5))
	max_active_deck_size = int(entry.get("max_active_deck_size", 10))


func connect_callables(state: LuaState) -> void:
	on_equip = LuaHelper.make_callable(state.globals["onEquip"])
	on_unequip = LuaHelper.make_callable(state.globals["onUnequip"])


# Four registered functions:
	# setupEffects
	#var setup_effects_fn = state.globals["setupEffects"]
	#if setup_effects_fn is LuaFunction:
		#
		## Immediatly calls setupEffects, so each threshold's callable is registered at definition
		#LuaHelper.call_by_name(state, "setupEffects", [null, String(definition.id)])
