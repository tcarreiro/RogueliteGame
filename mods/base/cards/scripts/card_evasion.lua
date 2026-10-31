function onDrawn(card_id)
	--print("Draw card " .. card_id)
end

function onPlayed(card_id)
	print("[LUA] Playing card " .. card_id)
	--Content.addEventBlock('event_stumble', "VALUE", 2)
	Content.addFactorBlock('factor_resonance', 2)
	return true
end
