class_name RunEffectDefinition extends Resource

@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var stack_mode: RunEffect.RunEffectStackMode
@export var category: RunEffect.RunEffectCategory

@export var on_equip: Callable
@export var on_unequip: Callable
@export var on_effect_triggered: Callable
