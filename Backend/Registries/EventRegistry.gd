#EventRegistry
extends Node

var _definitions: Dictionary[StringName, EventDefinition] = {}

func load_from_mods(active_mods: Array[StringName]) -> void:
	for mod_id in active_mods:
		_load_from_mod(mod_id)


func _load_from_mod(mod_id: StringName) -> void:
	# TODO: get from ModManager
	#var metadata := ModManager.get_metadata(mod_id)
	#if not metadata:
		#return
	#var event_path := metadata.folder_path.path_join("event")
	# TODO real: DirAccess.open(event_path), listar *.lua, parsear cada um
	# chamando register() por resultado.
	for definition in _mock_definitions_for(mod_id):
		register(definition)


func register(definition: EventDefinition) -> void:
	if _definitions.has(definition.id):
		push_warning("Event %s already registered."%definition.id)
		return
	_definitions[definition.id] = definition
	print("Event %s registered."%definition.id)


func get_definition(id: StringName) -> EventDefinition:
	return _definitions.get(id)


func get_all_definitions() -> Array[EventDefinition]:
	return _definitions.values()


func get_all_ids() -> Array[StringName]:
	return _definitions.keys()


func create_event(id: StringName) -> Event:
	var definition := get_definition(id)
	if not definition:
		return null
	match definition.event_trigger:
		Event.EventTrigger.TIMED:
			return TimedEvent.new(definition)
		Event.EventTrigger.REACTIVE:
			return ReactiveEvent.new(definition)
	return null


#region Mock
func _mock_definitions_for(mod_id: StringName) -> Array[EventDefinition]:
	if mod_id != &"base_mod":
		return []
	
	var resonance := EventDefinition.new()
	resonance.id = &"resonance_event"
	resonance.name = &"Resonance Event"
	resonance.event_trigger = Event.EventTrigger.TIMED
	resonance.interval = 30.0
	resonance.throttle = 5.0
	
	var surrender := EventDefinition.new()
	surrender.id = &"surrender_event"
	surrender.name = &"Surrender Event"
	surrender.event_trigger = Event.EventTrigger.REACTIVE
	
	var distortion := EventDefinition.new()
	distortion.id = &"distortion_event"
	distortion.name = &"Distortion Event"
	distortion.event_trigger = Event.EventTrigger.TIMED
	distortion.interval = 40.0
	distortion.throttle = 5.0
	
	var card_draw := EventDefinition.new()
	card_draw.id = &"card_draw_event"
	card_draw.name = &"Card Draw Event"
	card_draw.event_trigger = Event.EventTrigger.TIMED
	card_draw.interval = 30.0
	card_draw.throttle = 0.3
	
	var stumble := EventDefinition.new()
	stumble.id = &"stumble_event"
	stumble.name = &"Stumble Event"
	stumble.event_trigger = Event.EventTrigger.REACTIVE
	stumble.watched_event_id = &"card_draw_event"
	stumble.conditional = _stumble_conditional_mock
	
	return [resonance, surrender, distortion, card_draw, stumble]


func _stumble_conditional_mock(_resolved_event_id: StringName, _value: int) -> bool:
	if randf() < .5:
		return true
	return false

#endregion
