function onResolvedEvent(player, event_id, amount)
	local affected_factor_id = "factor_resonance"
	Content.doChangeFactorLevel(affected_factor_id, amount*28)
end

function onBlockedEvent(player, event_id)
	print(event_id .. " blocked")
end
