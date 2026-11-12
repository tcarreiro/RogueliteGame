function onWatchedEventTrigger(watched_event_id, amount)
	return ((Content.getCurrentHandSize() >= Content.getMaxHandSize()) or (Content.hasAvailableCardsToDraw() <= 0))
end

function onResolvedEvent(player, event_id, amount)
	--playsound
	Content.doChangeFactorLevel("factor_resonance", 1)
	Content.doChangeFactorLevel("factor_surrender", 1)
	return true
end
