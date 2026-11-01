-- Tela de teste de uma run
-- Get/Set:  UI.store("settings")

local function confirm(title, message, action)
	UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = action })
end

local function section_title(text)
	return Label{ text = text, class = "section-title" }
end

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

UI.defineComponent("MainMenu", {
	events = { "navigate" },
	render = function(p)
	
		local function go(target)
			if p.on_navigate then p.on_navigate(target) end
		end
		
		local function button(btn_id, label, navigation_target, class_on_hover)
			if class_on_hover == nil then
				class_on_hover = ""
			end
			return Button{ 
				id = btn_id,
				ref = btn_id,
				label = label,
				class = "btn primary " .. class_on_hover,
				on_pressed = function()
					--UI.playSoundEffect("click")
					go(navigation_target)
				end,
				on_mouse_entered = function()
					--UI.playSoundEffect("hover")
				end,
			}
		end
	
		--local settings = UI.store("settings")

		return Body{ children = {
			Div{ class = "main-menu-root", flex_grow = 1, gap = 12, children = {
				
				Div { class = "", flex_grow = 1, display = "flex", children = {
					Div{ class = "", flex_grow = 60, align_items = "center", children = {
						
					} },
					
					Div{ class = "", flex_grow = 40, display = "flex", padding_bottom = 120,  children = {
						Div{flex_grow = 1},
						Div{ flex_grow = 1, gap = 20, alignment = 'end', children = {
							button("play_btn", "PLAY", "play", ""),
							button("settings_btn", "SETTINGS", "settings", ""),
							button("quit_btn", "QUIT", "quit", "text-color-red"),
						} },
						Div{flex_grow = 1},
					} },
				} },
				
				
				Div{ class = "", alignment = "end", display = "flex", children = {
					Label{ class = "version-label", text = "v. 0.00.01-00001"},  -- TODO: get version from GameConfig
				} },
				
			} },
		} }
	end,
})
