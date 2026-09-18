class_name LuaUiAnimationPreset extends Resource

@export var property: String = "offset_transform_scale"  # ou _position, _rotation
@export var from_value: Vector2 = Vector2(1, 1)
@export var to_value: Vector2 = Vector2(1.08, 1.08)
@export var duration: float = 0.12
@export var loop: bool = false
@export var trans_type: Tween.TransitionType = Tween.TRANS_QUAD
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var auto_revert: bool = true
