function onWatchedEventTrigger(watched_event_id, amount)
	-- TODO: getMaxHandSize
	-- TODO: getCurrentHandSize
	-- TODO: getAvailableCardsOnActiveDeck
	
	--return (getCurrentHandSize >= getMaxHandSize) or (getAvailableCardsOnActiveDeck <= 0)
end

function onResolvedEvent(player, event_id, amount)
-- playsound
	Content.doChangeFactorLevel("factor_resonance", 1)
	Content.doChangeFactorLevel("factor_resonance", 1)
end
