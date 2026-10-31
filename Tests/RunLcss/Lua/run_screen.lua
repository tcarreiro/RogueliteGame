-- Tela de teste de uma run
-- Get/Set:  UI.store("run_screen") / UI.store("run_clock")   (Game -> Lua, reactive)
-- Actions:  Game.selectGauntlet(id), Game.selectDatashard(id), Game.toggleCard(uuid),
--           Game.playCard(uuid), Game.toggleRun()              (Lua -> Game, ids only)

local function confirm(title, message, action)
  UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = action })
end

local function section_title(text)
	return Label{ text = text, class = "section-title" }
end

-- Reactive list. Updates with store refresh
-- OBS: index começa em 0 e `item` é um Dictionary do Godot (item.name, item.id...).
local function choice_list(items, on_pick)
	return Repeat{
		gap = 6,
		items = items,
		render_item = function(item)
			local cls = "btn"
			if item.selected then cls = cls .. " selected" end
			return Button{
				label = item.name,
				class = cls,
				disabled = item.disabled,
				on_pressed = function() on_pick(item.id) end,
			}
		end,
	}
end

local function card_list(items, on_pick, base_class)
	return Repeat{
		gap = 6,
		items = items,
		render_item = function(card)
			local cls = base_class
			if card.active then cls = cls .. " active" end
			return Button{
				label = card.name,
				class = cls,
				on_pressed = function() on_pick(card.uuid) end,
			}
		end,
	}
end

local function stat_list(items)
	return Repeat{
		gap = 4,
		items = items,
		render_item = function(stat)
			return Div{ display = "flex", gap = 12, children = {
				Label{ text = stat.name, class = "stat-name" },
				Label{ text = stat.text, class = "stat-value" },
			} }
		end,
	}
end

UI.defineComponent("RunScreen", {
	render = function(p)
		local screen = UI.store("run_screen")
		local clock = UI.store("run_clock")

		local in_hub = UI.bind(screen, function() return screen.get_at("phase") == "hub" end)
		local in_run = UI.bind(screen, function() return screen.get_at("phase") == "run" end)
		
		local timer = UI.bind(clock, "timer")
		
		local gauntlet_options = UI.bind(screen, "gauntlets")
		local datashard_options = UI.bind(screen, "datashards")
		local card_options = UI.bind(screen, "cards")
		local active_cards = UI.bind(screen, "active_cards")
		
		local factors = UI.bind(screen, "factors")
		local events = UI.bind(screen, "events")
		local hand = UI.bind(screen, "hand")
		
		local effects = UI.bind(screen, "effects")
		local selected_gauntlet = UI.bind(screen, "selected_gauntlet")
		local selected_datashard = UI.bind(screen, "selected_datashard")
		
		local toggle_run_btn = UI.bind(screen, function() return not screen.get_at("can_toggle_run") end)
		
		local run_label = UI.bind(screen, function()
			if screen.get_at("phase") == "run" then return "End Run" end
			return "Start Run"
		end)
		
		local toggle_run_msg = UI.bind(screen, function()
			if screen.get_at("phase") == "hub" then return "Iniciar run?" end
			return "Encerrar run?"
		end)

		return Body{ children = {
			Div{ class = "run-root", flex_grow = 1, gap = 12, children = {
				-- Header
				Div{ id = "hub-header", class = "panel", display = "flex", flex_grow = 0.4, gap = 32, visible = in_hub, children = {
					Div{ id = "gauntlet-options", gap = 6, children = {
						section_title("Gauntlets"),
						Scroll{ flex_grow = 1, padding_right = 10, children = {
							choice_list(gauntlet_options, Game.selectGauntlet),
						} },
					} },
					Div{ id = "datashard-options", gap = 6, children = {
						section_title("Datashards"),
						Scroll{ flex_grow = 1, padding_right = 10, children = {
							choice_list(datashard_options, Game.selectDatashard),
						} },
					} },
					Div{ id = "active_effects", gap = 6, visible = in_hub,  children = {
						section_title("Run Effects"),
						Scroll{ flex_grow = 1, children = {
							Repeat{
								gap = 4,
								items = effects,
								render_item = function(effect) return Label{ text = effect.name, class = "stat-name" } end,
							},
						} },
					} },
				} },
				Div{ id = "run-header", class = "panel", display = "flex", flex_grow = 0.4, gap = 8, visible = in_run, children = {
					Label{ text = "Timer:", class = "section-title" },
					Label{ id = "timer-label", text = timer, class = "section-title" },
				} },

				-- Mid
				Div{ display = "flex", flex_grow = 1, gap = 16, children = {
					-- Deck
					Div{ display = "flex", flex_grow = 4, gap = 16, visible = in_hub, children = {
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("Collection"),
							Scroll{ flex_grow = 1, children = {
								card_list(card_options, Game.toggleCard, "btn card-btn"),
							} },
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("Active"),
							Scroll{ flex_grow = 1, children = {
								card_list(active_cards, Game.toggleCard, "btn card-btn active"),
							} },
						} },
					} },

					-- Factors, Events and Hand
					Div{ display = "flex", flex_grow = 4, gap = 16, visible = in_run, children = {
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("Factors"),
							stat_list(factors),
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("Events (resolved|blocked)"),
							stat_list(events),
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("Hand"),
							card_list(hand, Game.playCard, "btn hand-card"),
						} },
					} },

					-- Effects
					Div{ class = "panel", flex_grow = 1, gap = 6, visible = in_run,  children = {
						section_title("Run Effects"),
						Scroll{ flex_grow = 1, children = {
							Grid{ id = "effects", columns = 2, flex_grow = 1, children = {
								Repeat{
									gap = 4,
									items = effects,
									render_item = function(effect) return Label{ text = effect.name, class = "stat-name" } end,
								},
							} },
						} },
					} },
				} },

				-- Footer
				Div{ class = "panel", display = "flex", gap = 24, children = {
					Div{ gap = 4, children = {
						section_title("Equipments:"),
						Label{ id = "selected_gauntlet", text = selected_gauntlet, class = "stat-name" },
						Label{ id = "selected_datashard", text = selected_datashard, class = "stat-name" },
					} },
					Div{ flex_grow = 1 }, -- Separator
					Button{
						id = "run_btn",
						label = run_label,
						class = "btn primary",
						disabled = toggle_run_btn,
						on_pressed = function() 
							confirm("Confirm", toggle_run_msg, function()
								Game.toggleRun()
							end)
						end
					},
				} },
			} },
		} }
	end,
})
