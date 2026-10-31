class_name EventManager extends Resource

signal event_triggered(event_id: StringName, amount: int)
signal event_resolved(event_id: StringName, amount: int)
signal event_blocked(event_id: StringName, amount: int)

var _events: Dictionary[StringName, Event] = {}
var queue_timers: Dictionary[StringName, float] = {}
var event_queue: Dictionary[StringName, Array] = {} # Array[EventOccurrence]
var block_queue: Dictionary[StringName, Array] = {} # Array[EventBlock]
var queue_throttle: Dictionary[StringName, float] = {} # segundos entre processamentos, vindo de mod data
var _queue_throttle_timers: Dictionary[StringName, float] = {} 

func register_event(event: Event, throttle: float = 5.0) -> void:
	if not event:
		GameLogger.error("Event not found.")
		return
	_events[event.id] = event
	#event.created() # TODO
	event_queue[event.id] = []
	block_queue[event.id] = []
	queue_throttle[event.id] = throttle
	_queue_throttle_timers[event.id] = 0.0
	event.triggered.connect(_on_event_triggered)
	if event is ReactiveEvent:
		event_resolved.connect(event.consider_trigger)


func add_block(event_id: StringName, block: EventBlock) -> void:
	if block_queue.has(event_id):
		block_queue[event_id].append(block)


func remove_block(event_id: StringName, p_block: EventBlock) -> void:
	if block_queue.has(event_id):
		for block:EventBlock in block_queue[event_id]:
			if block.mode == p_block.mode:
				block.amount -= p_block.amount
				if block.amount <= 0:
					block_queue[event_id].erase(block)


func _on_event_triggered(event: Event, value: int) -> void:
	event_queue[event.id].append(EventOccurrence.new(event, value))
	event_triggered.emit(event.id, value)


func process(delta: float, speed_multiplier: float = 1.0) -> void:
	# Process timed events
	for event in _events.values():
		if event is TimedEvent:
			event.process(delta, speed_multiplier)
	
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
	var remaining_occurrences := _apply_blocks(occurrence.value, block_queue[event_id])
	
	if remaining_occurrences < projected_occurrences:
		event_blocked.emit(event_id, projected_occurrences - remaining_occurrences)
		_events[event_id].block_event(projected_occurrences - remaining_occurrences)
	
	if remaining_occurrences > 0:
		event_resolved.emit(event_id, remaining_occurrences)
		_events[event_id].resolve_event(remaining_occurrences)


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
