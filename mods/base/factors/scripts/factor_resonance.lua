local function onThreshold50(player, factor)
	print("Chegou em 50!", "warning")
end

function createThresholds(player, factor)
	Content.createThreshold(50, true, onThreshold50)
	Content.createThreshold(80, false, function(player, factor)
		print("Quase no limite!", "warning")
	end)
end

function onOverflow(player, factor_id)
	Content.doChangeFactorLevel(factor_id, 0)
end
