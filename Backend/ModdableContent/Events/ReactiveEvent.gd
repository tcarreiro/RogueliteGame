class_name ReactiveEvent extends Event

var watched_event_id: StringName
var conditional: Callable

func _init(definition: EventDefinition) -> void:
	super(definition)
	watched_event_id = definition.watched_event_id
	conditional = definition.conditional


func consider_trigger(resolved_event_id: StringName, value: int) -> void:
	if resolved_event_id != watched_event_id:
		return
	if not conditional.is_valid() or (conditional.is_valid() and not conditional.call(resolved_event_id, value)):
		return
	print("stumble!")
	trigger(value)
