class_name EquipmentDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var tier: int
@export var nature_id: StringName
@export var cost: float
@export var socket_slots: int
@export var type: Equipment.EQUIPMENT_TYPE
var addons: Dictionary[int, Addon] = {} # slot_id
var effects: Dictionary[StringName, RunEffect] = {}

# Gauntlet
@export var max_active_deck_size: int
