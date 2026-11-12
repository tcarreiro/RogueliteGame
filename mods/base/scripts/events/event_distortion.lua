function onResolvedEvent(player, event_id, amount)
	local affected_factor_id = "factor_distortion"
	Content.doChangeFactorLevel(affected_factor_id, amount)
end

function onBlockedEvent(event_id, amount)
	print(amount .. " of " .. event_id .. " blocked")
end
