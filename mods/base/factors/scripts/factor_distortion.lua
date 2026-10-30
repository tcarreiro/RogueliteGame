local function onThreshold50(player, factor)
	print("Chegou em 50!", "warning")
end

local function onThreshold80(player, factor)
	print("Quase no limite!", "warning")
end

function onCreation(player, factor_id)
	Content.createFactorThreshold(factor_id, 50, false, 1, "UP", onThreshold50)
	Content.createFactorThreshold(factor_id, 80, false, 1, "UP", onThreshold80)
end

function onOverflow(player, factor_id)
	--local amount = -Content.getFactorLevel(factor_id)
	--Content.doChangeFactorLevel(factor_id, amount)
	-- Do something bad
end
