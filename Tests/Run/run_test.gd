extends Control

signal gauntlet_selected()
signal datashard_selected()
signal deck_updated()

@onready var header: HBoxContainer = %Header
@onready var hub_container: HBoxContainer = %HubContainer
@onready var run_container: VBoxContainer = %RunContainer
@onready var run_btn: Button = %RunBtn
@onready var timer: HBoxContainer = %Timer

## Hub
@onready var selected_datashard: Label = %SelectedDatashard
@onready var selected_gauntlet: Label = %SelectedGauntlet

@onready var gauntlet_container: VBoxContainer = %GauntletContainer
var _gauntlets: Dictionary[StringName, Button] = {}
var _selected_gauntlet_btn: Button

@onready var datashards_container: VBoxContainer = %DatashardsContainer
var _datashards: Dictionary[StringName, Button] = {}
var _selected_datashard_btn: Button

@onready var effects_container: VBoxContainer = %EffectsContainer
var _effects: Dictionary[UUID, Label] = {}

@onready var cards_container: GridContainer = %CardsContainer
var _cards: Dictionary[UUID, CheckButton] = {}

@onready var selected_cards_container: GridContainer = %SelectedCardsContainer
var _selected_cards: Dictionary[UUID, Button] = {}

## Run
@onready var timer_label: Label = %TimerLabel

@onready var factor_container: VBoxContainer = %Factors
var _factors: Dictionary[StringName, Label] = {}

@onready var event_container: VBoxContainer = %Events
var _events: Dictionary[StringName, Label] = {}

func _ready() -> void:
	GameManager.run_manager.run_ticked.connect(_on_run_ticked)
	GameManager.run_manager.run_started.connect(_on_run_started)
	GameManager.run_manager.run_ended.connect(_on_run_ended)
	run_btn.pressed.connect(_run_btn)
	datashard_selected.connect(func():
		run_btn.disabled = false
		_create_effects_info()
	)
	gauntlet_selected.connect(func():
		run_btn.disabled = GameManager.get_active_datashard() == null
		_create_effects_info()
	)
	deck_updated.connect(_create_cards_container)
	deck_updated.connect(_create_selected_cards_container)
	goto_hub()


func goto_hub() -> void:
	hub_container.show()
	run_container.hide()
	
	gauntlet_container.show()
	datashards_container.show()
	timer.hide()
	
	selected_datashard.show()
	var text = ""
	if GameManager.get_active_datashard():
		text = GameManager.get_active_datashard().display_name
	selected_datashard.text = text
	
	selected_gauntlet.show()
	if GameManager.get_equipped_gauntlet():
		text = GameManager.get_equipped_gauntlet().display_name
	selected_gauntlet.text = text
	
	run_btn.disabled = GameManager.get_active_datashard() == null
	run_btn.text = "Start Run"
	
	_create_gauntlets_info()
	_create_datashards_info()
	_create_cards_container()
	_create_selected_cards_container()
	_create_effects_info()


func _create_cards_container() -> void:
	_cards.clear()
	for child in cards_container.get_children():
		child.queue_free()
	
	var card_collection = GameManager.get_permanent_deck()
	for card in card_collection:
		var card_btn := CheckButton.new()
		card_btn.text = card.display_name
		cards_container.add_child(card_btn)
		card_btn.button_pressed = GameManager.get_active_deck().has(card)
		card_btn.pressed.connect(_on_activate_card.bind(card))
		_cards[card.uuid] = card_btn


func _on_activate_card(card: Card) -> void:
	if GameManager.get_active_deck().has(card):
		_on_deactivate_card(card)
		return
	if GameManager.activate_card(card):
		deck_updated.emit()


func _create_selected_cards_container() -> void:
	_selected_cards.clear()
	for child in selected_cards_container.get_children():
		child.queue_free()
	
	var card_collection = GameManager.get_active_deck()
	for card in card_collection:
		var card_btn := Button.new()
		card_btn.text = card.display_name
		selected_cards_container.add_child(card_btn)
		card_btn.pressed.connect(_on_deactivate_card.bind(card))
		_selected_cards[card.uuid] = card_btn


func _on_deactivate_card(card: Card) -> void:
	if GameManager.deactivate_card(card):
		deck_updated.emit()


func goto_run() -> void:
	hub_container.hide()
	run_container.show()
	timer.show()
	
	gauntlet_container.hide()
	datashards_container.hide()
	
	run_btn.text = "End Run"
	GameManager.get_run_deck_manager().card_drawn.connect(_on_card_drawn)


func _on_card_drawn(card: Card) -> void:
	var btn := Button.new()
	btn.text = card.display_name
	btn.pressed.connect(func():
		var played_card := GameManager.get_run_deck_manager().play(card.uuid)
		if played_card:
			btn.queue_free()
	)
	run_container.add_child(btn)


