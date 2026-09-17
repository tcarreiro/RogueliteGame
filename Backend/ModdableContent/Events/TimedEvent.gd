class_name TimedEvent extends Event

@export var timer: float = 0.0
@export var interval: float


func _init(definition: EventDefinition) -> void:
	super(definition)
	interval = definition.interval


func process(delta: float, speed_multiplier) -> void:
	timer += delta * speed_multiplier
	if timer >= interval:
		timer -= interval
		trigger()
