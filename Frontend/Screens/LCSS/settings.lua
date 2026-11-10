local function section_title(text)
	return Label{ text = text, class = "section-title" }
end

local function setting_row(title, control, label_width)
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
 	render = function(p)
	local ref = "settings_modal"
	local graphics_store = UI.store("graphics_settings")
	local graphics_draft = graphics_store.draft()
	
	local audio_store = UI.store("audio_settings")
	local audio_draft = audio_store.draft()
	
	local game_store = UI.store("game_settings")
	local game_draft = game_store.draft()
	
	local function not_dirty() return not graphics_draft.dirty() and not audio_draft.dirty() and not game_draft.dirty() end
	local not_dirty_bind = UI.bind({graphics_draft, audio_draft, game_draft}, not_dirty)
	
	local function close()
		UI.callMethod(ref, "close")
	end 

	local function confirm(title, message, action)
	  UI.mount(ConfirmDialog{ title = title, message = message, on_confirm = action })
	end
	
	local function commit()
		graphics_draft.commit()
		audio_draft.commit()
		game_draft.commit()
	end
	
	return Modal{
		ref = ref,
		backdrop_color = "#000000AA",
		slots  = { content = {
			Div{ class = "main-menu-root", width = 1920, height = 1080, flex_grow = 1, gap = 12, children = {
				section_title("SETTINGS"),
				
				Scroll{ flex_grow = 1, children = {
					setting_row('$RESOLUTION',
						Dropdown{ class = 'settings-input', width = 300,
						options = graphics_store.get_at("resolution_options"),
						model = graphics_draft.model('resolution'),
					}, 240),
					setting_row('$VSYNC',
						Checkbox{ class = 'checkbox', label = 'Ligado',
						model = graphics_draft.model('vsync')
					}, 240),
					setting_row('$SHADOWS',
						Dropdown{  class = 'settings-input', width = 300,
						options = graphics_store.get_at("shadow_quality_options"),
						model = graphics_draft.model('shadow_quality'),
						--on_changed = function(v) print(v) end
					}, 240),
					setting_row('$SSAO',
						Dropdown{  class = 'settings-input', width = 300,
						options = graphics_store.get_at("ssao_quality_options"),
						model = graphics_draft.model('ssao_quality'),
						--on_changed = function(v) print(v) end
					}, 240),
					setting_row('$SIL',
						Dropdown{  class = 'settings-input', width = 300,
						options = graphics_store.get_at("ssil_quality_options"),
						model = graphics_draft.model('ssil_quality'),
						--on_changed = function(v) print(v) end
					}, 240),
					setting_row('$ANTI_ALIASING',
						Dropdown{  class = 'settings-input', width = 300,
						options = graphics_store.get_at("anti_aliasing_options"),
						model = graphics_draft.model('anti_aliasing'),
						--on_changed = function(v) print(v) end
					}, 240),
					setting_row('$LANGUAGE',
						Dropdown{  class = 'settings-input', width = 300,
						options = game_store.get_at("language_options"),
						model = game_draft.model('language'),
						--on_changed = function(v) print(v) end
					}, 240),
					setting_row('$VOLUME',
						Slider{ class = 'slider', width = 300, min = 0, max = 100, step = 1, show_value = true,
						track_height = 8, thumb_size = 22,
						model = audio_draft.model('volume'),
					}, 240),
				} },
				
				Div{ id = "actions", display = "flex", gap = 12, children = {
					Div{ flex_grow = 1 },
					Button{ label = "APPLY", class = "btn", disabled = not_dirty_bind,
						on_mouse_entered = function()
							if not_dirty() then
								--UI.playSoundEffect("som")
							end
						end,
						on_pressed = function() 
							confirm("SAVE", "SAVE_CONFIG_MSG", commit)
						end,
					},
					Button{ label = "SAVE", class = "btn", disabled = not_dirty_bind,
						on_mouse_entered = function()
							if not_dirty() then
								--UI.playSoundEffect("som")
							end
						end,
						on_pressed = function()
						  confirm("SAVE", "SAVE_CONFIG_BACK_MSG", function()
							commit()
							close()
						  end)
						end,
					},
					Button{ label = "RESTORE", class = "btn",
						on_mouse_entered = function()
							--UI.playSoundEffect("som")
						end,
						on_pressed = function()
							graphics_draft.discard()
						end,
					},
					Button{ label = "BACK", class = "btn cancel",
						on_mouse_entered = function()
							--UI.playSoundEffect("som")
						end,
						on_pressed = function()
							if not_dirty() then
								close()
								return
							end
							confirm("RESTORE", "DISCARD_CONFIG_MSG", function()
								graphics_draft.discard()
								close()
							end)
						end,
					},
				} },
			} },
		} }
	}
  end,
})
