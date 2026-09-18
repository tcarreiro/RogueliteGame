class_name RunEffectDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var stack_mode: RunEffect.RunEffectStackMode
@export var category: RunEffect.RunEffectCategory

@export var on_equip: Callable
@export var on_unequip: Callable
@export var on_effect_triggered: Callable


func parse_stack_mode(raw: String, run_effect_id: StringName) -> RunEffect.RunEffectStackMode:
	match raw.to_upper():
		"UNIQUE":
			return RunEffect.RunEffectStackMode.UNIQUE
		"REFRESH":
			return RunEffect.RunEffectStackMode.REFRESH
		"STACK":
			return RunEffect.RunEffectStackMode.STACK
		_:
			push_error("[RunEffectDefinition] stack_mode inválido '%s' para run_effect '%s'. Usando UNIQUE como padrão." % [raw, run_effect_id])
			return RunEffect.RunEffectStackMode.UNIQUE
	


func parse_category(raw: String, run_effect_id: StringName) -> RunEffect.RunEffectCategory:
	match raw.to_upper():
		"BUFF":
			return RunEffect.RunEffectCategory.BUFF
		"DEBUFF":
			return RunEffect.RunEffectCategory.DEBUFF
		_:
			push_error("[RunEffectDefinition] category inválido '%s' para run_effect '%s'. Usando BUFF como padrão." % [raw, run_effect_id])
			return RunEffect.RunEffectCategory.BUFF
