class_name EventManager extends RefCounted

signal event_resolved(event_id: StringName, value: int)
signal event_blocked(event_id: StringName)

var _events: Dictionary[StringName, Event] = {}
var queue_timers: Dictionary[StringName, float] = {}
var event_queue: Dictionary[StringName, Array] = {} # Array[EventOccurrence]
var block_queue: Dictionary[StringName, Array] = {} # Array[EventBlock]
var queue_throttle: Dictionary[StringName, float] = {} # segundos entre processamentos, vindo de mod data
var _queue_throttle_timers: Dictionary[StringName, float] = {} 
var _speed_multiplier: float = 10.0

func register_event(event: Event, throttle: float = 5.0) -> void:
	if not event:
		push_warning("Event not found.")
		return
	_events[event.id] = event
	event_queue[event.id] = []
	block_queue[event.id] = []
	queue_throttle[event.id] = throttle
	_queue_throttle_timers[event.id] = 0.0
	event.triggered.connect(_on_event_triggered)
	event_resolved.connect(_on_event_resolved)
	event_blocked.connect(_on_event_blocked)
	
	if event is ReactiveEvent:
		event_resolved.connect(event.consider_trigger)


func add_block(event_id: StringName, block: EventBlock) -> void:
	if block_queue.has(event_id):
		block_queue[event_id].append(block)


func _on_event_triggered(event: Event, value: int) -> void:
	if not event_queue.has(event.id):
		return
	event_queue[event.id].append(EventOccurrence.new(event, value))


func _on_event_resolved(event_id: StringName, value: int) -> void:
	var event := GameManager.get_event(event_id)
	if event.on_resolved.is_valid():
		event.on_resolved.call(null, event_id, value)


func _on_event_blocked(event_id: StringName) -> void:
	var event := GameManager.get_event(event_id)
	if event.on_blocked.is_valid():
		event.on_blocked.call(null, event_id)


func process(delta: float) -> void:
	# Process timed events
	for event in _events.values():
		if event is TimedEvent:
			event.process(delta, _speed_multiplier)
	
	for event_id in event_queue:
		var queue: Array = event_queue[event_id]
		if queue.is_empty():
			_queue_throttle_timers[event_id] = 0.0
			continue
		
		_queue_throttle_timers[event_id] += delta
		var throttle: float = queue_throttle.get(event_id, 5.0)
		if _queue_throttle_timers[event_id] >= throttle:
			_queue_throttle_timers[event_id] -= throttle
			_process_next_occurrence(event_id)


func _process_next_occurrence(event_id: StringName) -> void:
	var queue: Array = event_queue[event_id]
	if queue.is_empty():
		return
	
	var occurrence: EventOccurrence = queue.pop_front()
	var projected_occurrences = occurrence.value
	var final_value := _apply_blocks(occurrence.value, block_queue[event_id])
	
	if final_value < projected_occurrences:
		event_blocked.emit(event_id, projected_occurrences - final_value)
	
	if final_value > 0:
		event_resolved.emit(event_id, final_value)


func _apply_blocks(value: int, blocks:Array) -> int:
	var remaining := value
	var i := 0
	
	while (i < blocks.size() and remaining > 0):
		var block: EventBlock = blocks[i]
		var consumed := 0
		
		match block.mode:
			EventBlock.Mode.EVENTS:
				consumed = remaining
				block.amount -= 1 # consume entire event
			EventBlock.Mode.VALUE:
				consumed = min(block.amount, remaining)
				block.amount -= consumed
			EventBlock.Mode.NEXT_EVENT_VALUE:
				consumed = min(block.amount, remaining)
				block.amount = 0 # discards any remaining
	
		remaining -= consumed
		if block.amount <= 0:
			blocks.remove_at(i)
		else:
			i += 1
	
	return remaining


func get_event(event_id: StringName) -> Event:
	return _events.get(event_id)


func get_all_event_ids() -> Array[StringName]:
	return _events.keys()
