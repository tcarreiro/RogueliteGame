extends Control

@onready var timer_label: Label = %TimerLabel
@onready var equipments_label: Label = %EquipmentsLabel
@onready var factor_container: VBoxContainer = %Factors
var _factors: Dictionary[StringName, Label] = {}

@onready var event_container: VBoxContainer = %Events
var _events: Dictionary[StringName, Label] = {}

func _ready() -> void:
	GameManager.run_manager.run_ticked.connect(_on_run_ticked)
	GameManager.run_manager.run_started.connect(_on_run_started)
	GameManager.run_manager.run_ended.connect(_on_run_ended)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if GameManager.run_manager.is_run_active():
			GameManager.run_manager.end_run(true)
		else:
			if GameManager.get_active_datashard():
				GameManager.run_manager.start_run()
			else:
				GameLogger.debug("No datashard equipped")


func _on_run_ended(_success:bool) -> void:
	pass


func _clear_infos() -> void:
	_factors.clear()
	for child in factor_container.get_children():
		child.queue_free()
	_events.clear()
	for child in event_container.get_children():
		child.queue_free()


func _on_run_started(_config: RunConfig) -> void:
	GameManager.run_manager.event_manager.event_resolved.connect(_on_event_resolved)
	GameManager.run_manager.event_manager.event_blocked.connect(_on_event_blocked)
	_clear_infos()
	_create_loot_info()
	_create_factor_info()
	_create_event_info()


func _create_loot_info() -> void:
	var text :PackedStringArray= []
	for loot: Loot in GameManager.run_manager.equipment_manager.get_all_loot():
		text.append(loot.display_name)
	equipments_label.text = ", ".join(text)


func _create_factor_info() -> void:
	var all_factor_ids = GameManager.run_manager.factor_manager.get_all_factor_ids()
	var container_label := Label.new()
	container_label.text = "Factors"
	factor_container.add_child(container_label)
	
	for factor_id in all_factor_ids:
		var factor : Factor = GameManager.get_factor(factor_id)
		if factor == null:
			continue
		var container := HBoxContainer.new()
		var fac_label := Label.new()
		fac_label.text = factor.display_name
		var fac_val := Label.new()
		fac_val.text = "%s/%s"%[factor.current_level, factor.max_level]
		container.add_child(fac_label)
		container.add_child(fac_val)
		factor_container.add_child(container)
		_factors[factor.id] = fac_val
		factor.level_changed.connect(_on_factor_changed)


func _create_event_info() -> void:
	var all_event_ids = GameManager.run_manager.event_manager.get_all_event_ids()
	var container_label := Label.new()
	container_label.text = "Events (resolved|blocked)"
	event_container.add_child(container_label)
	
	for event_id in all_event_ids:
		var event : Event = GameManager.get_event(event_id)
		if event == null:
			continue
		var container := HBoxContainer.new()
		var ev_label := Label.new()
		ev_label.text = event.name
		var ev_val := Label.new()
		ev_val.text = "0|0"
		container.add_child(ev_label)
		container.add_child(ev_val)
		event_container.add_child(container)
		_events[event.id] = ev_val
		


func _on_run_ticked(run_state: RunState) -> void:
	timer_label.text = Utils.format_timer(run_state.elapsed_time)


func _on_factor_changed(factor: Factor) -> void:
	_factors[factor.id].text = "%s/%s"%[factor.current_level, factor.max_level]


func _on_event_blocked(event_id: StringName, amount: int) -> void:
	var values = _split_events(event_id)
	_events[event_id].text = "%s|%s" % [values[0], int(values[1] + amount)]


func _on_event_resolved(event_id: StringName, amount: int) -> void:
	var values = _split_events(event_id)
	_events[event_id].text = "%s|%s" % [int(values[0]) + amount, values[1]]


func _split_events(event_id: StringName) -> Array:
	var old_text := _events[event_id].text.split("|")
	var resolved = old_text
	var blocked = "0"
	if old_text is PackedStringArray:
		resolved = old_text[0]
		blocked = old_text[1]
	return [resolved, blocked]
