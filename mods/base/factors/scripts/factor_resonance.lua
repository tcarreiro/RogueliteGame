local function onThreshold50(player, factor)
	print("Chegou em 50!", "warning")
end

local function onThreshold80(player, factor)
	print("Quase no limite!", "warning")
end

function createThresholds(player, factor)
	Content.createThreshold(50, true, onThreshold50)
	Content.createThreshold(80, false, onThreshold80)
end

function onOverflow(player, factor_id)
	local amount = -Content.getFactorLevel(factor_id)
	Content.doChangeFactorLevel(factor_id, amount)
end
