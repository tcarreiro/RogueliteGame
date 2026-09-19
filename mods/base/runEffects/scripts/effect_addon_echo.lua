function onRunStart(player, effect_id)
	local buff_timer = 5000
	local buff_value = 20
	local factor_id = "factor_resonance"
	local initial_max_level = Content.getFactorMaxLevel(factor_id)
	Content.doChangeFactorMaxLevel(factor_id, initial_max_level + buff_value)
	print("[LUA] Res NEW max level: " .. Content.getFactorMaxLevel(factor_id))
	Content.addAction(
	function()
		local cur_level = Content.getFactorMaxLevel(factor_id)
		local new_level = cur_level - buff_value
		Content.doChangeFactorMaxLevel(factor_id, new_level)
		print("[LUA] new level: " .. Content.getFactorMaxLevel(factor_id))
	end, buff_timer)
end
