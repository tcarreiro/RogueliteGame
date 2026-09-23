class_name EffectManager extends Resource

@export var active_effects: Array[Effect] = []

var _run_manager: RunManager

func _init() -> void:
	_run_manager = GameManager.run_manager


func process_effects(delta: float, _speed_multiplier: float = 1.0) -> void:
	for effect in active_effects:
		_process_effect(effect)
		if effect.has_time_remaining():
			effect.duration -= delta * _speed_multiplier
		if not effect.has_time_remaining() or not effect.can_fire():
			active_effects.erase(effect)


func _process_effect(effect: Effect) -> void:
	if not effect.trigger_event == Effect.TriggerEvent.TE_IMMEDIATE:
		return
	effect.fire.call({})


func register_effect(effect: Effect) -> void:
	match effect.trigger_event:
		Effect.TriggerEvent.TE_IMMEDIATE:
			effect.fire.call({})
		Effect.TriggerEvent.TE_RUN_EVENT:
			if effect.event_category == Effect.EventCategory.EC_RE_START_RUN:
				_run_manager.run_started.connect(effect.fire.call_deferred.bind({}), ConnectFlags.CONNECT_ONE_SHOT)
			if effect.event_category == Effect.EventCategory.EC_RE_END_RUN:
				_run_manager.run_ended.connect(effect.fire.call_deferred.bind({}), ConnectFlags.CONNECT_ONE_SHOT)
		Effect.TriggerEvent.TE_CARD_EVENT:
			_run_manager.run_state.run_deck_manager.card_played.connect(func(card):
				if effect.matches(card.id, Effect.EventCategory.EC_CE_PLAYED):
					effect.fire.call_deferred({"card_id": card.id})
			)
			_run_manager.run_state.run_deck_manager.card_drawn.connect(func(card):
				if effect.matches(card.id, Effect.EventCategory.EC_CE_DRAWN):
					effect.fire.call_deferred({"card_id": card.id})
			)
			_run_manager.run_state.run_deck_manager.card_discarded.connect(func(card):
				if effect.matches(card.id, Effect.EventCategory.EC_CE_DISCARDED):
					effect.fire.call_deferred({"card_id": card.id})
			)
		Effect.TriggerEvent.TE_FACTOR_EVENT:
			_run_manager.run_state.factor_manager.level_changed.connect(func(factor):
				if effect.matches(factor.id, Effect.EventCategory.EC_FE_LEVEL_CHANGED):
					effect.fire.call_deferred({"factor_id": factor.id})
			)
			_run_manager.run_state.factor_manager.overflow.connect(func(factor):
				if effect.matches(factor.id, Effect.EventCategory.EC_FE_OVERFLOW):
					effect.fire.call_deferred({"factor_id": factor.id})
			)
			_run_manager.run_state.factor_manager.threshold_reached.connect(func(factor, threshold):
				if effect.matches(factor.id, Effect.EventCategory.EC_FE_THRESHOLD_REACHED):
					effect.fire.call_deferred({"factor_id": factor.id, "threshold": threshold})
			)
		Effect.TriggerEvent.TE_PLAYER_EVENT:
			#_run_manager.run_state.run_deck_manager.card_played.connect(func(card):
				#if effect.matches(card.id, Effect.EventCategory.EC_CE_PLAYED):
					#effect.fire.call_deferred({"card_id": card.id})
			#)
			# TODO
			pass
		Effect.TriggerEvent.TE_LOOT_EVENT:
			_run_manager.run_state.run_loot_manager.collected.connect(func(loot):
				if effect.matches(loot.id, Effect.EventCategory.EC_LE_COLLECTED):
					effect.fire.call_deferred({"card_id": loot.id})
			)
			pass
	active_effects.append(effect)
