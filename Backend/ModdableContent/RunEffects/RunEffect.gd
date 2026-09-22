class_name RunEffect extends Resource

# Modificadores do sistema de Enchantables (Equipment, Datashard, Addon)
# todos eles possuem efeitos modificadores da run
# A ideia é justamente todos serem um "RunEffect", construído a partir do Lua
# mas, ao menos no "mod base", ser diligente em quais peças (Equipment, Addon ou Datashard)
# podem ter de efeito

enum RunEffectCategory {
	BUFF,
	DEBUFF
}

var id: StringName
var display_name: StringName
var description: String
var unique: bool = false
var category: RunEffectCategory

var on_equip: Callable
var on_unequip: Callable
var on_run_start: Callable

func _init(definition: RunEffectDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	unique = definition.unique
	category = definition.category
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip
	on_run_start = definition.on_run_start


func connect_run_start() -> void:
	Utils.ensure_connected(GameManager.run_manager.run_started, _on_run_started, ConnectFlags.CONNECT_ONE_SHOT)


func _on_run_started() -> void:
	if on_run_start.is_valid():
		on_run_start.call(null)  # TODO: player


func equip() -> void:
	if on_equip.is_valid():
		on_equip.call(id)


func unequip() -> void:
	if on_unequip.is_valid():
		on_unequip.call(id)