func _run_btn() -> void:
	if GameManager.run_manager.is_run_active():
		GameManager.run_manager.end_run(true)
		goto_hub()
	else:
		if GameManager.get_active_datashard():
			GameManager.run_manager.start_run()
			goto_run()
		else:
			GameLogger.debug("No datashard equipped")


func _on_run_ended(_success:bool) -> void:
	pass


func _create_gauntlets_info() -> void:
	_gauntlets.clear()
	for child in gauntlet_container.get_children():
		child.queue_free()
		
	var available_gauntlets = GameManager.get_available_gauntlets()
	var container_label := Label.new()
	container_label.text = "Gauntlets"
	gauntlet_container.add_child(container_label)
	for gauntlet: Gauntlet in available_gauntlets:
		var gauntlet_btn := Button.new()
		gauntlet_btn.text = gauntlet.display_name
		gauntlet_container.add_child(gauntlet_btn)
		gauntlet_btn.pressed.connect(_on_gauntlet_selected.bind(gauntlet_btn, gauntlet))
		_gauntlets[gauntlet.id] = gauntlet_btn


func _on_gauntlet_selected(gauntlet_btn: Button, gauntlet: Gauntlet) -> void:
	GameManager.equip_gauntlet(gauntlet)

	_selected_gauntlet_btn = gauntlet_btn
	gauntlet_selected.emit()
	selected_gauntlet.text = gauntlet.display_name
	selected_datashard.text = gauntlet.get_equipped_datashard().display_name if gauntlet.get_equipped_datashard() else &""


func _create_datashards_info() -> void:
	_datashards.clear()
	for child in datashards_container.get_children():
		child.queue_free()
		
	var unlocked_datashards = GameManager.get_unlocked_datashards()
	var container_label := Label.new()
	container_label.text = "Datashards"
	datashards_container.add_child(container_label)
	
	for datashard in unlocked_datashards:
		var datashard_btn := Button.new()
		datashard_btn.text = datashard.display_name
		datashards_container.add_child(datashard_btn)
		if not GameManager.get_equipped_gauntlet():
			datashard_btn.disabled = true
		datashard_btn.pressed.connect(_on_datashard_selected.bind(datashard_btn, datashard))
		gauntlet_selected.connect(func(): datashard_btn.disabled = false, ConnectFlags.CONNECT_ONE_SHOT)
		_datashards[datashard.id] = datashard_btn


func _on_datashard_selected(datashard_btn: Button, datashard: Datashard) -> void:
	GameManager.equip_datashard(datashard)
	datashard_selected.emit()
	_selected_datashard_btn = datashard_btn
	selected_datashard.text = datashard.display_name


func _create_effects_info() -> void:
	_effects.clear()
	for child in effects_container.get_children():
		child.queue_free()
	
	var active_effects = GameManager.get_active_effects()
	var container_label := Label.new()
	container_label.text = "Run Effects"
	effects_container.add_child(container_label)
	
	for effect in active_effects:
		var effects_label := Label.new()
		effects_label.text = effect.display_name
		effects_container.add_child(effects_label)
		_effects[effect.uuid] = effects_label


func _on_run_started() -> void:
	GameManager.run_manager.run_state.event_manager.event_resolved.connect(_on_event_resolved)
	GameManager.run_manager.run_state.event_manager.event_blocked.connect(_on_event_blocked)
	_create_factor_info()
	_create_event_info()


func _create_factor_info() -> void:
	_factors.clear()
	for child in factor_container.get_children():
		child.queue_free()
		
	var all_factor_ids = GameManager.get_factor_manager().get_all_factor_ids()
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
		fac_val.text = "%s/%s (%s)"%[factor.current_level, factor.max_level, factor.blocks]
		container.add_child(fac_label)
		container.add_child(fac_val)
		factor_container.add_child(container)
		_factors[factor.id] = fac_val
		factor.level_changed.connect(_on_factor_changed)
		factor.factor_block_added.connect(_on_factor_changed)
		factor.factor_blocked.connect(_on_factor_changed)


func _create_event_info() -> void:
	_events.clear()
	for child in event_container.get_children():
		child.queue_free()
	
	var all_event_ids = GameManager.get_event_manager().get_all_event_ids()
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
	_factors[factor.id].text = "%s/%s (%s)"%[factor.current_level, factor.max_level, factor.blocks]


func _on_event_blocked(event_id: StringName, amount: int) -> void:
	var values = _split_events(event_id)
	_events[event_id].text = "%s|%s" % [int(values[0]), (int(values[1]) + amount)]


func _on_event_resolved(event_id: StringName, amount: int) -> void:
	var values = _split_events(event_id)
	_events[event_id].text = "%s|%s" % [int(values[0]) + amount, int(values[1])]


func _split_events(event_id: StringName) -> Array:
	var old_text := _events[event_id].text.split("|")
	var resolved = old_text
	var blocked = "0"
	if old_text is PackedStringArray:
		resolved = old_text[0]
		blocked = old_text[1]
	return [resolved, blocked]
