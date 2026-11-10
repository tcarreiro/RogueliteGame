-- Tela de teste de uma run
-- Get/Set:  UI.store("run_screen") / UI.store("run_clock")   (Game -> Lua, reactive)
-- Actions:  Game.selectGauntlet(id), Game.selectDatashard(id), Game.toggleCard(uuid),
--           Game.playCard(uuid), Game.toggleRun()              (Lua -> Game, ids only)

local function confirm(title, message, confirm_action, cancel_action)
	Game.pause()
	UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = confirm_action, on_cancel = cancel_action })
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

UI.defineComponent("GameScreen", {
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
			if screen.get_at("phase") == "run" then return "LABEL_END_RUN" end
			return "LABEL_START_RUN"
		end)
		
		local toggle_run_msg = UI.bind(screen, function()
			if screen.get_at("phase") == "hub" then return "CONFIRM_MSG_START_RUN" end
			return "CONFIRM_MSG_END_RUN"
		end)

		local opened_inventories = {}
		local function toggle_modal() 
			UI.mount(InventoryModal{ ref = "inventory_modal", store = "inventory", title = "LABEL_INVENTORY", columns = 7, windowed = true, margin = {0, 0, 650, 0} })
			UI.mount(InventoryModal{ ref = "inventory_hotbar_modal", store = "inventory_hotbar", title = "LABEL_INVENTORY", columns = 7, windowed = true, margin = {650, 0, 0, 0} })
		end
		
		local function toggle_pause_menu()
			UI.mount(PauseMenu{ ref = "pause_menu", title = "LABEL_PAUSE_MENU" })
		end

		return Body{ children = {
			-- keyboard actions
			--Hotkey{ action = "toggle_context_menu", on_press = toggle_modal },
			Hotkey{ action = "toggle_context_menu", on_press = toggle_pause_menu },
			Hotkey{ action = "toggle_inventory", on_press = toggle_modal },
			
			Div{ class = "run-root", flex_grow = 1, gap = 12, children = {
				-- Header
				Div{ id = "hub-header", class = "panel", display = "flex", flex_grow = 0.4, gap = 32, visible = in_hub, children = {
					Div{ id = "gauntlet-options", gap = 6, children = {
						section_title("LABEL_GAUNTLETS"),
						Scroll{ class = "pr-2", flex_grow = 1, children = {
							choice_list(gauntlet_options, Game.selectGauntlet),
						} },
					} },
					Div{ id = "datashard-options", gap = 6, children = {
						section_title("LABEL_DATASHARDS"),
						Scroll{ class = "pr-2", flex_grow = 1, children = {
							choice_list(datashard_options, Game.selectDatashard),
						} },
					} },
					Div{ id = "active_effects", gap = 6, visible = in_hub,  children = {
						section_title("LABEL_RUN_EFFECTS"),
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
							section_title("LABEL_CARD_COLLECTION"),
							Scroll{ class = "pr-2", flex_grow = 1, children = {
								card_list(card_options, Game.toggleCard, "btn card-btn"),
							} },
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("LABEL_ACTIVE_DECK"),
							Scroll{ class = "pr-2", flex_grow = 1, children = {
								card_list(active_cards, Game.toggleCard, "btn card-btn active"),
							} },
						} },
					} },

					-- Factors, Events and Hand
					Div{ display = "flex", flex_grow = 4, gap = 16, visible = in_run, children = {
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("LABEL_FACTORS"),
							stat_list(factors),
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("LABEL_EVENTS"),
							stat_list(events),
						} },
						Div{ class = "panel", flex_grow = 1, gap = 6, children = {
							section_title("LABEL_HAND"),
							card_list(hand, Game.playCard, "btn hand-card"),
						} },
					} },

					-- Effects
					Div{ class = "panel", flex_grow = 1, gap = 6, visible = in_run,  children = {
						section_title("LABEL_RUN_EFFECTS"),
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
						section_title("LABEL_EQUIPMENTS"),
						Label{ id = "selected_gauntlet", text = selected_gauntlet, class = "stat-name" },
						Label{ id = "selected_datashard", text = selected_datashard, class = "stat-name" },
					} },
					Div{ flex_grow = 1 }, -- Separator
					Div{ id = "inventory-btns", gap = 6,  children = {
						section_title("LABEL_ACTIONS"),
						Button{ id = "inventory_btn", label = "LABEL_INVENTORY", class = "btn primary", visible = in_hub,
							on_click = toggle_modal
						},
						Button{
							id = "run_btn",
							label = run_label,
							class = "btn primary",
							disabled = toggle_run_btn,
							on_pressed = function() 
								confirm("Confirm", toggle_run_msg, function()
									Game.resume()
									Game.toggleRun()
								end,
								function()
									Game.resume()
								end)
							end
						},
					} },
				} },
			} },
		} }
	end,
})
