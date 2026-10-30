--enum TriggerEvent {
	--TE_IMMEDIATE,
	--TE_RUN_EVENT,
	--TE_CARD_EVENT,
	--TE_FACTOR_EVENT,
	--TE_PLAYER_EVENT,
	--TE_LOOT_EVENT,
--}
--
--enum EventCategory {
	--EC_NONE,
	--EC_RE_START_RUN,
	--EC_RE_END_RUN,
	--EC_RE_TRIGGERED,
	--EC_RE_RESOLVED,
	--EC_RE_BLOCKED,
	--EC_CE_DRAWN,
	--EC_CE_PLAYED,
	--EC_CE_DISCARDED,
	--EC_FE_OVERFLOW,
	--EC_FE_LEVEL_CHANGED,
	--EC_FE_THRESHOLD_REACHED,
	--EC_PE_SPOTTED,
	--EC_PE_DEATH,
	--EC_PE_HIT,
	--EC_LE_COLLECTED
--}

function onRunStart(loot)
	-- TODO: is recreating (and adding) a new effect each run start
	Content.doCreateEffect({
		display_name = "Echo Veil",
		parent_loot = loot,
		trigger_event = "TE_IMMEDIATE",
		event_category = "EC_NONE",
		effect_category = "BUFF",
		description = "INCREASE_MAX_RESONANCE_20",
		stacks = 1,
		on_trigger = function(params)
			Content.doChangeFactorMaxLevel("factor_resonance", 20)
		end
	})
	return true
end
