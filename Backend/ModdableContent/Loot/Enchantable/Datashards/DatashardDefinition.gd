class_name DatashardDefinition extends Resource

var id: StringName
var display_name: String
var description: String
var tier: int = 1
var nature_id: StringName

var on_obtained: Callable
var on_run_started: Callable
var on_equip: Callable
var on_unequip: Callable

func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	tier = int(entry.get("tier", 1))
	nature_id = str(entry.get("nature_id", id))
