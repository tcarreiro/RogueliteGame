class_name RunEffect extends RefCounted

# Modificadores do sistema de Enchantables (Equipment, Datashard, Addon)
# todos eles possuem efeitos modificadores da run
# A ideia é justamente todos serem um "RunEffect", construído a partir do Lua
# mas, ao menos no "mod base", ser diligente em quais peças (Equipment, Addon ou Datashard)
# podem ter de efeito
# Em último caso, posso separar em 3 classes iguais, uma para cada peça.
# Deixando RunEffect como base (similar ao Event) e criando GauntletRunEffect extends RunEffect,
# GauntletAddonRunEffect extends RunEffect e DatashardGauntletAddonRunEffect extends RunEffect

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


func connect_run_start_effects() -> void:
	var sig := GameManager.run_manager.run_started
	if not sig.is_connected(_on_run_started):
		sig.connect(_on_run_started)


func disconnect_run_start_effects() -> void:
	var sig := GameManager.run_manager.run_started
	if sig.is_connected(_on_run_started):
		sig.disconnect(_on_run_started)


func _on_run_started(_config: RunConfig) -> void:
	if on_run_start.is_valid():
		on_run_start.call(null, id)  # TODO: player


func trigger_on_equip() -> void:
	if on_equip.is_valid():
		on_equip.call(id)


func trigger_on_unequip() -> void:
	if on_unequip.is_valid():
		on_unequip.call(id)
