class_name RunEffect extends RefCounted

# Modificadores do sistema de Gauntlet
# Gauntlet usa um Datashard e tem "slots" de socket para GauntletAddon
# todos eles possuem efeitos modificadores da run
# A ideia é justamente todos serem um "RunEffect", construído a partir do Lua
# mas, ao menos no "mod base", ser diligente em quais peças (Gauntlet, Addon ou Datashard)
# podem ter de efeito
# Em último caso, posso separar em 3 classes iguais, uma para cada peça.
# Deixando RunEffect como base (similar ao Event) e criando GauntletRunEffect extends RunEffect,
# GauntletAddonEffect extends RunEffect e DatashardGauntletAddonEffect extends RunEffect

# Deprecated
enum RunEffectStackMode {
	UNIQUE,
	REFRESH,
	STACK
}

enum RunEffectCategory {
	BUFF,
	DEBUFF
}

var id: StringName
var display_name: StringName
var description: String
#var stack_mode: RunEffectStackMode
var unique: bool = false
var category: RunEffectCategory

var on_equip: Callable
var on_unequip: Callable
var on_effect_triggered: Callable

func _init(definition: RunEffectDefinition) -> void:
	id = definition.id
	display_name = definition.display_name
	description = definition.description
	#stack_mode = definition.stack_mode
	unique = definition.unique
	category = definition.category
	on_equip = definition.on_equip
	on_unequip = definition.on_unequip
	on_effect_triggered = definition.on_effect_triggered
