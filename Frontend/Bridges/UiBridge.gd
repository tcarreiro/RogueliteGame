class_name UiBridge extends RefCounted
## Ponte entre o Lua de UI (LuaUi.state) e o jogo. Irmã do ContentBridge, mas para a UI:
## o ContentBridge registra no estado de cada MOD; este registra só no estado da UI, então um mod
## não alcança Game.toggleRun() & cia.
##
## Duas mãos, nenhuma passa objeto do jogo para o Lua:
##   jogo -> Lua : stores reativas (UI.store("run_screen") / UI.store("run_clock")) com dados simples
##   Lua -> jogo : funções Game.*(id), que recebem só texto e resolvem o objeto aqui dentro

const STATE_NAME := &"ui"
const NAMESPACE := &"Game"
const NONE_LABEL := "-"

var screen := ReactiveDictionary.new()
var clock := ReactiveDictionary.new({"timer": "00:00:00"})

var _event_counts: Dictionary = {}   # event_id -> Vector2i(resolved, blocked)
var _run_links: Array = []           # [Signal, Callable] ligados só durante a run


#region Ciclo de vida
func attach() -> void:
	if LuaBridgeRegistry.get_lua_state(STATE_NAME) == null:
		LuaBridgeRegistry.register_state(STATE_NAME, LuaUi.state)
	LuaUi.expose_store("run_screen", screen, true)
	LuaUi.expose_store("run_clock", clock, true)
	_register_actions()

	var rm := GameManager.run_manager
	rm.run_started.connect(_on_run_started)
	rm.run_ended.connect(_on_run_ended)
	rm.run_ticked.connect(_on_run_ticked)
	if rm.is_run_active():
		_on_run_started()
	else:
		refresh()


func detach() -> void:
	var rm := GameManager.run_manager
	for pair in [[rm.run_started, _on_run_started], [rm.run_ended, _on_run_ended], [rm.run_ticked, _on_run_ticked]]:
		if pair[0].is_connected(pair[1]):
			pair[0].disconnect(pair[1])
	_disconnect_run()
	LuaUi.state.globals[NAMESPACE] = null


func _register_actions() -> void:
	LuaUi.state.globals[NAMESPACE] = null
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "selectGauntlet", lua_select_gauntlet)
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "selectDatashard", lua_select_datashard)
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "toggleCard", lua_toggle_card)
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "playCard", lua_play_card)
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "toggleRun", lua_toggle_run)
	LuaBridgeRegistry.lua_register(STATE_NAME, NAMESPACE, "playSoundEffect", lua_play_sound_effect)
#endregion


#region Lua -> jogo (todas validam a fase e resolvem o id aqui dentro)
func lua_select_gauntlet(id: Variant) -> bool:
	if GameManager.run_manager.is_run_active():
		return false
	var gauntlet: Variant = _find_by_id(GameManager.get_available_gauntlets(), str(id))
	if gauntlet == null:
		return false
	GameManager.equip_gauntlet(gauntlet)
	refresh()
	return true


func lua_select_datashard(id: Variant) -> bool:
	if GameManager.run_manager.is_run_active() or GameManager.get_equipped_gauntlet() == null:
		return false
	var datashard: Variant = _find_by_id(GameManager.get_unlocked_datashards(), str(id))
	if datashard == null:
		return false
	GameManager.equip_datashard(datashard)
	refresh()
	return true


func lua_toggle_card(uuid: Variant) -> bool:
	if GameManager.run_manager.is_run_active():
		return false
	var card: Card = _find_card(GameManager.get_permanent_deck(), str(uuid))
	if card == null:
		return false
	var ok: bool = GameManager.deactivate_card(card) if GameManager.get_active_deck().has(card) else GameManager.activate_card(card)
	refresh()
	return ok


func lua_play_card(uuid: Variant) -> bool:
	if not GameManager.run_manager.is_run_active():
		return false
	var deck := GameManager.get_run_deck_manager()
	var card: Card = _find_card(deck.hand_pile.get_cards(), str(uuid))
	return card != null and deck.play(card.uuid) != null


func lua_toggle_run() -> void:
	var rm := GameManager.run_manager
	if rm.is_run_active():
		rm.end_run(true)
	elif GameManager.get_active_datashard() != null:
		rm.start_run()
	else:
		GameLogger.debug("No datashard equipped")


func lua_play_sound_effect(sound_name: StringName) -> void:
	#TODO create sound registry
	#TODO AudioManager autoload?
	#TODO AudioManager.play_at_bus(sound_name, bus_name)
	print("play sound %s"%[sound_name])

#endregion


#region jogo -> Lua
func refresh() -> void:
	screen.assign(_build_snapshot())


