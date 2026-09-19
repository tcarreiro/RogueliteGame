class_name RunEffectDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var unique: bool = false
@export var category: RunEffect.RunEffectCategory

@export var on_equip: Callable
@export var on_unequip: Callable
@export var on_run_start: Callable


func _init(entry: Dictionary):
	id = StringName(entry["id"])
	display_name = str(entry.get("display_name", id))
	description = str(entry.get("description", id))
	unique = bool(entry.get("unique", false))
	category = Utils.parse_string_into_enum(
		RunEffect.RunEffectCategory, str(entry.get("category", "BUFF")), "[RunEffectDefinition - category]") as RunEffect.RunEffectCategory
