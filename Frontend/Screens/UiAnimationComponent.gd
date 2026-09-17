class_name UiAnimationComponent extends Node

signal animation_ended

enum AnimationType {
	HOVER,
	ENTER
}

@export_category("Options")
@export var type: AnimationType
@export var from_center: bool = true
@export var parallel_animations: bool = true
@export var properties: Array = [
	"scale",
	"position", 
	"rotation",
	"size"
]

@export_category("Hover settings")
@export var anim_duration: float = 0.1
@export var anim_delay: float = 0.1
@export var anim_transition: Tween.TransitionType
@export var anim_easing: Tween.EaseType
@export var anim_scale: Vector2 = Vector2.ONE
@export var anim_position: Vector2
@export var anim_rotation: float
@export var anim_size: Vector2 
@export var wait_for: UiAnimationComponent

var parent: Node
var default_values : Dictionary = {}
var anim_values : Dictionary = {}

func _ready() -> void:
	parent = get_parent()
	call_deferred("_setup")

func _setup() -> void:
	if from_center:
		parent.pivot_offset = parent.size / 2

	for property in properties:
		default_values[property] = parent.get(property)

	anim_values = {
		"scale": anim_scale,
		"position": parent.position + anim_position, 
		"rotation": parent.rotation + deg_to_rad(anim_rotation),
		"size": parent.size + anim_size, 
	}

	_connect_signals()
	
	if type == AnimationType.ENTER:
		_on_enter()

func _on_enter() -> void:
	add_tween(anim_values, true, 0, 0, Tween.TransitionType.TRANS_LINEAR, anim_easing)
	
	if wait_for:
		pass
	else:
		add_tween(default_values, parallel_animations, anim_duration, anim_delay, anim_transition, anim_easing, true)

func _connect_signals() -> void:
	if type == AnimationType.HOVER:
		parent.mouse_entered.connect(add_tween.bind(
			anim_values,
			parallel_animations,
			anim_duration,
			anim_delay,
			anim_transition,
			anim_easing
		))
		parent.mouse_exited.connect(add_tween.bind(
			default_values,
			parallel_animations,
			anim_duration,
			anim_delay,
			anim_transition,
			anim_easing
		))
	
	if wait_for:
		wait_for.animation_ended.connect(add_tween.bind(
			default_values,
			parallel_animations,
			anim_duration,
			anim_delay,
			anim_transition,
			anim_easing,
			true
		))

func add_tween(values:Dictionary, parallel: bool, duration: float, delay: float, transition_type: Tween.TransitionType, ease_type: Tween.EaseType, should_emit_signal:bool = false) -> void:
	var tween = parent.create_tween()
	tween.set_parallel(parallel)
	tween.pause()
	for property in properties:
		tween.tween_property(parent, str(property), values[property], duration).set_trans(transition_type).set_ease(ease_type)
	if get_tree():
		await get_tree().create_timer(delay).timeout
	tween.play()
	if should_emit_signal:
		await tween.finished
		animation_ended.emit()
