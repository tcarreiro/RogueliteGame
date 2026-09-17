class_name RunEffect extends Resource

# Modificadores do sistema de Gauntlet
# Gauntlet usa um Datashard e tem "slots" de socket para GauntletAddon
# todos eles possuem efeitos modificadores da run
# A ideia é justamente todos serem um "RunEffect", construído a partir do Lua
# mas, ao menos no "mod base", ser diligente em quais peças (Gauntlet, Addon ou Datashard)
# podem ter de efeito
# Em último caso, posso separar em 3 classes iguais, uma para cada peça.

# precisa de API que exponha:
# factors (current_level, max_level, adicionar efeitos no overflow...)
# events (loot rate, loot amount, events intervals...)
# cards (cards de natureza X com efeito adicional (positivo ou negativo)...)

# e aí essa classe irá ter os identificadores para buscar no registry

enum RunEffectStackMode {
	UNIQUE,
	REFRESH,
	STACK
}

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var stack_mode: RunEffectStackMode

# e as "ações" vindas do LUA
