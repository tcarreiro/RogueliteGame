function onEquip()

end

function onUnequip()

end

function onRunStart(player, effect_id)
	print("Run started with effect " .. effect_id .. " added")
	local initial_max_level = Content.getFactorMaxLevel("factor_resonance")
	print("Res max level: " .. initial_max_level)
	Content.doChangeFactorMaxLevel("factor_resonance", initial_max_level + 20)
	print("Res NEW max level: " .. Content.getFactorMaxLevel("factor_resonance"))
end
