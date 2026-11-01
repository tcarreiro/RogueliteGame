local function section_title(text)
	return Label{ text = text, class = "section-title" }
end

local function row(title, control, label_width)
  return 
	Div{  id = "row-wrapper", display = "flex", gap = 16, padding = 30, children = {
		Div{ id = "label-wrapper", alignment = "center", children = {
			Label{ text = title, class = "settings-label", width = label_width },
		} },
		control,
		Div{ id = "separator", flex_grow = 5 }
	} }
end

UI.defineComponent("Settings", {
  events = { "navigate" },
  render = function(p)
	local settings_store = UI.store("settings")
	local draft_store = settings_store.draft()
	local not_dirty = UI.bind(draft_store, function() return not draft_store.dirty() end)
	
	local function back_to_menu()
	  if p.on_navigate then p.on_navigate("main_menu") end
	end

	local function confirm(title, message, action)
	  UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = action })
	end

	return Body{ children = {
		Div{ class = "main-menu-root", flex_grow = 1, gap = 12, children = {
			
			section_title("SETTINGS"),
			
			Label{ id = "applied_config",  class = "settings-hint", text = UI.bind(settings_store, function()
				return "Aplicado: " .. settings_store.get_at("resolution")
				  .. " | vsync " .. tostring(settings_store.get_at("vsync"))
				  .. " | volume " .. settings_store.get_at("volume")
				  .. " | quality " .. settings_store.get_at("quality_options")[settings_store.get_at("quality")-1].label
			  end),
			},
			
			Label{ id = "draft_config",  class = "settings-hint", text = UI.bind(draft_store, function()
				return "Rascunho: " .. draft_store.get_at("resolution")
				  .. " | vsync " .. tostring(draft_store.get_at("vsync"))
				  .. " | volume " .. draft_store.get_at("volume")
				  .. " | quality " .. draft_store.get_at("quality_options")[draft_store.get_at("quality")-1].label
			  end),
			},
			
			Scroll{ flex_grow = 1, children = {
				row('Resolução',
					Dropdown{ class = 'settings-input', width = 300,
					options = settings_store.get_at("resolution_options"),
					model = draft_store.model('resolution'),
				}, 240),
				row('VSync',
					Checkbox{ class = 'checkbox', label = 'Ligado',
					model = draft_store.model('vsync')
				}, 240),
				row('Volume',
					Slider{ class = 'slider', width = 300, min = 0, max = 100, step = 1, show_value = true,
					track_height = 8, thumb_size = 22,
					model = draft_store.model('volume'),
				}, 240),
				row('Qualidade',
					RadioGroup{ options = settings_store.get_at("quality_options"),
					model = draft_store.model('quality'),
					on_changed = function(v) print(v) end
				}, 240),
			} },
			

			Div{ id = "actions", display = "flex", gap = 12, children = {
				Div{ flex_grow = 1 },
				Button{ label = "APPLY", class = "btn", disabled = not_dirty,
					on_mouse_entered = function()
						if draft_store.dirty() then
							--UI.playSoundEffect("som")
						end
					end,
					on_pressed = function() 
						confirm("SAVE", "SAVE_CONFIG_MSG", function()
							draft_store.commit()
						end)
					end,
				},
				Button{ label = "SAVE", class = "btn", disabled = not_dirty,
					on_mouse_entered = function()
						if draft_store.dirty() then
							--UI.playSoundEffect("som")
						end
					end,
					on_pressed = function()
					  confirm("SAVE", "SAVE_CONFIG_BACK_MSG", function()
						draft_store.commit()
						back_to_menu()
					  end)
					end,
				},
				Button{ label = "RESTORE", class = "btn",
					on_mouse_entered = function()
						--UI.playSoundEffect("som")
					end,
					on_pressed = function()
						draft_store.discard()
					end,
				},
				Button{ label = "BACK", class = "btn cancel",
					on_mouse_entered = function()
						--UI.playSoundEffect("som")
					end,
					on_pressed = function()
						if not draft_store.dirty() then
							back_to_menu()
							return
						end
						confirm("RESTORE", "DISCARD_CONFIG_MSG", function()
							draft_store.discard()
							back_to_menu()
						end)
					end,
				},
			} },
		} },
	} }
  end,
})