func _build_snapshot() -> Dictionary:
	var in_run := GameManager.run_manager.is_run_active()
	var gauntlet := GameManager.get_equipped_gauntlet()
	var shard := GameManager.get_active_datashard()
	var active_uuids := {}
	for card: Card in GameManager.get_active_deck():
		active_uuids[str(card.uuid)] = true

	var gauntlets: Array = []
	for g: Gauntlet in GameManager.get_available_gauntlets():
		gauntlets.append({"id": str(g.id), "name": str(g.display_name), "disabled": false,
				"selected": gauntlet != null and g.id == gauntlet.id})

	var datashards: Array = []
	for d: Datashard in GameManager.get_unlocked_datashards():
		datashards.append({"id": str(d.id), "name": str(d.display_name), "disabled": gauntlet == null,
				"selected": shard != null and d.id == shard.id})

	var cards: Array = []
	for c: Card in GameManager.get_permanent_deck():
		cards.append({"uuid": str(c.uuid), "name": str(c.display_name), "active": active_uuids.has(str(c.uuid))})

	var active_cards: Array = []
	for c: Card in GameManager.get_active_deck():
		active_cards.append({"uuid": str(c.uuid), "name": str(c.display_name)})

	var effects: Array = []
	for e: Effect in GameManager.get_active_effects():
		effects.append({"name": str(e.display_name)})

	return {
		"phase": "run" if in_run else "hub",
		"can_toggle_run": in_run or shard != null,
		"selected_gauntlet": str(gauntlet.display_name) if gauntlet else NONE_LABEL,
		"selected_datashard": str(shard.display_name) if shard else NONE_LABEL,
		"gauntlets": gauntlets,
		"datashards": datashards,
		"cards": cards,
		"active_cards": active_cards,
		"effects": effects,
		"factors": _factors_snapshot() if in_run else [],
		"events": _events_snapshot() if in_run else [],
		"hand": _hand_snapshot() if in_run else [],
	}


func _factors_snapshot() -> Array:
	var out: Array = []
	var manager := GameManager.get_factor_manager()
	for id in manager.get_all_factor_ids():
		var f: Factor = manager.get_factor(id)
		if f == null:
			continue
		out.append({"id": str(f.id), "name": str(f.display_name),
				"text": "%s/%s (%s)" % [f.current_level, f.max_level, f.blocks]})
	return out


func _events_snapshot() -> Array:
	var out: Array = []
	for id in GameManager.get_event_manager().get_all_event_ids():
		var event: Event = GameManager.get_event(id)
		if event == null:
			continue
		var counts: Vector2i = _event_counts.get(id, Vector2i.ZERO)
		out.append({"id": str(id), "name": event.name, "text": "%s|%s" % [counts.x, counts.y]})
	return out


func _hand_snapshot() -> Array:
	var out: Array = []
	for c: Card in GameManager.get_run_deck_manager().hand_pile.get_cards():
		out.append({"uuid": str(c.uuid), "name": str(c.display_name)})
	return out
#endregion


#region Sinais do jogo
func _on_run_started() -> void:
	var run_state := GameManager.get_run_state()
	_event_counts.clear()
	for id in run_state.event_manager.get_all_event_ids():
		_event_counts[id] = Vector2i.ZERO
	_link(run_state.event_manager.event_resolved, _on_event_resolved)
	_link(run_state.event_manager.event_blocked, _on_event_blocked)
	for id in run_state.factor_manager.get_all_factor_ids():
		var factor: Factor = run_state.factor_manager.get_factor(id)
		_link(factor.level_changed, _on_factor_changed)
		_link(factor.factor_block_added, _on_factor_changed)
		_link(factor.factor_blocked, _on_factor_changed)
	var deck := run_state.run_deck_manager
	_link(deck.card_drawn, _on_hand_changed)
	_link(deck.card_played, _on_hand_changed)
	_link(deck.card_discarded, _on_hand_changed)
	clock.set_at("timer", Utils.format_timer(0.0))
	refresh()


func _on_run_ended(_success: bool) -> void:
	_disconnect_run()
	refresh()


func _on_run_ticked(run_state: RunState) -> void:
	clock.set_at("timer", Utils.format_timer(run_state.elapsed_time))   # set_at ignora valor igual: 1 emissão/s


func _on_event_resolved(event_id: StringName, amount: int) -> void:
	_event_counts[event_id] += Vector2i(amount, 0)
	refresh()


func _on_event_blocked(event_id: StringName, amount: int) -> void:
	_event_counts[event_id] += Vector2i(0, amount)
	refresh()


func _on_factor_changed(_factor: Factor) -> void:
	refresh()


func _on_hand_changed(_card: Card) -> void:
	refresh()


func _link(sig: Signal, callable: Callable) -> void:
	sig.connect(callable)
	_run_links.append([sig, callable])


func _disconnect_run() -> void:
	for pair in _run_links:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	_run_links.clear()
#endregion


#region Helpers
func _find_by_id(items: Array, id: String) -> Variant:
	for item in items:
		if str(item.id) == id:
			return item
	return null


func _find_card(cards: Array, uuid: String) -> Card:
	for card: Card in cards:
		if str(card.uuid) == uuid:
			return card
	return null
#endregion
