function onRunStart(player)
	local buff_value = 20
	local factor_id = "factor_resonance"
	local initial_max_level = Content.getFactorMaxLevel(factor_id)
	Content.doChangeFactorMaxLevel(factor_id, initial_max_level + buff_value)
end
